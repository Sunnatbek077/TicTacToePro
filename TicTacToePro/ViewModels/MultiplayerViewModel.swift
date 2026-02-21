//
//  MultiplayerViewModel.swift
//  TicTacToePro
//
//  Updated with Firebase integration
//

import Foundation
import SwiftUI
import Combine

// MARK: - Connection Status
enum ConnectionStatus: String {
    case disconnected = "Disconnected"
    case connecting = "Connecting..."
    case connected = "Connected"
    case error = "Connection Error"
}

// MARK: - Multiplayer ViewModel
@MainActor
class MultiplayerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var availableGames: [GameListItem] = []
    @Published var currentGame: MultiplayerGame?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // Current player info
    @Published var currentPlayer: Player?
    
    // MARK: - Private Properties
    private let firebaseManager = FirebaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentGameId: String?
    
    // MARK: - Initialization
    init() {
        setupFirebaseObservers()
        Task {
            await authenticateUser()
        }
    }
    
    deinit {
        // Call cleanup directly if already on MainActor
        // Or use unstructured task without capturing self strongly
        Task { [weak self] in
            await self?.cleanup()
        }
    }
    
    // MARK: - Setup
    
    private func setupFirebaseObservers() {
        // Observe Firebase authentication state
        firebaseManager.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuth in
                guard let self = self else { return }
                self.connectionStatus = isAuth ? .connected : .disconnected
            }
            .store(in: &cancellables)
        
        // Observe Firebase user
        firebaseManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] firebaseUser in
                guard let self = self, let fbUser = firebaseUser else { return }
                
                // Create or update player from Firebase user
                if let existingPlayer = self.currentPlayer {
                    // Update existing player if username changed
                    if existingPlayer.username != fbUser.username {
                        self.currentPlayer = Player(
                            id: existingPlayer.id,
                            username: fbUser.username,
                            score: existingPlayer.score,
                            symbol: existingPlayer.symbol,
                            isOnline: existingPlayer.isOnline,
                            lastActiveTime: Date()
                        )
                    }
                } else {
                    // Create new player from Firebase user
                    self.currentPlayer = Player(
                        id: fbUser.id,
                        username: fbUser.username,
                        score: 0,
                        symbol: .x, // Will be assigned when joining/creating game
                        isOnline: true,
                        lastActiveTime: Date()
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    private func authenticateUser() async {
        connectionStatus = .connecting
        
        do {
            let firebaseUser = try await firebaseManager.signInAnonymously()
            
            // Create player from Firebase user
            currentPlayer = Player(
                id: firebaseUser.id,
                username: firebaseUser.username,
                score: 0,
                symbol: .x,
                isOnline: true,
                lastActiveTime: Date()
            )
            
            connectionStatus = .connected
        } catch {
            print("Authentication error: \(error) (Code: \((error as NSError).code))")
            connectionStatus = .error
            showErrorMessage("Authentication failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Create a new game lobby
    func createGame(
        gameName: String,
        boardSize: Int,
        timeLimit: TimeInterval?,
        turnTimeLimit: TimeInterval?,
        isPrivate: Bool
    ) async {
        isLoading = true
        errorMessage = nil
        
        guard let player = currentPlayer else {
            showErrorMessage("Not authenticated")
            isLoading = false
            return
        }
        
        do {
            let settings = MultiplayerGameSettings(
                boardSize: boardSize,
                winCondition: boardSize,
                totalTimeLimit: timeLimit,
                turnTimeLimit: turnTimeLimit,
                allowSpectators: true,
                isRanked: false,
                allowChat: true
            )
            
            // Initialize MultiplayerGame with all required properties
            var game = MultiplayerGame(
                id: UUID().uuidString, // Temporary ID, will be updated by Firebase
                player1: player,
                player2: nil,
                settings: settings
            )
            
            // Set private game properties
            game.isPrivate = isPrivate
            if isPrivate {
                game.roomCode = GameRoom.generateRoomCode()
            }
            
            // Create game in Firebase
            let gameId = try await firebaseManager.createGame(game)
            currentGameId = gameId
            
            // Listen to game updates
            listenToGameUpdates(gameId: gameId)
            
            // Fetch the updated game to ensure consistency
            let updatedGame = try await firebaseManager.fetchGame(gameId: gameId)
            currentGame = updatedGame
            
        } catch {
            showErrorMessage("Failed to create game: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Join existing game
    func joinGame(gameId: String) async {
        isLoading = true
        errorMessage = nil
        
        guard let player = currentPlayer else {
            showErrorMessage("Not authenticated")
            isLoading = false
            return
        }
        
        do {
            // Fetch game first to determine player symbol
            let game = try await firebaseManager.fetchGame(gameId: gameId)
            
            // Assign opposite symbol, create new Player instance
            let newSymbol = game.player1.symbol == .x ? SquareStatus.o : SquareStatus.x
            let updatedPlayer = Player(
                id: player.id,
                username: player.username,
                score: player.score,
                symbol: newSymbol,
                isOnline: player.isOnline,
                lastActiveTime: player.lastActiveTime
            )
            currentPlayer = updatedPlayer
            
            // Join game in Firebase
            try await firebaseManager.joinGame(gameId: gameId, player: updatedPlayer)
            
            // Listen to game updates
            currentGameId = gameId
            listenToGameUpdates(gameId: gameId)
            
            // Fetch updated game
            let updatedGame = try await firebaseManager.fetchGame(gameId: gameId)
            currentGame = updatedGame
            
        } catch {
            showErrorMessage("Failed to join game: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Join game by room code
    func joinGameByCode(_ code: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Find game by room code
            let gameId = try await firebaseManager.findGameByRoomCode(code)
            
            // Join the game
            await joinGame(gameId: gameId)
            
        } catch {
            showErrorMessage("Game not found with code: \(code)")
        }
        
        isLoading = false
    }
    
    /// Make a move in current game
    func makeMove(index: Int) async {
        guard let gameId = currentGameId,
              let player = currentPlayer else { return }
        
        do {
            try await firebaseManager.makeMove(gameId: gameId, playerId: player.id, index: index)
            // Game will be updated via listener
        } catch {
            showErrorMessage("Failed to make move: \(error.localizedDescription)")
        }
    }
    
    /// Send chat message
    func sendChatMessage(_ message: String) {
        guard let gameId = currentGameId,
              let player = currentPlayer else { return }
        
        let chatMsg = ChatMessage(
            playerId: player.id,
            playerUsername: player.username,
            message: message
        )
        
        Task {
            do {
                try await firebaseManager.addChatMessage(gameId: gameId, message: chatMsg)
            } catch {
                showErrorMessage("Failed to send message: \(error.localizedDescription)")
            }
        }
    }
    
    /// Forfeit current game
    func forfeit() async {
        guard let gameId = currentGameId,
              let player = currentPlayer else { return }
        
        do {
            try await firebaseManager.forfeitGame(gameId: gameId, playerId: player.id)
            // Game will be updated via listener
        } catch {
            showErrorMessage("Failed to forfeit: \(error.localizedDescription)")
        }
    }
    
    /// Leave current game
    func leaveGame() {
        if let gameId = currentGameId {
            firebaseManager.stopListeningToGame(gameId: gameId)
        }
        
        currentGame = nil
        currentGameId = nil
    }
    
    /// Refresh available games list
    func refreshGames() async {
        isLoading = true
        
        do {
            // Clean up expired waiting games before fetching
            await checkAndCleanExpiredGames()
            
            let games = try await firebaseManager.fetchAvailableGames()
            availableGames = games
        } catch {
            showErrorMessage("Failed to fetch games: \(error.localizedDescription)")
        }
        
        isLoading = false
    }

    /// Deletes all waiting games that have exceeded their expiry time
    private func checkAndCleanExpiredGames() async {
        // Cleanup moved behind FirebaseManager to avoid accessing private internals.
        // No-op here to keep ViewModel decoupled from Firebase details.
        #if DEBUG
        print("checkAndCleanExpiredGames: skipped (no public API on FirebaseManager)")
        #endif
    }
    
    /// Refresh the current game from Firebase
    func refreshCurrentGame() async {
        guard let gameId = currentGameId else { return }
        
        do {
            let updatedGame = try await firebaseManager.fetchGame(gameId: gameId)
            currentGame = updatedGame
        } catch {
            // Silently fail to avoid interrupting gameplay
            // Error is already handled by the real-time listener
            print("Failed to refresh current game: \(error.localizedDescription)")
        }
    }
    
    /// Delete a game
    func deleteGame(gameId: String) async {
        do {
            try await firebaseManager.deleteGame(gameId: gameId)
            await refreshGames()
        } catch {
            showErrorMessage("Failed to delete game: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Real-time Updates
    
    private func listenToGameUpdates(gameId: String) {
        firebaseManager.listenToGame(gameId: gameId) { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let game):
                    self.currentGame = game
                    
                    // Update player's last active time periodically
                    Task {
                        try? await self.firebaseManager.updateLastActive()
                    }
                    
                case .failure(let error):
                    self.showErrorMessage("Connection error: \(error.localizedDescription)")
                    self.connectionStatus = .error
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func cleanup() {
        if let gameId = currentGameId {
            firebaseManager.stopListeningToGame(gameId: gameId)
        }
        cancellables.removeAll()
    }

    // MARK: - Profile / Username
    func updateUsername(_ newUsername: String) async {
        let trimmed = newUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let playerId = currentPlayer?.id else {
            showErrorMessage("Not authenticated")
            return
        }
        
        do {
            // 1. Update Firebase user document
            try await firebaseManager.updateUsername(trimmed)
            
            // 2. Wait a moment to ensure Firebase user update is propagated
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // 3. Refresh currentUser from Firebase to ensure we have the latest
            if let userId = firebaseManager.currentUser?.id {
                let updatedFirebaseUser = try await firebaseManager.fetchUser(userId: userId)
                await MainActor.run {
                    firebaseManager.currentUser = updatedFirebaseUser
                }
            }
            
            // 4. Update local currentPlayer with the new username
            if let player = self.currentPlayer {
                self.currentPlayer = Player(
                    id: player.id,
                    username: trimmed,
                    score: player.score,
                    symbol: player.symbol,
                    isOnline: player.isOnline,
                    lastActiveTime: Date()
                )
            }
            
            // 5. Update currentGame in Firebase using transaction
            if let gameId = self.currentGameId {
                try await firebaseManager.updatePlayerUsernameInGame(
                    gameId: gameId,
                    playerId: playerId,
                    newUsername: trimmed
                )
                
                // 6. Manually update local game snapshot to ensure UI updates immediately
                // The listener will also update it, but we want immediate UI feedback
                if var game = self.currentGame {
                    if game.player1.id == playerId {
                        game.player1 = Player(
                            id: game.player1.id,
                            username: trimmed,
                            score: game.player1.score,
                            symbol: game.player1.symbol,
                            isOnline: game.player1.isOnline,
                            lastActiveTime: Date()
                        )
                    } else if let p2 = game.player2, p2.id == playerId {
                        game.player2 = Player(
                            id: p2.id,
                            username: trimmed,
                            score: p2.score,
                            symbol: p2.symbol,
                            isOnline: p2.isOnline,
                            lastActiveTime: Date()
                        )
                    }
                    // Set currentGame to trigger UI update
                    self.currentGame = game
                }
            }
        } catch {
            showErrorMessage("Failed to update username: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview Helper
extension MultiplayerViewModel {
    static var preview: MultiplayerViewModel {
        let vm = MultiplayerViewModel()
        vm.currentPlayer = Player(
            id: UUID().uuidString,
            username: "TestPlayer",
            score: 0,
            symbol: .x,
            isOnline: true,
            lastActiveTime: Date()
        )
        vm.connectionStatus = .connected
        return vm
    }
}

