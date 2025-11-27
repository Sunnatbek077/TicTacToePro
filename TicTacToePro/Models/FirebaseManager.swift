//
//  FirebaseManager.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 26/10/2025.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Firebase Manager
final class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Published var currentUser: FirebaseUser?
    @Published var isAuthenticated = false
    
    private var listeners: [String: ListenerRegistration] = [:]
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Modern Firestore settings with persistent cache (recommended)
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(
            sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited)  // ✅ Unlimited cache (no size limit, disables cleanup)
        )
        db.settings = settings
        
        // Start listening to auth state
        startAuthStateListener()
    }
    
    deinit {
        // Clean up auth listener
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Authentication
    
    /// Sign in anonymously (for quick multiplayer access)
    func signInAnonymously() async throws -> FirebaseUser {
        do {
            let result = try await auth.signInAnonymously()
            let userId = result.user.uid
            
            // Check if user already exists in Firestore with a saved username
            var savedUsername: String?
            do {
                let existingUser = try await fetchUser(userId: userId)
                savedUsername = existingUser.username
            } catch {
                // User doesn't exist yet, will create new one
            }
            
            // Use saved username if available, otherwise generate a random one
            let username = savedUsername ?? "Player_\(Int.random(in: 1000...9999))"
            
            let user = FirebaseUser(
                id: userId,
                username: username,
                isAnonymous: true
            )
            
            // Save/update user in Firestore (will merge if exists)
            try await saveUser(user)
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
            
            return user
        } catch {
            print("Anonymous sign-in failed: \(error)")
            throw error
        }
    }
    
    /// Sign in with custom username (still anonymous but with custom name)
    func signInWithUsername(_ username: String) async throws -> FirebaseUser {
        do {
            let result = try await auth.signInAnonymously()
            let user = FirebaseUser(
                id: result.user.uid,
                username: username,
                isAnonymous: true
            )
            
            try await saveUser(user)
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
            
            return user
        } catch {
            print("Sign-in with username failed: \(error)")
            throw error
        }
    }
    
    private func startAuthStateListener() {
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            
            if let user = user {
                Task {
                    do {
                        let firebaseUser = try await self.fetchUser(userId: user.uid)
                        await MainActor.run {
                            self.currentUser = firebaseUser
                            self.isAuthenticated = true
                        }
                    } catch {
                        print("Error fetching user data: \(error)")
                    }
                }
            } else {
                Task {
                    await MainActor.run {
                        self.currentUser = nil
                        self.isAuthenticated = false
                    }
                }
            }
        }
    }
    
    
    /// Sign out and clean up
    func signOut() throws {
        try auth.signOut()
        
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
            authStateListenerHandle = nil
        }
        
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - User Management
    
    private func saveUser(_ user: FirebaseUser) async throws {
        let userData: [String: Any] = [
            "id": user.id,
            "username": user.username,
            "isAnonymous": user.isAnonymous,
            "createdAt": FieldValue.serverTimestamp(),
            "lastActiveAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(user.id).setData(userData, merge: true)
    }
    
    /// Update the username of the currently authenticated user
    func updateUsername(_ newUsername: String) async throws {
        guard let userId = currentUser?.id else { throw FirebaseError.userNotFound }
        
        try await db.collection("users").document(userId).updateData([
            "username": newUsername,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        await MainActor.run {
            if let current = self.currentUser {
                self.currentUser = FirebaseUser(id: current.id, username: newUsername, isAnonymous: current.isAnonymous)
            }
        }
    }
    
    func fetchUser(userId: String) async throws -> FirebaseUser {
        let doc = try await db.collection("users").document(userId).getDocument()
        
        guard let data = doc.data() else {
            throw FirebaseError.userNotFound
        }
        
        return FirebaseUser(
            id: data["id"] as? String ?? userId,
            username: data["username"] as? String ?? "Unknown",
            isAnonymous: data["isAnonymous"] as? Bool ?? true
        )
    }
    
    func updateLastActive() async throws {
        guard let userId = currentUser?.id else { return }
        try await db.collection("users").document(userId).updateData([
            "lastActiveAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Game Management
    
    func createGame(_ game: MultiplayerGame) async throws -> String {
        let gameRef = db.collection("games").document()
        let gameId = gameRef.documentID
        
        var gameData = try gameToFirestoreData(game)
        gameData["id"] = gameId
        gameData["createdAt"] = FieldValue.serverTimestamp()
        gameData["updatedAt"] = FieldValue.serverTimestamp()
        
        try await gameRef.setData(gameData)
        return gameId
    }
    
    func fetchGame(gameId: String) async throws -> MultiplayerGame {
        let doc = try await db.collection("games").document(gameId).getDocument()
        guard let data = doc.data() else { throw FirebaseError.gameNotFound }
        return try firestoreDataToGame(data)
    }
    
    func updateGame(_ game: MultiplayerGame) async throws {
        let gameData = try gameToFirestoreData(game)
        try await db.collection("games").document(game.id).updateData(
            gameData.merging(["updatedAt": FieldValue.serverTimestamp()]) { _, new in new }
        )
    }
    
    func updatePlayerUsernameInGame(gameId: String, playerId: String, newUsername: String) async throws {
        let gameRef = db.collection("games").document(gameId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let gameDoc: DocumentSnapshot
            do {
                gameDoc = try transaction.getDocument(gameRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard let data = gameDoc.data() else {
                let error = NSError(domain: "FirebaseManager", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Game not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            if let player1Data = data["player1"] as? [String: Any],
               let player1Id = player1Data["id"] as? String,
               player1Id == playerId {
                var updatedPlayer1 = player1Data
                updatedPlayer1["username"] = newUsername
                updatedPlayer1["lastActiveTime"] = FieldValue.serverTimestamp()
                
                transaction.updateData([
                    "player1": updatedPlayer1,
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: gameRef)
                
            } else if let player2Data = data["player2"] as? [String: Any],
                      let player2Id = player2Data["id"] as? String,
                      player2Id == playerId {
                var updatedPlayer2 = player2Data
                updatedPlayer2["username"] = newUsername
                updatedPlayer2["lastActiveTime"] = FieldValue.serverTimestamp()
                
                transaction.updateData([
                    "player2": updatedPlayer2,
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: gameRef)
            }
            return nil
        }
    }
    
    func joinGame(gameId: String, player: Player) async throws {
        let gameRef = db.collection("games").document(gameId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let gameDoc: DocumentSnapshot
            do {
                gameDoc = try transaction.getDocument(gameRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard var data = gameDoc.data() else {
                let error = NSError(domain: "FirebaseManager", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Game not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            if data["player2"] != nil {
                let error = NSError(domain: "FirebaseManager", code: -2,
                                  userInfo: [NSLocalizedDescriptionKey: "Game is full"])
                errorPointer?.pointee = error
                return nil
            }
            
            data["player2"] = self.playerToDict(player)
            data["status"] = MultiplayerGameStatus.active.rawValue
            data["startTime"] = FieldValue.serverTimestamp()
            data["currentTurnStartTime"] = FieldValue.serverTimestamp()
            data["updatedAt"] = FieldValue.serverTimestamp()
            
            transaction.updateData(data, forDocument: gameRef)
            return nil
        }
    }
    
    func makeMove(gameId: String, playerId: String, index: Int) async throws {
        let gameRef = db.collection("games").document(gameId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let gameDoc: DocumentSnapshot
            do {
                gameDoc = try transaction.getDocument(gameRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard let data = gameDoc.data() else {
                let error = NSError(domain: "FirebaseManager", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Game not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            do {
                var game = try self.firestoreDataToGame(data)
                
                if !game.makeMove(playerId: playerId, index: index) {
                    let error = NSError(domain: "FirebaseManager", code: -3,
                                      userInfo: [NSLocalizedDescriptionKey: "Invalid move"])
                    errorPointer?.pointee = error
                    return nil
                }
                
                let updatedData = try self.gameToFirestoreData(game)
                transaction.updateData(
                    updatedData.merging(["updatedAt": FieldValue.serverTimestamp()]) { _, new in new },
                    forDocument: gameRef
                )
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            return nil
        }
    }
    
    func listenToGame(gameId: String, completion: @escaping (Result<MultiplayerGame, Error>) -> Void) {
        let listener = db.collection("games").document(gameId)
            .addSnapshotListener { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = snapshot?.data() else {
                    completion(.failure(FirebaseError.gameNotFound))
                    return
                }
                
                do {
                    let game = try self.firestoreDataToGame(data)
                    completion(.success(game))
                } catch {
                    completion(.failure(error))
                }
            }
        
        listeners[gameId] = listener
    }
    
    func stopListeningToGame(gameId: String) {
        listeners[gameId]?.remove()
        listeners.removeValue(forKey: gameId)
    }
    
    func fetchAvailableGames() async throws -> [GameListItem] {
        let snapshot = try await db.collection("games")
            .whereField("status", in: [
                MultiplayerGameStatus.waiting.rawValue,
                MultiplayerGameStatus.active.rawValue
            ])
            .whereField("isPrivate", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments()
        
        return try snapshot.documents.compactMap { doc in
            try firestoreDataToGameListItem(doc.data())
        }
    }
    
    func addChatMessage(gameId: String, message: ChatMessage) async throws {
        let gameRef = db.collection("games").document(gameId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let gameDoc: DocumentSnapshot
            do {
                gameDoc = try transaction.getDocument(gameRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard var data = gameDoc.data() else {
                let error = NSError(domain: "FirebaseManager", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Game not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            var chatMessages = data["chatMessages"] as? [[String: Any]] ?? []
            chatMessages.append(self.chatMessageToDict(message))
            
            data["chatMessages"] = chatMessages
            data["updatedAt"] = FieldValue.serverTimestamp()
            
            transaction.updateData(data, forDocument: gameRef)
            return nil
        }
    }
    
    func forfeitGame(gameId: String, playerId: String) async throws {
        let gameRef = db.collection("games").document(gameId)
        
        _ = try await db.runTransaction { transaction, errorPointer in
            let gameDoc: DocumentSnapshot
            do {
                gameDoc = try transaction.getDocument(gameRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }
            
            guard let data = gameDoc.data() else {
                let error = NSError(domain: "FirebaseManager", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Game not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            do {
                var game = try self.firestoreDataToGame(data)
                game.forfeit(playerId: playerId)
                
                let updatedData = try self.gameToFirestoreData(game)
                transaction.updateData(
                    updatedData.merging(["updatedAt": FieldValue.serverTimestamp()]) { _, new in new },
                    forDocument: gameRef
                )
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            return nil
        }
    }
    
    func findGameByRoomCode(_ code: String) async throws -> String {
        let snapshot = try await db.collection("games")
            .whereField("roomCode", isEqualTo: code)
            .limit(to: 1)
            .getDocuments()
        
        guard let doc = snapshot.documents.first else {
            throw FirebaseError.gameNotFound
        }
        
        return doc.documentID
    }
    
    func deleteGame(gameId: String) async throws {
        try await db.collection("games").document(gameId).delete()
        stopListeningToGame(gameId: gameId)
    }
    
    // MARK: - Helper Methods (unchanged — already perfect)
    // ... [All your helper methods remain exactly as they were] ...
    // I've kept them all below unchanged for brevity, but they're included in full in the original.

    // MARK: - Helper Methods

    private func gameToFirestoreData(_ game: MultiplayerGame) throws -> [String: Any] {
        var data: [String: Any] = [
            "id": game.id,
            "status": game.status.rawValue,
            "result": game.result.rawValue,
            "boardState": game.boardState.map { $0.rawValue },
            "currentTurn": game.currentTurn.rawValue,
            "player1": playerToDict(game.player1),
            "settings": settingsToDict(game.settings),
            "moveHistory": game.moveHistory.map { moveToDict($0) },
            "chatMessages": game.chatMessages.map { chatMessageToDict($0) },
            "spectatorCount": game.spectatorCount,
            "isPrivate": game.isPrivate
        ]
        
        if let player2 = game.player2 {
            data["player2"] = playerToDict(player2)
        }
        if let startTime = game.startTime {
            data["startTime"] = startTime
        }
        if let endTime = game.endTime {
            data["endTime"] = endTime
        }
        if let lastMoveTime = game.lastMoveTime {
            data["lastMoveTime"] = lastMoveTime
        }
        if let player1Time = game.player1TimeRemaining {
            data["player1TimeRemaining"] = player1Time
        }
        if let player2Time = game.player2TimeRemaining {
            data["player2TimeRemaining"] = player2Time
        }
        if let turnStart = game.currentTurnStartTime {
            data["currentTurnStartTime"] = turnStart
        }
        if let roomCode = game.roomCode {
            data["roomCode"] = roomCode
        }
        
        return data
    }

    private func firestoreDataToGame(_ data: [String: Any]) throws -> MultiplayerGame {
        guard let id = data["id"] as? String,
              let statusRaw = data["status"] as? String,
              let status = MultiplayerGameStatus(rawValue: statusRaw),
              let resultRaw = data["result"] as? String,
              let result = MultiplayerGameResult(rawValue: resultRaw),
              let boardStateRaw = data["boardState"] as? [String],
              let currentTurnRaw = data["currentTurn"] as? String,
              let currentTurn = SquareStatus(rawValue: currentTurnRaw),
              let player1Data = data["player1"] as? [String: Any],
              let settingsData = data["settings"] as? [String: Any] else {
            throw FirebaseError.invalidData
        }
        
        let player1 = dictToPlayer(player1Data)
        let player2 = (data["player2"] as? [String: Any]).map { dictToPlayer($0) }
        let settings = dictToSettings(settingsData)
        let boardState = boardStateRaw.compactMap { SquareStatus(rawValue: $0) }
        
        let moveHistoryData = data["moveHistory"] as? [[String: Any]] ?? []
        let moveHistory = moveHistoryData.compactMap { try? dictToMove($0) }
        
        let chatMessagesData = data["chatMessages"] as? [[String: Any]] ?? []
        let chatMessages = chatMessagesData.compactMap { try? dictToChatMessage($0) }
        
        var game = MultiplayerGame(id: id, player1: player1, player2: player2, settings: settings)
        game.status = status
        game.result = result
        game.boardState = boardState
        game.currentTurn = currentTurn
        game.moveHistory = moveHistory
        game.chatMessages = chatMessages
        game.spectatorCount = data["spectatorCount"] as? Int ?? 0
        game.isPrivate = data["isPrivate"] as? Bool ?? false
        game.startTime = data["startTime"] as? Date
        game.endTime = data["endTime"] as? Date
        game.lastMoveTime = data["lastMoveTime"] as? Date
        game.player1TimeRemaining = data["player1TimeRemaining"] as? TimeInterval
        game.player2TimeRemaining = data["player2TimeRemaining"] as? TimeInterval
        game.currentTurnStartTime = data["currentTurnStartTime"] as? Date
        game.roomCode = data["roomCode"] as? String
        
        return game
    }

    private func firestoreDataToGameListItem(_ data: [String: Any]) throws -> GameListItem {
        guard let id = data["id"] as? String,
              let statusRaw = data["status"] as? String,
              let status = MultiplayerGameStatus(rawValue: statusRaw),
              let player1Data = data["player1"] as? [String: Any],
              let player1Id = player1Data["id"] as? String,
              let player1Username = player1Data["username"] as? String,
              let settingsData = data["settings"] as? [String: Any],
              let boardSize = settingsData["boardSize"] as? Int,
              let isPrivate = data["isPrivate"] as? Bool else {
            throw FirebaseError.invalidData
        }
        
        let player2Username = (data["player2"] as? [String: Any])?["username"] as? String
        let spectatorCount = data["spectatorCount"] as? Int ?? 0
        let roomCode = data["roomCode"] as? String
        let createdAt = data["createdAt"] as? Date ?? Date()
        
        return GameListItem(
            id: id,
            player1Id: player1Id,
            player1Username: player1Username,
            player2Username: player2Username,
            status: status,
            boardSize: boardSize,
            roomCode: roomCode,
            isPrivate: isPrivate,
            spectatorCount: spectatorCount,
            createdAt: createdAt
        )
    }

    private func playerToDict(_ player: Player) -> [String: Any] {
        return [
            "id": player.id,
            "username": player.username,
            "score": player.score,
            "symbol": player.symbol.rawValue,
            "isOnline": player.isOnline,
            "lastActiveTime": player.lastActiveTime
        ]
    }

    private func dictToPlayer(_ dict: [String: Any]) -> Player {
        let id = dict["id"] as? String ?? ""
        let username = dict["username"] as? String ?? "Unknown"
        let score = dict["score"] as? Int ?? 0
        let symbolRaw = dict["symbol"] as? String ?? "x"
        let symbol = SquareStatus(rawValue: symbolRaw) ?? .x
        let isOnline = dict["isOnline"] as? Bool ?? true
        let lastActiveTime = dict["lastActiveTime"] as? Date ?? Date()
        
        return Player(id: id, username: username, score: score, symbol: symbol, isOnline: isOnline, lastActiveTime: lastActiveTime)
    }

    private func settingsToDict(_ settings: MultiplayerGameSettings) -> [String: Any] {
        var dict: [String: Any] = [
            "boardSize": settings.boardSize,
            "winCondition": settings.winCondition,
            "allowSpectators": settings.allowSpectators,
            "isRanked": settings.isRanked,
            "allowChat": settings.allowChat
        ]
        
        if let totalTime = settings.totalTimeLimit {
            dict["totalTimeLimit"] = totalTime
        }
        if let turnTime = settings.turnTimeLimit {
            dict["turnTimeLimit"] = turnTime
        }
        
        return dict
    }

    private func dictToSettings(_ dict: [String: Any]) -> MultiplayerGameSettings {
        let boardSize = dict["boardSize"] as? Int ?? 3
        let winCondition = dict["winCondition"] as? Int
        let totalTimeLimit = dict["totalTimeLimit"] as? TimeInterval
        let turnTimeLimit = dict["turnTimeLimit"] as? TimeInterval
        let allowSpectators = dict["allowSpectators"] as? Bool ?? false
        let isRanked = dict["isRanked"] as? Bool ?? false
        let allowChat = dict["allowChat"] as? Bool ?? true
        
        return MultiplayerGameSettings(
            boardSize: boardSize,
            winCondition: winCondition,
            totalTimeLimit: totalTimeLimit,
            turnTimeLimit: turnTimeLimit,
            allowSpectators: allowSpectators,
            isRanked: isRanked,
            allowChat: allowChat
        )
    }

    private func moveToDict(_ move: GameMove) -> [String: Any] {
        return [
            "id": move.id,
            "playerId": move.playerId,
            "index": move.index,
            "symbol": move.symbol.rawValue,
            "timestamp": move.timestamp,
            "moveNumber": move.moveNumber
        ]
    }

    private func dictToMove(_ dict: [String: Any]) throws -> GameMove {
        guard let id = dict["id"] as? String,
              let playerId = dict["playerId"] as? String,
              let index = dict["index"] as? Int,
              let symbolRaw = dict["symbol"] as? String,
              let symbol = SquareStatus(rawValue: symbolRaw),
              let timestamp = dict["timestamp"] as? Date,
              let moveNumber = dict["moveNumber"] as? Int else {
            throw FirebaseError.invalidData
        }
        
        return GameMove(id: id, playerId: playerId, index: index, symbol: symbol, timestamp: timestamp, moveNumber: moveNumber)
    }

    private func chatMessageToDict(_ message: ChatMessage) -> [String: Any] {
        return [
            "id": message.id,
            "playerId": message.playerId,
            "playerUsername": message.playerUsername,
            "message": message.message,
            "timestamp": message.timestamp,
            "isSystemMessage": message.isSystemMessage
        ]
    }

    private func dictToChatMessage(_ dict: [String: Any]) throws -> ChatMessage {
        guard let id = dict["id"] as? String,
              let playerId = dict["playerId"] as? String,
              let playerUsername = dict["playerUsername"] as? String,
              let message = dict["message"] as? String,
              let timestamp = dict["timestamp"] as? Date else {
            throw FirebaseError.invalidData
        }
        
        let isSystemMessage = dict["isSystemMessage"] as? Bool ?? false
        
        return ChatMessage(id: id, playerId: playerId, playerUsername: playerUsername, message: message, timestamp: timestamp, isSystemMessage: isSystemMessage)
    }
}

// MARK: - Firebase User Model
struct FirebaseUser: Codable {
    let id: String
    let username: String
    let isAnonymous: Bool
}

// MARK: - Firebase Error
enum FirebaseError: LocalizedError {
    case userNotFound, gameNotFound, invalidData, unauthorized, gameFull, invalidMove
    
    var errorDescription: String? {
        switch self {
        case .userNotFound: return "User not found"
        case .gameNotFound: return "Game not found"
        case .invalidData: return "Invalid data format"
        case .unauthorized: return "Unauthorized action"
        case .gameFull: return "Game is full"
        case .invalidMove: return "Invalid move"
        }
    }
}
