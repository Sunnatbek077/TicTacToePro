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
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(
            sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited)
        )
        db.settings = settings
        startAuthStateListener()
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Authentication
    
    func signInAnonymously() async throws -> FirebaseUser {
        do {
            let result = try await auth.signInAnonymously()
            let userId = result.user.uid
            
            var savedUsername: String?
            do {
                let existingUser = try await fetchUser(userId: userId)
                savedUsername = existingUser.username
            } catch FirebaseError.userNotFound {
                print("[Auth] No existing user found for uid \(userId) — will create new one.")
            } catch {
                print("[Auth] Failed to fetch existing user for uid \(userId): \(error.localizedDescription)")
            }
            
            let username = savedUsername ?? "Player_\(Int.random(in: 1000...9999))"
            let user = FirebaseUser(id: userId, username: username, isAnonymous: true)
            
            do {
                try await saveUser(user)
            } catch {
                print("[Auth] Failed to save user to Firestore (uid: \(userId)): \(error.localizedDescription)")
                throw FirebaseError.saveFailed(reason: error.localizedDescription)
            }
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
            
            return user
        } catch let error as FirebaseError {
            throw error
        } catch {
            print("[Auth] Anonymous sign-in failed: \(error.localizedDescription)")
            throw FirebaseError.authFailed(reason: error.localizedDescription)
        }
    }
    
    func signInWithUsername(_ username: String) async throws -> FirebaseUser {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("[Auth] Sign-in failed: username is empty.")
            throw FirebaseError.invalidInput(field: "username", reason: "Username must not be empty.")
        }
        
        do {
            let result = try await auth.signInAnonymously()
            let user = FirebaseUser(id: result.user.uid, username: username, isAnonymous: true)
            
            do {
                try await saveUser(user)
            } catch {
                print("[Auth] Failed to save user '\(username)' to Firestore: \(error.localizedDescription)")
                throw FirebaseError.saveFailed(reason: error.localizedDescription)
            }
            
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
            
            return user
        } catch let error as FirebaseError {
            throw error
        } catch {
            print("[Auth] Sign-in with username '\(username)' failed: \(error.localizedDescription)")
            throw FirebaseError.authFailed(reason: error.localizedDescription)
        }
    }
    
    private func startAuthStateListener() {
        authStateListenerHandle = auth.addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            if let user = user {
                Task {
                    do {
                        let firebaseUser = try await self.fetchUser(userId: user.uid)
                        await MainActor.run {
                            self.currentUser = firebaseUser
                            self.isAuthenticated = true
                        }
                    } catch FirebaseError.userNotFound {
                        print("[Auth] Auth state changed but user document not found for uid: \(user.uid)")
                    } catch {
                        print("[Auth] Failed to fetch user data on auth state change (uid: \(user.uid)): \(error.localizedDescription)")
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
    
    func signOut() throws {
        do {
            try auth.signOut()
        } catch {
            print("[Auth] Sign-out failed: \(error.localizedDescription)")
            throw FirebaseError.authFailed(reason: error.localizedDescription)
        }
        
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
        
        do {
            try await db.collection("users").document(user.id).setData(userData, merge: true)
        } catch {
            print("[Firestore] Failed to save user '\(user.username)' (id: \(user.id)): \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateUsername(_ newUsername: String) async throws {
        guard !newUsername.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("[User] Update username failed: new username is empty.")
            throw FirebaseError.invalidInput(field: "username", reason: "New username must not be empty.")
        }
        
        guard let userId = currentUser?.id else {
            print("[User] Update username failed: no authenticated user.")
            throw FirebaseError.userNotFound
        }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "username": newUsername,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } catch {
            print("[User] Failed to update username to '\(newUsername)' for user \(userId): \(error.localizedDescription)")
            throw FirebaseError.updateFailed(reason: error.localizedDescription)
        }
        
        await MainActor.run {
            if let current = self.currentUser {
                self.currentUser = FirebaseUser(id: current.id, username: newUsername, isAnonymous: current.isAnonymous)
            }
        }
    }
    
    func fetchUser(userId: String) async throws -> FirebaseUser {
        guard !userId.isEmpty else {
            print("[User] Fetch failed: userId is empty.")
            throw FirebaseError.invalidInput(field: "userId", reason: "User ID must not be empty.")
        }
        
        let doc: DocumentSnapshot
        do {
            doc = try await db.collection("users").document(userId).getDocument()
        } catch {
            print("[User] Failed to fetch document for userId '\(userId)': \(error.localizedDescription)")
            throw FirebaseError.fetchFailed(reason: error.localizedDescription)
        }
        
        guard let data = doc.data() else {
            print("[User] No document data found for userId '\(userId)'.")
            throw FirebaseError.userNotFound
        }
        
        return FirebaseUser(
            id: data["id"] as? String ?? userId,
            username: data["username"] as? String ?? "Unknown",
            isAnonymous: data["isAnonymous"] as? Bool ?? true
        )
    }
    
    func updateLastActive() async throws {
        guard let userId = currentUser?.id else {
            print("[User] updateLastActive skipped: no authenticated user.")
            return
        }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "lastActiveAt": FieldValue.serverTimestamp()
            ])
        } catch {
            print("[User] Failed to update lastActiveAt for user \(userId): \(error.localizedDescription)")
            throw FirebaseError.updateFailed(reason: error.localizedDescription)
        }
    }
    
    // MARK: - Game Management
    
    func createGame(_ game: MultiplayerGame) async throws -> String {
        let gameRef = db.collection("games").document()
        let gameId = gameRef.documentID
        
        var gameData: [String: Any]
        do {
            gameData = try gameToFirestoreData(game)
        } catch {
            print("[Game] Failed to serialize game data before creating: \(error.localizedDescription)")
            throw FirebaseError.invalidData
        }
        
        gameData["id"] = gameId
        gameData["createdAt"] = FieldValue.serverTimestamp()
        gameData["updatedAt"] = FieldValue.serverTimestamp()
        
        do {
            try await gameRef.setData(gameData)
        } catch {
            print("[Game] Failed to create game document (gameId: \(gameId)): \(error.localizedDescription)")
            throw FirebaseError.saveFailed(reason: error.localizedDescription)
        }
        
        return gameId
    }
    
    func fetchGame(gameId: String) async throws -> MultiplayerGame {
        guard !gameId.isEmpty else {
            print("[Game] Fetch failed: gameId is empty.")
            throw FirebaseError.invalidInput(field: "gameId", reason: "Game ID must not be empty.")
        }
        
        let doc: DocumentSnapshot
        do {
            doc = try await db.collection("games").document(gameId).getDocument()
        } catch {
            print("[Game] Failed to fetch document for gameId '\(gameId)': \(error.localizedDescription)")
            throw FirebaseError.fetchFailed(reason: error.localizedDescription)
        }
        
        guard let data = doc.data() else {
            print("[Game] No document data found for gameId '\(gameId)'.")
            throw FirebaseError.gameNotFound
        }
        
        do {
            return try firestoreDataToGame(data)
        } catch {
            print("[Game] Failed to parse game data for gameId '\(gameId)': \(error.localizedDescription)")
            throw FirebaseError.invalidData
        }
    }
    
    func updateGame(_ game: MultiplayerGame) async throws {
        var gameData: [String: Any]
        do {
            gameData = try gameToFirestoreData(game)
        } catch {
            print("[Game] Failed to serialize game data for update (gameId: \(game.id)): \(error.localizedDescription)")
            throw FirebaseError.invalidData
        }
        
        do {
            try await db.collection("games").document(game.id).updateData(
                gameData.merging(["updatedAt": FieldValue.serverTimestamp()]) { _, new in new }
            )
        } catch {
            print("[Game] Failed to update game (gameId: \(game.id)): \(error.localizedDescription)")
            throw FirebaseError.updateFailed(reason: error.localizedDescription)
        }
    }
    
    func updatePlayerUsernameInGame(gameId: String, playerId: String, newUsername: String) async throws {
        guard !newUsername.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("[Game] Update player username failed: new username is empty (gameId: \(gameId), playerId: \(playerId)).")
            throw FirebaseError.invalidInput(field: "username", reason: "New username must not be empty.")
        }
        
        let gameRef = db.collection("games").document(gameId)
        
        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                let gameDoc: DocumentSnapshot
                do {
                    gameDoc = try transaction.getDocument(gameRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
                
                guard let data = gameDoc.data() else {
                    errorPointer?.pointee = NSError(
                        domain: "FirebaseManager",
                        code: FirebaseErrorCode.gameNotFound.rawValue,
                        userInfo: [NSLocalizedDescriptionKey: "Game not found (gameId: \(gameId))"]
                    )
                    return nil
                }
                
                if let player1Data = data["player1"] as? [String: Any],
                   let player1Id = player1Data["id"] as? String,
                   player1Id == playerId {
                    var updatedPlayer1 = player1Data
                    updatedPlayer1["username"] = newUsername
                    updatedPlayer1["lastActiveTime"] = FieldValue.serverTimestamp()
                    transaction.updateData(["player1": updatedPlayer1, "updatedAt": FieldValue.serverTimestamp()], forDocument: gameRef)
                    
                } else if let player2Data = data["player2"] as? [String: Any],
                          let player2Id = player2Data["id"] as? String,
                          player2Id == playerId {
                    var updatedPlayer2 = player2Data
                    updatedPlayer2["username"] = newUsername
                    updatedPlayer2["lastActiveTime"] = FieldValue.serverTimestamp()
                    transaction.updateData(["player2": updatedPlayer2, "updatedAt": FieldValue.serverTimestamp()], forDocument: gameRef)
                    
                } else {
                    print("[Game] Player \(playerId) not found in game \(gameId) — username update skipped.")
                }
                
                return nil
            }
        } catch {
            print("[Game] Transaction failed while updating username for player \(playerId) in game \(gameId): \(error.localizedDescription)")
            throw FirebaseError.updateFailed(reason: error.localizedDescription)
        }
    }
    
    func joinGame(gameId: String, player: Player) async throws {
        let gameRef = db.collection("games").document(gameId)
        
        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                let gameDoc: DocumentSnapshot
                do {
                    gameDoc = try transaction.getDocument(gameRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
                
                guard let data = gameDoc.data() else {
                    errorPointer?.pointee = NSError(
                        domain: "FirebaseManager",
                        code: FirebaseErrorCode.gameNotFound.rawValue,
                        userInfo: [NSLocalizedDescriptionKey: "Game not found (gameId: \(gameId))"]
                    )
                    return nil
                }
                
                if data["player2"] != nil {
                    errorPointer?.pointee = NSError(
                        domain: "FirebaseManager",
                        code: FirebaseErrorCode.gameFull.rawValue,
                        userInfo: [NSLocalizedDescriptionKey: "Game is already full (gameId: \(gameId))"]
                    )
                    return nil
                }
                
                transaction.updateData([
                    "player2": self.playerToDict(player),
                    "status": MultiplayerGameStatus.active.rawValue,
                    "startTime": FieldValue.serverTimestamp(),
                    "currentTurnStartTime": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ], forDocument: gameRef)
                
                return nil
            }
        } catch let error as NSError where error.code == FirebaseErrorCode.gameFull.rawValue {
            print("[Game] Join failed — game is full (gameId: \(gameId), player: \(player.id)).")
            throw FirebaseError.gameFull
        } catch {
            print("[Game] Transaction failed while joining game \(gameId) for player \(player.id): \(error.localizedDescription)")
            throw FirebaseError.updateFailed(reason: error.localizedDescription)
        }
    }
    
    func makeMove(gameId: String, playerId: String, index: Int) async throws {
        guard index >= 0 else {
            print("[Game] makeMove failed: invalid index \(index) (gameId: \(gameId), playerId: \(playerId)).")
            throw FirebaseError.invalidMove
        }
        
        let gameRef = db.collection("games").document(gameId)
        
        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                let gameDoc: DocumentSnapshot
                do {
                    gameDoc = try transaction.getDocument(gameRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
                
                guard let data = gameDoc.data() else {
                    errorPointer?.pointee = NSError(
                        domain: "FirebaseManager",
                        code: FirebaseErrorCode.gameNotFound.rawValue,
                        userInfo: [NSLocalizedDescriptionKey: "Game not found (gameId: \(gameId))"]
                    )
                    return nil
                }
                
                do {
                    var game = try self.firestoreDataToGame(data)
                    
                    guard game.makeMove(playerId: playerId, index: index) else {
                        print("[Game] Invalid move rejected — playerId: \(playerId), index: \(index), gameId: \(gameId).")
                        errorPointer?.pointee = NSError(
                            domain: "FirebaseManager",
                            code: FirebaseErrorCode.invalidMove.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid move at index \(index) for player \(playerId)"]
                        )
                        return nil
                    }
                    
                    let updatedData = try self.gameToFirestoreData(game)
                    transaction.updateData(
                        updatedData.merging(["updatedAt": FieldValue.serverTimestamp()]) { _, new in new },
                        forDocument: gameRef
                    )
                } catch {
                    errorPointer?.pointee = error as NSError
                }
                
                return nil
            }
        } catch let error as NSError where error.code == FirebaseErrorCode.invalidMove.rawValue {
            throw FirebaseError.invalidMove
        } catch {
            print("[Game] Transaction failed while making move (gameId: \(gameId), playerId: \(playerId), index: \(index)): \(error.localizedDescription)")
            throw FirebaseError.updateFailed(reason: error.localizedDescription)
        }
    }
    
    func listenToGame(gameId: String, completion: @escaping (Result<MultiplayerGame, Error>) -> Void) {
        guard !gameId.isEmpty else {
            print("[Game] listenToGame failed: gameId is empty.")
            completion(.failure(FirebaseError.invalidInput(field: "gameId", reason: "Game ID must not be empty.")))
            return
        }
        
        let listener = db.collection("games").document(gameId)
            .addSnapshotListener { snapshot, error in
                if let error {
                    print("[Game] Snapshot listener error for gameId '\(gameId)': \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("[Game] Snapshot received nil data for gameId '\(gameId)'.")
                    completion(.failure(FirebaseError.gameNotFound))
                    return
                }
                
                do {
                    let game = try self.firestoreDataToGame(data)
                    completion(.success(game))
                } catch {
                    print("[Game] Failed to parse snapshot data for gameId '\(gameId)': \(error.localizedDescription)")
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
        let snapshot: QuerySnapshot
        do {
            snapshot = try await db.collection("games")
                .whereField("status", in: [
                    MultiplayerGameStatus.waiting.rawValue,
                    MultiplayerGameStatus.active.rawValue
                ])
                .whereField("isPrivate", isEqualTo: false)
                .order(by: "createdAt", descending: true)
                .limit(to: 20)
                .getDocuments()
        } catch {
            print("[Game] Failed to fetch available games: \(error.localizedDescription)")
            throw FirebaseError.fetchFailed(reason: error.localizedDescription)
        }
        
        return snapshot.documents.compactMap { doc in
            do {
                return try firestoreDataToGameListItem(doc.data())
            } catch {
                print("[Game] Failed to parse game list item (docId: \(doc.documentID)): \(error.localizedDescription)")
                return nil
            }
        }
    }
    
    func addChatMessage(gameId: String, message: ChatMessage) async throws {
        guard !message.message.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("[Chat] Rejected empty message from player \(message.playerId) in game \(gameId).")
            throw FirebaseError.invalidInput(field: "message", reason: "Chat message must not be empty.")
        }
        
        let gameRef = db.collection("games").document(gameId)
        
        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                let gameDoc: DocumentSnapshot
                do {
                    gameDoc = try transaction.getDocument(gameRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
                
                guard var data = gameDoc.data() else {
                    errorPointer?.pointee = NSError(
                        domain: "FirebaseManager",
                        code: FirebaseErrorCode.gameNotFound.rawValue,
                        userInfo: [NSLocalizedDescriptionKey: "Game not found (gameId: \(gameId))"]
                    )
                    return nil
                }
                
                var chatMessages = data["chatMessages"] as? [[String: Any]] ?? []
                chatMessages.append(self.chatMessageToDict(message))
                data["chatMessages"] = chatMessages
                data["updatedAt"] = FieldValue.serverTimestamp()
                
                transaction.updateData(data, forDocument: gameRef)
                return nil
            }
        } catch {
            print("[Chat] Failed to add message to game \(gameId) from player \(message.playerId): \(error.localizedDescription)")
            throw FirebaseError.updateFailed(reason: error.localizedDescription)
        }
    }
    
    func forfeitGame(gameId: String, playerId: String) async throws {
        let gameRef = db.collection("games").document(gameId)
        
        do {
            _ = try await db.runTransaction { transaction, errorPointer in
                let gameDoc: DocumentSnapshot
                do {
                    gameDoc = try transaction.getDocument(gameRef)
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
                
                guard let data = gameDoc.data() else {
                    errorPointer?.pointee = NSError(
                        domain: "FirebaseManager",
                        code: FirebaseErrorCode.gameNotFound.rawValue,
                        userInfo: [NSLocalizedDescriptionKey: "Game not found (gameId: \(gameId))"]
                    )
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
                }
                
                return nil
            }
        } catch {
            print("[Game] Forfeit transaction failed for player \(playerId) in game \(gameId): \(error.localizedDescription)")
            throw FirebaseError.updateFailed(reason: error.localizedDescription)
        }
    }
    
    func findGameByRoomCode(_ code: String) async throws -> String {
        guard !code.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("[Game] findGameByRoomCode failed: room code is empty.")
            throw FirebaseError.invalidInput(field: "roomCode", reason: "Room code must not be empty.")
        }
        
        let snapshot: QuerySnapshot
        do {
            snapshot = try await db.collection("games")
                .whereField("roomCode", isEqualTo: code)
                .limit(to: 1)
                .getDocuments()
        } catch {
            print("[Game] Failed to query game by room code '\(code)': \(error.localizedDescription)")
            throw FirebaseError.fetchFailed(reason: error.localizedDescription)
        }
        
        guard let doc = snapshot.documents.first else {
            print("[Game] No game found with room code '\(code)'.")
            throw FirebaseError.gameNotFound
        }
        
        return doc.documentID
    }
    
    func deleteGame(gameId: String) async throws {
        do {
            try await db.collection("games").document(gameId).delete()
        } catch {
            print("[Game] Failed to delete game (gameId: \(gameId)): \(error.localizedDescription)")
            throw FirebaseError.updateFailed(reason: error.localizedDescription)
        }
        stopListeningToGame(gameId: gameId)
    }
    
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
            "isPrivate": game.isPrivate,
            "createdAt": game.createdAt,
            "waitExpiresAt": game.waitExpiresAt
        ]
        
        if let player2 = game.player2 { data["player2"] = playerToDict(player2) }
        if let startTime = game.startTime { data["startTime"] = startTime }
        if let endTime = game.endTime { data["endTime"] = endTime }
        if let lastMoveTime = game.lastMoveTime { data["lastMoveTime"] = lastMoveTime }
        if let player1Time = game.player1TimeRemaining { data["player1TimeRemaining"] = player1Time }
        if let player2Time = game.player2TimeRemaining { data["player2TimeRemaining"] = player2Time }
        if let turnStart = game.currentTurnStartTime { data["currentTurnStartTime"] = turnStart }
        if let roomCode = game.roomCode { data["roomCode"] = roomCode }
        
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
            print("[Parser] firestoreDataToGame failed — missing or malformed required fields. Data keys: \(data.keys.joined(separator: ", "))")
            throw FirebaseError.invalidData
        }
        
        let player1 = dictToPlayer(player1Data)
        let player2 = (data["player2"] as? [String: Any]).map { dictToPlayer($0) }
        let settings = dictToSettings(settingsData)
        let boardState = boardStateRaw.compactMap { SquareStatus(rawValue: $0) }
        
        let moveHistoryData = data["moveHistory"] as? [[String: Any]] ?? []
        let moveHistory: [GameMove] = moveHistoryData.compactMap {
            do {
                return try dictToMove($0)
            } catch {
                print("[Parser] Failed to parse move entry — skipping. Error: \(error.localizedDescription)")
                return nil
            }
        }
        
        let chatMessagesData = data["chatMessages"] as? [[String: Any]] ?? []
        let chatMessages: [ChatMessage] = chatMessagesData.compactMap {
            do {
                return try dictToChatMessage($0)
            } catch {
                print("[Parser] Failed to parse chat message entry — skipping. Error: \(error.localizedDescription)")
                return nil
            }
        }
        
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
            print("[Parser] firestoreDataToGameListItem failed — missing required fields. Data keys: \(data.keys.joined(separator: ", "))")
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
        if let totalTime = settings.totalTimeLimit { dict["totalTimeLimit"] = totalTime }
        if let turnTime = settings.turnTimeLimit { dict["turnTimeLimit"] = turnTime }
        return dict
    }

    private func dictToSettings(_ dict: [String: Any]) -> MultiplayerGameSettings {
        return MultiplayerGameSettings(
            boardSize: dict["boardSize"] as? Int ?? 3,
            winCondition: dict["winCondition"] as? Int,
            totalTimeLimit: dict["totalTimeLimit"] as? TimeInterval,
            turnTimeLimit: dict["turnTimeLimit"] as? TimeInterval,
            allowSpectators: dict["allowSpectators"] as? Bool ?? false,
            isRanked: dict["isRanked"] as? Bool ?? false,
            allowChat: dict["allowChat"] as? Bool ?? true
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
            print("[Parser] dictToMove failed — missing or malformed fields. Keys: \(dict.keys.joined(separator: ", "))")
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
            print("[Parser] dictToChatMessage failed — missing or malformed fields. Keys: \(dict.keys.joined(separator: ", "))")
            throw FirebaseError.invalidData
        }
        return ChatMessage(
            id: id,
            playerId: playerId,
            playerUsername: playerUsername,
            message: message,
            timestamp: timestamp,
            isSystemMessage: dict["isSystemMessage"] as? Bool ?? false
        )
    }
}

