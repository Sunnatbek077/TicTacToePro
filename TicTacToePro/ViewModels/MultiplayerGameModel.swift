//
//  MultiplayerGameModel.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 17/10/25.
//

import Foundation

// MARK: - Player
struct Player: Codable, Identifiable, Equatable {
    let id: String
    let username: String
    var score: Int
    let symbol: SquareStatus // .x yoki .o
    var isOnline: Bool
    var lastActiveTime: Date
    
    enum CodingKeys: String, CodingKey {
        case id, username, score, symbol, isOnline, lastActiveTime
    }
    
    init(id: String = UUID().uuidString,
         username: String,
         score: Int = 0,
         symbol: SquareStatus,
         isOnline: Bool = true,
         lastActiveTime: Date = Date()) {
        self.id = id
        self.username = username
        self.score = score
        self.symbol = symbol
        self.isOnline = isOnline
        self.lastActiveTime = lastActiveTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        score = try container.decode(Int.self, forKey: .score)
        
        let symbolString = try container.decode(String.self, forKey: .symbol)
        symbol = SquareStatus(rawValue: symbolString) ?? .empty
        
        isOnline = try container.decode(Bool.self, forKey: .isOnline)
        lastActiveTime = try container.decode(Date.self, forKey: .lastActiveTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(username, forKey: .username)
        try container.encode(score, forKey: .score)
        try container.encode(symbol.rawValue, forKey: .symbol)
        try container.encode(isOnline, forKey: .isOnline)
        try container.encode(lastActiveTime, forKey: .lastActiveTime)
    }
}

// MARK: - SquareStatus Codable Extension
extension SquareStatus: Codable {
    var rawValue: String {
        switch self {
        case .empty: return "empty"
        case .x: return "x"
        case .o: return "o"
        case .xw: return "xw"
        case .ow: return "ow"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "empty": self = .empty
        case "x": self = .x
        case "o": self = .o
        case "xw": self = .xw
        case "ow": self = .ow
        default: return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SquareStatus(rawValue: rawValue) ?? .empty
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

// MARK: - Move History
struct GameMove: Codable, Identifiable {
    let id: String
    let playerId: String
    let index: Int
    let symbol: SquareStatus
    let timestamp: Date
    let moveNumber: Int
    
    init(id: String = UUID().uuidString,
         playerId: String,
         index: Int,
         symbol: SquareStatus,
         timestamp: Date = Date(),
         moveNumber: Int) {
        self.id = id
        self.playerId = playerId
        self.index = index
        self.symbol = symbol
        self.timestamp = timestamp
        self.moveNumber = moveNumber
    }
}

// MARK: - Game Settings
struct MultiplayerGameSettings: Codable {
    let boardSize: Int // 3-9
    let winCondition: Int // ketma-ket kerak bo'lgan belgilar soni
    let totalTimeLimit: TimeInterval? // umumiy vaqt limiti (sekundlarda)
    let turnTimeLimit: TimeInterval? // har bir harakat uchun vaqt
    let allowSpectators: Bool
    let isRanked: Bool
    let allowChat: Bool
    
    init(boardSize: Int = 3,
         winCondition: Int? = nil,
         totalTimeLimit: TimeInterval? = nil,
         turnTimeLimit: TimeInterval? = 30,
         allowSpectators: Bool = false,
         isRanked: Bool = false,
         allowChat: Bool = true) {
        self.boardSize = max(3, min(9, boardSize))
        self.winCondition = winCondition ?? self.boardSize
        self.totalTimeLimit = totalTimeLimit
        self.turnTimeLimit = turnTimeLimit
        self.allowSpectators = allowSpectators
        self.isRanked = isRanked
        self.allowChat = allowChat
    }
}

// MARK: - Game Status
enum MultiplayerGameStatus: String, Codable {
    case waiting = "waiting"           // O'yinchi kutmoqda
    case ready = "ready"               // Ikkala o'yinchi tayyor
    case active = "active"             // O'yin davom etmoqda
    case paused = "paused"             // To'xtatilgan
    case finished = "finished"         // Tugagan
    case abandoned = "abandoned"       // Tashlab ketilgan
    case timeout = "timeout"           // Vaqt tugagan
}

// MARK: - Game Result
enum MultiplayerGameResult: String, Codable {
    case player1Won = "player1_won"
    case player2Won = "player2_won"
    case draw = "draw"
    case timeoutPlayer1 = "timeout_player1"
    case timeoutPlayer2 = "timeout_player2"
    case forfeitPlayer1 = "forfeit_player1"
    case forfeitPlayer2 = "forfeit_player2"
    case none = "none"
}

// MARK: - Chat Message
struct ChatMessage: Codable, Identifiable {
    let id: String
    let playerId: String
    let playerUsername: String
    let message: String
    let timestamp: Date
    let isSystemMessage: Bool
    
    init(id: String = UUID().uuidString,
         playerId: String,
         playerUsername: String,
         message: String,
         timestamp: Date = Date(),
         isSystemMessage: Bool = false) {
        self.id = id
        self.playerId = playerId
        self.playerUsername = playerUsername
        self.message = message
        self.timestamp = timestamp
        self.isSystemMessage = isSystemMessage
    }
}

// MARK: - Main Multiplayer Game
struct MultiplayerGame: Codable, Identifiable {
    let id: String
    var player1: Player
    var player2: Player?
    var settings: MultiplayerGameSettings
    var boardState: [SquareStatus]
    var currentTurn: SquareStatus
    var status: MultiplayerGameStatus
    var result: MultiplayerGameResult
    var moveHistory: [GameMove]
    var chatMessages: [ChatMessage]
    
    // Vaqt boshqaruvi
    var startTime: Date?
    var endTime: Date?
    var lastMoveTime: Date?
    var player1TimeRemaining: TimeInterval?
    var player2TimeRemaining: TimeInterval?
    var currentTurnStartTime: Date?
    
    // Qo'shimcha ma'lumotlar
    var spectatorCount: Int
    var roomCode: String?
    var isPrivate: Bool
    
    init(id: String = UUID().uuidString,
         player1: Player,
         player2: Player? = nil,
         settings: MultiplayerGameSettings = MultiplayerGameSettings()) {
        self.id = id
        self.player1 = player1
        self.player2 = player2
        self.settings = settings
        
        // Board yaratish
        let totalSquares = settings.boardSize * settings.boardSize
        self.boardState = Array(repeating: .empty, count: totalSquares)
        
        self.currentTurn = .x
        self.status = player2 == nil ? .waiting : .ready
        self.result = .none
        self.moveHistory = []
        self.chatMessages = []
        
        self.startTime = nil
        self.endTime = nil
        self.lastMoveTime = nil
        self.player1TimeRemaining = settings.totalTimeLimit
        self.player2TimeRemaining = settings.totalTimeLimit
        self.currentTurnStartTime = nil
        
        self.spectatorCount = 0
        self.roomCode = nil
        self.isPrivate = false
    }
    
    // MARK: - Game Logic Integration
    
    /// Board obyektini olish
    func getBoard() -> Board {
        return Board(position: boardState, turn: currentTurn)
    }
    
    /// Harakat qilish
    mutating func makeMove(playerId: String, index: Int) -> Bool {
        guard status == .active else { return false }
        guard boardState.indices.contains(index) else { return false }
        guard boardState[index] == .empty else { return false }
        
        // To'g'ri o'yinchini tekshirish
        let currentPlayer = (currentTurn == player1.symbol) ? player1 : player2
        guard currentPlayer?.id == playerId else { return false }
        
        // Harakatni amalga oshirish
        boardState[index] = currentTurn
        let move = GameMove(playerId: playerId,
                           index: index,
                           symbol: currentTurn,
                           moveNumber: moveHistory.count + 1)
        moveHistory.append(move)
        lastMoveTime = Date()
        
        // Vaqtni yangilash
        updateTimeAfterMove()
        
        // G'olibni tekshirish
        let board = getBoard()
        if board.isWin {
            status = .finished
            result = currentTurn == player1.symbol ? .player1Won : .player2Won
            endTime = Date()
            
            // Skor yangilash
            if currentTurn == player1.symbol {
                player1.score += 1
            } else if let _ = player2 {
                player2?.score += 1
            }
            return true
        }
        
        // Durang tekshirish
        if board.isDraw {
            status = .finished
            result = .draw
            endTime = Date()
            return true
        }
        
        // Navbatni almashtirish
        currentTurn = (currentTurn == .x) ? .o : .x
        currentTurnStartTime = Date()
        
        return true
    }
    
    /// Vaqtni yangilash
    private mutating func updateTimeAfterMove() {
        guard settings.totalTimeLimit != nil,
              let turnStart = currentTurnStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(turnStart)
        
        if currentTurn == player1.symbol {
            if let remaining = player1TimeRemaining {
                player1TimeRemaining = max(0, remaining - elapsed)
            }
        } else {
            if let remaining = player2TimeRemaining {
                player2TimeRemaining = max(0, remaining - elapsed)
            }
        }
    }
    
    /// Chat xabar qo'shish
    mutating func addChatMessage(playerId: String, message: String) {
        guard settings.allowChat else { return }
        
        let playerUsername: String
        if playerId == player1.id {
            playerUsername = player1.username
        } else if let p2 = player2, playerId == p2.id {
            playerUsername = p2.username
        } else {
            return
        }
        
        let chatMsg = ChatMessage(playerId: playerId,
                                 playerUsername: playerUsername,
                                 message: message)
        chatMessages.append(chatMsg)
    }
    
    /// System xabar qo'shish
    mutating func addSystemMessage(_ message: String) {
        let systemMsg = ChatMessage(playerId: "system",
                                   playerUsername: "System",
                                   message: message,
                                   isSystemMessage: true)
        chatMessages.append(systemMsg)
    }
    
    /// O'yinni boshlash
    mutating func startGame() {
        guard status == .ready, player2 != nil else { return }
        status = .active
        startTime = Date()
        currentTurnStartTime = Date()
        addSystemMessage("Game started!")
    }
    
    /// O'yinni tark etish
    mutating func forfeit(playerId: String) {
        status = .finished
        if playerId == player1.id {
            result = .forfeitPlayer1
            player2?.score += 1
        } else {
            result = .forfeitPlayer2
            player1.score += 1
        }
        endTime = Date()
    }
    
    /// Vaqt tugashi
    mutating func handleTimeout(playerId: String) {
        status = .finished
        if playerId == player1.id {
            result = .timeoutPlayer1
            player2?.score += 1
        } else {
            result = .timeoutPlayer2
            player1.score += 1
        }
        endTime = Date()
    }
}

// MARK: - Game Room (Lobby)
struct GameRoom: Codable, Identifiable {
    let id: String
    let roomCode: String
    let hostId: String
    var settings: MultiplayerGameSettings
    var isPrivate: Bool
    var createdAt: Date
    var playersInRoom: [Player]
    var maxPlayers: Int
    
    init(id: String = UUID().uuidString,
         roomCode: String = generateRoomCode(),
         hostId: String,
         settings: MultiplayerGameSettings = MultiplayerGameSettings(),
         isPrivate: Bool = false) {
        self.id = id
        self.roomCode = roomCode
        self.hostId = hostId
        self.settings = settings
        self.isPrivate = isPrivate
        self.createdAt = Date()
        self.playersInRoom = []
        self.maxPlayers = 2
    }
    
    static func generateRoomCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}

// MARK: - API Request/Response Models

struct CreateGameRequest: Codable {
    let playerId: String
    let playerUsername: String
    let settings: MultiplayerGameSettings
    let isPrivate: Bool
    let roomCode: String?
}

struct JoinGameRequest: Codable {
    let playerId: String
    let playerUsername: String
    let gameId: String?
    let roomCode: String?
}

struct MakeMoveRequest: Codable {
    let gameId: String
    let playerId: String
    let index: Int
}

struct GameResponse: Codable {
    let success: Bool
    let message: String?
    let game: MultiplayerGame?
    let error: String?
}

struct GameListResponse: Codable {
    let success: Bool
    let games: [GameListItem]?
    let error: String?
}

struct GameListItem: Codable, Identifiable {
    let id: String
    let player1Id: String
    let player1Username: String
    let player2Username: String?
    let status: MultiplayerGameStatus
    let boardSize: Int
    let roomCode: String?
    let isPrivate: Bool
    let spectatorCount: Int
    let createdAt: Date
}

// MARK: - WebSocket Messages

enum WebSocketMessageType: String, Codable {
    case gameUpdate = "game_update"
    case moveUpdate = "move_update"
    case chatMessage = "chat_message"
    case playerJoined = "player_joined"
    case playerLeft = "player_left"
    case gameStarted = "game_started"
    case gameEnded = "game_ended"
    case timeUpdate = "time_update"
    case error = "error"
}

struct WebSocketMessage: Codable {
    let type: WebSocketMessageType
    let gameId: String
    let data: Data
    let timestamp: Date
    
    init(type: WebSocketMessageType, gameId: String, data: Codable) {
        self.type = type
        self.gameId = gameId
        self.timestamp = Date()
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.data = (try? encoder.encode(data)) ?? Data()
    }
}

// MARK: - JSON Encoding/Decoding Extensions

extension MultiplayerGame {
    func toJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func fromJSON(_ json: String) -> MultiplayerGame? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let data = json.data(using: .utf8),
              let game = try? decoder.decode(MultiplayerGame.self, from: data) else {
            return nil
        }
        return game
    }
}

extension Player {
    func toJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Convenience Extensions

extension MultiplayerGame {
    var isWaitingForPlayer: Bool {
        status == .waiting && player2 == nil
    }
    
    var canStart: Bool {
        player2 != nil && status == .ready
    }
    
    var currentPlayerName: String {
        let player = currentTurn == player1.symbol ? player1 : player2
        return player?.username ?? "Unknown"
    }
    
    var winner: Player? {
        guard status == .finished else { return nil }
        
        switch result {
        case .player1Won, .timeoutPlayer2, .forfeitPlayer2:
            return player1
        case .player2Won, .timeoutPlayer1, .forfeitPlayer1:
            return player2
        default:
            return nil
        }
    }
}

