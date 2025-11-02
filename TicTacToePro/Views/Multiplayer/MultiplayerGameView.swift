//
//  MultiplayerGameView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 12/10/25.
//

import SwiftUI
import Combine

struct MultiplayerGameView: View {
    let game: MultiplayerGame
    @ObservedObject var multiplayerVM: MultiplayerViewModel
    let onExit: () -> Void
    
    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var viewModel = ViewModel()
    
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    
    @State private var showChat = false
    @State private var chatMessage = ""
    @State private var showForfeitAlert = false
    @State private var showExitAlert = false
    @State private var showWaitingOverlay = true
    @FocusState private var chatFocused: Bool
    
    // Timer for periodic refresh
    @State private var timerCancellable: AnyCancellable?
    
    var body: some View {
        ZStack {
            // Main game board view
            mainGameBoard
                .overlay(alignment: .top) {
                    // Multiplayer overlay
                    if let game = multiplayerVM.currentGame {
                        multiplayerOverlay(game: game)
                    }
                }
                .overlay {
                    // Waiting for opponent overlay
                    if let game = multiplayerVM.currentGame, game.status == .waiting {
                        waitingForOpponentOverlay(game: game)
                    }
                }
                .overlay {
                    // Game result overlay
                    if let game = multiplayerVM.currentGame, game.status == .finished {
                        gameResultOverlay(game: game)
                    }
                }
                .overlay(alignment: .trailing) {
                    // Chat button
                    if let game = multiplayerVM.currentGame, game.settings.allowChat {
                        chatButton
                            .padding()
                    }
                }
                .sheet(isPresented: $showChat) {
                    if let game = multiplayerVM.currentGame {
                        chatView(game: game)
                    }
                }
        }
        .onAppear {
            syncGameState()
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
        .onChange(of: multiplayerVM.currentGame?.boardState) { _, _ in
            syncGameState()
        }
        .onChange(of: multiplayerVM.currentGame?.status) { _, newStatus in
            if newStatus == .active {
                showWaitingOverlay = false
            }
            // Stop timer if game is finished
            if newStatus == .finished {
                stopRefreshTimer()
            }
        }
        .alert("Leave Game?", isPresented: $showExitAlert) {
            Button("Stay", role: .cancel) { }
            Button("Leave", role: .destructive) {
                onExit()
            }
        } message: {
            Text("Are you sure you want to leave? This will count as a forfeit.")
        }
        .alert("Forfeit Game?", isPresented: $showForfeitAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Forfeit", role: .destructive) {
                Task {
                    await multiplayerVM.forfeit()
                    onExit()
                }
            }
        } message: {
            Text("Your opponent will win this game.")
        }
    }
    
    // MARK: - Main Game Board
    private var mainGameBoard: some View {
        GameBoardView(
            onExit: {
                showExitAlert = true
            },
            viewModel: viewModel,
            ticTacToe: gameViewModel,
            gameTypeIsPVP: true,
            difficulty: .easy,
            startingPlayerIsO: game.player2?.symbol == .o,
            timeLimit: timeLimitOption,
            onCellTap: { index in
                // Only allow if it's my turn and the cell is empty
                guard let currentGame = multiplayerVM.currentGame,
                      let me = multiplayerVM.currentPlayer else { return }
                let isMyTurn = me.symbol == currentGame.currentTurn
                let isCellEmpty = currentGame.boardState.indices.contains(index) && currentGame.boardState[index] == .empty
                guard isMyTurn && isCellEmpty else { return }
                Task {
                    await multiplayerVM.makeMove(index: index)
                }
            }
        )
        .overlay(alignment: .bottomLeading) {
            // Forfeit button - o'yinni yakunlash
            if let game = multiplayerVM.currentGame,
               game.status == .active {
                forfeitButton
                    .padding()
            }
        }
    }
    
