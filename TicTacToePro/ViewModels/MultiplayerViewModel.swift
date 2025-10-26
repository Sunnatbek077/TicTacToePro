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
        // Wrap cleanup in a Task to ensure main actor isolation
        Task { @MainActor in
            self.cleanup()
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
                
                // Convert Firebase user to Player
                if self.currentPlayer == nil {
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
            let game = MultiplayerGame(
                id: UUID().uuidString, // Temporary ID, will be updated by Firebase
                player1: player,
                player2: nil,
                settings: settings
            )
            
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
            let games = try await firebaseManager.fetchAvailableGames()
            availableGames = games
        } catch {
            showErrorMessage("Failed to fetch games: \(error.localizedDescription)")
        }
        
        isLoading = false
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
