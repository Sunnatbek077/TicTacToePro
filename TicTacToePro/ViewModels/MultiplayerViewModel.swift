//
//  MultiplayerViewModel.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 19/10/25.
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
    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "YOUR_SERVER_URL" // Replace with actual server URL
    
    // MARK: - Initialization
    init() {
        // Mock data for testing (remove when backend is ready)
        loadMockData()
    }
    
    // MARK: - Mock Data (for UI testing)
    private func loadMockData() {
        availableGames = [
            GameListItem(
                id: "1",
                player1Username: "Sunnat",
                player2Username: nil,
                status: .waiting,
                boardSize: 3,
                roomCode: "ABC123",
                isPrivate: false,
                spectatorCount: 0,
                createdAt: Date()
            ),
            GameListItem(
                id: "2",
                player1Username: "Aziz",
                player2Username: nil,
                status: .waiting,
                boardSize: 5,
                roomCode: "XYZ789",
                isPrivate: false,
                spectatorCount: 2,
                createdAt: Date().addingTimeInterval(-300)
            ),
            GameListItem(
                id: "3",
                player1Username: "Pro Player",
                player2Username: nil,
                status: .waiting,
                boardSize: 4,
                roomCode: nil,
                isPrivate: true,
                spectatorCount: 0,
                createdAt: Date().addingTimeInterval(-600)
            )
        ]
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
        
        // Create player if not exists
        if currentPlayer == nil {
            currentPlayer = Player(
                username: "Player_\(Int.random(in: 1000...9999))",
                symbol: .x
            )
        }
        
        guard let player = currentPlayer else {
            showErrorMessage("Failed to create player")
            isLoading = false
            return
        }
        
        let settings = MultiplayerGameSettings(
            boardSize: boardSize,
            winCondition: boardSize,
            totalTimeLimit: timeLimit,
            turnTimeLimit: turnTimeLimit,
            allowSpectators: true,
            isRanked: false,
            allowChat: true
        )
        
        // Create game request
        let request = CreateGameRequest(
            playerId: player.id,
            playerUsername: player.username,
            settings: settings,
            isPrivate: isPrivate,
            roomCode: isPrivate ? GameRoom.generateRoomCode() : nil
        )
        
        // TODO: Send request to server
        // For now, create mock game
        createMockGame(player: player, settings: settings, isPrivate: isPrivate)
        
        isLoading = false
    }
    
    /// Join existing game
    func joinGame(gameId: String) async {
        isLoading = true
        errorMessage = nil
        
        // Create player if not exists
        if currentPlayer == nil {
            currentPlayer = Player(
                username: "Player_\(Int.random(in: 1000...9999))",
                symbol: .o
            )
        }
        
        guard let player = currentPlayer else {
            showErrorMessage("Failed to create player")
            isLoading = false
            return
        }
        
        let request = JoinGameRequest(
            playerId: player.id,
            playerUsername: player.username,
            gameId: gameId,
            roomCode: nil
        )
        
        // TODO: Send request to server
        // For now, join mock game
        joinMockGame(gameId: gameId, player: player)
        
        isLoading = false
    }
    
    /// Join game by room code
    func joinGameByCode(_ code: String) async {
        isLoading = true
        errorMessage = nil
        
        if currentPlayer == nil {
            currentPlayer = Player(
                username: "Player_\(Int.random(in: 1000...9999))",
                symbol: .o
            )
        }
        
        guard let player = currentPlayer else {
            showErrorMessage("Failed to create player")
            isLoading = false
            return
        }
        
        let request = JoinGameRequest(
            playerId: player.id,
            playerUsername: player.username,
            gameId: nil,
            roomCode: code
        )
        
        // TODO: Send request to server
        // For now, search mock game by code
        if let game = availableGames.first(where: { $0.roomCode == code }) {
            await joinGame(gameId: game.id)
        } else {
            showErrorMessage("Game not found with code: \(code)")
        }
        
        isLoading = false
    }
    
    /// Make a move in current game
    func makeMove(index: Int) async {
        guard let game = currentGame,
              let player = currentPlayer else { return }
        
        var updatedGame = game
        let success = updatedGame.makeMove(playerId: player.id, index: index)
        
        if success {
            currentGame = updatedGame
            
            // TODO: Send move to server via WebSocket
            sendWebSocketMessage(type: .moveUpdate, data: MakeMoveRequest(
                gameId: game.id,
                playerId: player.id,
                index: index
            ))
        }
    }
    
    /// Send chat message
    func sendChatMessage(_ message: String) {
        guard var game = currentGame,
              let player = currentPlayer else { return }
        
        game.addChatMessage(playerId: player.id, message: message)
        currentGame = game
        
        // TODO: Send to server
        let chatMsg = ChatMessage(
            playerId: player.id,
            playerUsername: player.username,
            message: message
        )
        sendWebSocketMessage(type: .chatMessage, data: chatMsg)
    }
    
    /// Forfeit current game
    func forfeit() async {
        guard var game = currentGame,
              let player = currentPlayer else { return }
        
        game.forfeit(playerId: player.id)
        currentGame = game
        
        // TODO: Notify server
    }
    
    /// Leave current game
    func leaveGame() {
        currentGame = nil
        disconnectWebSocket()
    }
    
    /// Refresh available games list
    func refreshGames() async {
        isLoading = true
        
        // TODO: Fetch from server
        // For now, just reload mock data
        await Task.sleep(1_000_000_000) // 1 second delay
        loadMockData()
        
        isLoading = false
    }
    
    // MARK: - WebSocket Methods
    
    private func connectWebSocket(gameId: String) {
        guard let url = URL(string: "\(baseURL)/games/\(gameId)/connect") else { return }
        
        connectionStatus = .connecting
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        connectionStatus = .connected
        
        receiveWebSocketMessage()
    }
    
    private func disconnectWebSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionStatus = .disconnected
    }
    
    private func sendWebSocketMessage(type: WebSocketMessageType, data: Codable) {
        guard let game = currentGame else { return }
        
        let message = WebSocketMessage(type: type, gameId: game.id, data: data)
        
        guard let jsonData = try? JSONEncoder().encode(message),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(wsMessage) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }
    
    private func receiveWebSocketMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                Task { @MainActor in
                    self.handleWebSocketMessage(message)
                    self.receiveWebSocketMessage() // Continue listening
                }
                
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                Task { @MainActor in
                    self.connectionStatus = .error
                }
            }
        }
    }
    
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8),
                  let wsMessage = try? JSONDecoder().decode(WebSocketMessage.self, from: data) else { return }
            
            processWebSocketMessage(wsMessage)
            
        case .data(let data):
            guard let wsMessage = try? JSONDecoder().decode(WebSocketMessage.self, from: data) else { return }
            processWebSocketMessage(wsMessage)
            
        @unknown default:
            break
        }
    }
    
    private func processWebSocketMessage(_ message: WebSocketMessage) {
        switch message.type {
        case .gameUpdate:
            if let game = try? JSONDecoder().decode(MultiplayerGame.self, from: message.data) {
                currentGame = game
            }
            
        case .moveUpdate:
            if let game = try? JSONDecoder().decode(MultiplayerGame.self, from: message.data) {
                currentGame = game
            }
            
        case .chatMessage:
            if let chatMsg = try? JSONDecoder().decode(ChatMessage.self, from: message.data) {
                currentGame?.chatMessages.append(chatMsg)
            }
            
        case .playerJoined:
            if let player = try? JSONDecoder().decode(Player.self, from: message.data) {
                currentGame?.player2 = player
                currentGame?.status = .active
                currentGame?.startTime = Date()
            }
            
        case .playerLeft:
            showErrorMessage("Opponent left the game")
            currentGame?.status = .abandoned
            
        case .gameStarted:
            currentGame?.status = .active
            currentGame?.startTime = Date()
            
        case .gameEnded:
            if let game = try? JSONDecoder().decode(MultiplayerGame.self, from: message.data) {
                currentGame = game
            }
            
        case .timeUpdate:
            // Handle time updates
            break
            
        case .error:
            if let errorMsg = String(data: message.data, encoding: .utf8) {
                showErrorMessage(errorMsg)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Mock Methods (remove when backend is ready)
    
    private func createMockGame(player: Player, settings: MultiplayerGameSettings, isPrivate: Bool) {
        var game = MultiplayerGame(player1: player, settings: settings)
        game.roomCode = isPrivate ? GameRoom.generateRoomCode() : nil
        game.isPrivate = isPrivate
        
        currentGame = game
        
        // Add to available games list
        let listItem = GameListItem(
            id: game.id,
            player1Username: player.username,
            player2Username: nil,
            status: .waiting,
            boardSize: settings.boardSize,
            roomCode: game.roomCode,
            isPrivate: isPrivate,
            spectatorCount: 0,
            createdAt: Date()
        )
        availableGames.insert(listItem, at: 0)
    }
    
    private func joinMockGame(gameId: String, player: Player) {
        guard let index = availableGames.firstIndex(where: { $0.id == gameId }) else {
            showErrorMessage("Game not found")
            return
        }
        
        let gameItem = availableGames[index]
        
        // Create full game
        var game = MultiplayerGame(
            id: gameItem.id,
            player1: Player(
                username: gameItem.player1Username,
                symbol: .x
            ),
            player2: player,
            settings: MultiplayerGameSettings(boardSize: gameItem.boardSize)
        )
        
        game.startGame()
        currentGame = game
        
        // Update list
        availableGames[index] = GameListItem(
            id: game.id,
            player1Username: gameItem.player1Username,
            player2Username: player.username,
            status: .active,
            boardSize: gameItem.boardSize,
            roomCode: gameItem.roomCode,
            isPrivate: gameItem.isPrivate,
            spectatorCount: gameItem.spectatorCount,
            createdAt: gameItem.createdAt
        )
    }
}

// MARK: - Preview Helper
extension MultiplayerViewModel {
    static var preview: MultiplayerViewModel {
        let vm = MultiplayerViewModel()
        vm.currentPlayer = Player(username: "TestPlayer", symbol: .x)
        return vm
    }
}