    // MARK: - Yoki boshqa variant - minimal dizayn
    private var forfeitButtonMinimal: some View {
        Button {
            
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 56, height: 56)
                
                Image(systemName: "flag.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Forfeit Button
    private var forfeitButton: some View {
        Button {
            showForfeitAlert = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "flag.fill")
                    .font(.callout)
                Text("Forfeit")
                    .font(.subheadline.bold())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [.red.opacity(0.9), .orange.opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    private var timeLimitOption: TimeLimitOption {
        guard let turnTime = game.settings.turnTimeLimit else {
            return .unlimited
        }
        let minutes = Int(turnTime / 60)
        return TimeLimitOption(rawValue: minutes) ?? .tenMinutes
    }
    
    // MARK: - Multiplayer Overlay
    @ViewBuilder
    private func multiplayerOverlay(game: MultiplayerGame) -> some View {
        VStack(spacing: 8) {
            // Players info bar
            HStack(spacing: 12) {
                // Player 1
                playerInfoCompact(
                    username: game.player1.username,
                    symbol: game.player1.symbol,
                    isCurrentTurn: game.currentTurn == game.player1.symbol,
                    isYou: multiplayerVM.currentPlayer?.id == game.player1.id
                )
                
                // VS
                Text("VS")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                // Player 2
                if let player2 = game.player2 {
                    playerInfoCompact(
                        username: player2.username,
                        symbol: player2.symbol,
                        isCurrentTurn: game.currentTurn == player2.symbol,
                        isYou: multiplayerVM.currentPlayer?.id == player2.id
                    )
                } else {
                    Text("Waiting...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.8))
                        )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Player Info Compact
    @ViewBuilder
    private func playerInfoCompact(
        username: String,
        symbol: SquareStatus,
        isCurrentTurn: Bool,
        isYou: Bool
    ) -> some View {
        let backgroundColor: Color = {
            if isCurrentTurn {
                return colorScheme == .dark ? Color.green.opacity(0.2) : Color.green.opacity(0.15)
            } else {
                return colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.8)
            }
        }()
        
        let strokeColor: Color = isCurrentTurn ? Color.green.opacity(0.5) : Color.clear
        
        HStack(spacing: 6) {
            // Turn indicator
            Circle()
                .fill(isCurrentTurn ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
            
            // Symbol
            Text(symbol == .x ? "X" : "O")
                .font(.caption.bold())
                .foregroundColor(symbol == .x ? .blue : .red)
            
            // Username
            Text(isYou ? "You" : username)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(backgroundColor))
        .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
    }
    
    // MARK: - Waiting Overlay
    @ViewBuilder
    private func waitingForOpponentOverlay(game: MultiplayerGame) -> some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Loading animation
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                VStack(spacing: 12) {
                    Text("Waiting for opponent...")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    if let roomCode = game.roomCode {
                        VStack(spacing: 8) {
                            Text("Room Code")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack {
                                Text(roomCode)
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                Button {
                                    UIPasteboard.general.string = roomCode
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                    }
                    
                    Text("Share this code with your friend")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Cancel button
                Button {
                    onExit()
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.8))
                        )
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .padding()
        }
    }
    
    // MARK: - Game Result Overlay
    @ViewBuilder
    private func gameResultOverlay(game: MultiplayerGame) -> some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Result icon
                resultIcon(for: game.result)
                    .font(.system(size: 80))
                
                // Result text
                VStack(spacing: 8) {
                    Text(resultTitle(for: game.result))
                        .font(.title.bold())
                        .foregroundColor(.white)
                    
                    Text(resultMessage(for: game, result: game.result))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        // Request rematch (TODO: implement)
                    } label: {
                        Text("Rematch")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.pink, .purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Button {
                        onExit()
                    } label: {
                        Text("Exit")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.3))
                            )
                    }
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .padding()
        }
    }
    
    // MARK: - Chat Button
    private var chatButton: some View {
        Button {
            showChat.toggle()
        } label: {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 56, height: 56)
                
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Unread indicator
                if let game = multiplayerVM.currentGame,
                   !game.chatMessages.isEmpty {
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                        .offset(x: 18, y: -18)
                }
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Chat View
    @ViewBuilder
    private func chatView(game: MultiplayerGame) -> some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(game.chatMessages) { message in
                            chatMessageView(message: message)
                        }
                    }
                    .padding()
                }
                
                // Input
                HStack(spacing: 12) {
                    TextField("Type message...", text: $chatMessage)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95))
                        )
                        .focused($chatFocused)
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(chatMessage.isEmpty ? Color.gray : Color.blue)
                            )
                    }
                    .disabled(chatMessage.isEmpty)
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        showChat = false
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showForfeitAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "flag.fill")
                            Text("Finish game")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func chatMessageView(message: ChatMessage) -> some View {
        let isMyMessage = message.playerId == multiplayerVM.currentPlayer?.id
        let alignment: Alignment = isMyMessage ? .trailing : .leading
        
        let backgroundColor: Color = {
            if message.isSystemMessage {
                return Color.yellow.opacity(0.2)
            } else if isMyMessage {
                return Color.blue
            } else {
                return Color.gray.opacity(0.2)
            }
        }()
        
        let textColor: Color = {
            if message.isSystemMessage {
                return .primary
            } else if isMyMessage {
                return .white
            } else {
                return .primary
            }
        }()
        
        HStack {
            if isMyMessage {
                Spacer()
            }
            
            VStack(alignment: isMyMessage ? .trailing : .leading, spacing: 4) {
                if !message.isSystemMessage {
                    Text(message.playerUsername)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(message.message)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 12).fill(backgroundColor))
                    .foregroundColor(textColor)
            }
            
            if !isMyMessage && !message.isSystemMessage {
                Spacer()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func syncGameState() {
        guard let game = multiplayerVM.currentGame else { return }
        
        // Sync board state
        gameViewModel.setBoardSize(game.settings.boardSize)
        for (index, status) in game.boardState.enumerated() {
            if gameViewModel.squares.indices.contains(index) {
                gameViewModel.squares[index].squareStatus = status
            }
        }
        
        // Sync turn
        gameViewModel.playerToMove = game.currentTurn
        
        // Check if it's local player's turn
        let isMyTurn = multiplayerVM.currentPlayer?.symbol == game.currentTurn
        
        // Sync game over state
        if game.status == .finished {
            gameViewModel.gameOver = true
            gameViewModel.winner = game.result == .draw ? .empty : game.currentTurn
        }
    }
    
    private func sendMessage() {
        guard !chatMessage.isEmpty else { return }
        multiplayerVM.sendChatMessage(chatMessage)
        chatMessage = ""
    }
    
    // MARK: - Timer Functions
    
    /// Start timer to refresh game every 5 seconds
    private func startRefreshTimer() {
        stopRefreshTimer() // Stop any existing timer
        
        // Only start timer if game is not finished
        guard let game = multiplayerVM.currentGame,
              game.status != .finished else { return }
        
        // Create, connect and subscribe to the timer
        timerCancellable = Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak multiplayerVM] _ in
                guard let multiplayerVM = multiplayerVM else { return }
                Task { @MainActor in
                    await multiplayerVM.refreshCurrentGame()
                }
            }
    }
    
    /// Stop the refresh timer
    private func stopRefreshTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func resultIcon(for result: MultiplayerGameResult) -> some View {
        let iconData = getResultIconData(for: result)
        
        return Image(systemName: iconData.icon)
            .foregroundColor(iconData.color)
    }
    
    private func getResultIconData(for result: MultiplayerGameResult) -> (icon: String, color: Color) {
        switch result {
        case .player1Won, .player2Won:
            return ("trophy.fill", .yellow)
        case .draw:
            return ("equal.circle.fill", .gray)
        case .timeoutPlayer1, .timeoutPlayer2:
            return ("clock.fill", .orange)
        case .forfeitPlayer1, .forfeitPlayer2:
            return ("flag.fill", .red)
        case .none:
            return ("questionmark.circle.fill", .gray)
        }
    }
    
    private func resultTitle(for result: MultiplayerGameResult) -> String {
        guard let game = multiplayerVM.currentGame,
              let currentPlayer = multiplayerVM.currentPlayer else {
            return "Game Over"
        }
        
        let didWin = (result == .player1Won && currentPlayer.id == game.player1.id) ||
                     (result == .player2Won && currentPlayer.id == game.player2?.id)
        
        switch result {
        case .player1Won, .player2Won:
            return didWin ? "Victory!" : "Defeat"
        case .draw:
            return "Draw!"
        case .timeoutPlayer1, .timeoutPlayer2:
            return "Time's Up!"
        case .forfeitPlayer1, .forfeitPlayer2:
            return "Forfeit"
        case .none:
            return "Game Over"
        }
    }
    
    private func resultMessage(for game: MultiplayerGame, result: MultiplayerGameResult) -> String {
        guard let currentPlayer = multiplayerVM.currentPlayer else {
            return ""
        }
        
        let isPlayer1 = currentPlayer.id == game.player1.id
        let isPlayer2 = currentPlayer.id == game.player2?.id
        
        switch result {
        case .player1Won, .player2Won:
            let didWin = (result == .player1Won && isPlayer1) || (result == .player2Won && isPlayer2)
            return didWin ? "Congratulations! You won the game!" : "Better luck next time!"
            
        case .draw:
            return "Nobody wins this time"
            
        case .timeoutPlayer1, .timeoutPlayer2:
            let timedOut = (result == .timeoutPlayer1 && isPlayer1) || (result == .timeoutPlayer2 && isPlayer2)
            return timedOut ? "You ran out of time" : "Opponent ran out of time"
            
        case .forfeitPlayer1, .forfeitPlayer2:
            let forfeited = (result == .forfeitPlayer1 && isPlayer1) || (result == .forfeitPlayer2 && isPlayer2)
            return forfeited ? "You forfeited the game" : "Opponent forfeited"
            
        case .none:
            return ""
        }
    }
}