// MARK: - Firebase User Model
struct FirebaseUser: Codable {
    let id: String
    let username: String
    let isAnonymous: Bool
}

// MARK: - Firebase Error Codes (for NSError interop in transactions)
enum FirebaseErrorCode: Int {
    case gameNotFound = 1
    case gameFull     = 2
    case invalidMove  = 3
    case unauthorized = 4
}

// MARK: - Firebase Error
enum FirebaseError: LocalizedError {
    case userNotFound
    case gameNotFound
    case invalidData
    case unauthorized
    case gameFull
    case invalidMove
    case authFailed(reason: String)
    case saveFailed(reason: String)
    case fetchFailed(reason: String)
    case updateFailed(reason: String)
    case invalidInput(field: String, reason: String)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found."
        case .gameNotFound:
            return "Game not found."
        case .invalidData:
            return "Invalid or malformed data format."
        case .unauthorized:
            return "Unauthorized action."
        case .gameFull:
            return "The game is already full."
        case .invalidMove:
            return "The requested move is invalid."
        case .authFailed(let reason):
            return "Authentication failed: \(reason)"
        case .saveFailed(let reason):
            return "Failed to save data: \(reason)"
        case .fetchFailed(let reason):
            return "Failed to fetch data: \(reason)"
        case .updateFailed(let reason):
            return "Failed to update data: \(reason)"
        case .invalidInput(let field, let reason):
            return "Invalid input for '\(field)': \(reason)"
        }
    }
}
