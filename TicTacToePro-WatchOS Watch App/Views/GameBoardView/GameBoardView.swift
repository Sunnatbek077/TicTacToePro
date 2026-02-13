//
//  GameBoardView.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 20/09/25
//

import SwiftUI
import Combine
import Foundation

struct GameBoardView: View {
    var onExit: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var viewModel: ViewModel
    @ObservedObject var ticTacToe: GameViewModel
    
    let gameTypeIsPVP: Bool
    let difficulty: AIDifficulty
    let startingPlayerIsO: Bool
    let timeLimit: TimeLimitOption?
    var onCellTap: ((Int) -> Void)? = nil
    
    // Local (session-only) scoreboard
    @State var xWins: Int = 0
    @State var oWins: Int = 0
    @State var ties: Int = 0
    
    // Local transient states
    @State var vibro: Bool = false
    @State var showTurnBanner: Bool = false
    @State var showConfetti: Bool = false
    @State var aiThinking: Bool = false
    @State var animateWinningGlow: Bool = false
    @State var recentlyPlacedIndex: Int? = nil
    @State var animateBoardEntrance: Bool = false

    // Time limit state
    @State private var totalSeconds: Int = 0
    @State private var remainingSeconds: Int = 0
    @State private var timerCancellable: AnyCancellable? = nil

    private var hasTimeLimit: Bool {
        if let timeLimit, timeLimit.rawValue > 0 { return true }
        return false
    }

    private var timeProgress: Double {
        guard hasTimeLimit, totalSeconds > 0 else { return 1.0 }
        return max(0.0, min(1.0, Double(remainingSeconds) / Double(totalSeconds)))
    }

    private var formattedRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Header Reaction Emojis
    private var headerReactions: [String] {
        if ticTacToe.gameOver {
            if ticTacToe.winner == .empty {
                return ["🤷", "😐"]
            } else {
                if !gameTypeIsPVP && ticTacToe.winner == ticTacToe.aiPlays {
                    return ["🤖", "😎"]
                } else {
                    return ["🎉", "🏆"]
                }
            }
        }
        
        if !gameTypeIsPVP && ticTacToe.playerToMove == ticTacToe.aiPlays {
            return ["🤔", "🧠"]
        }
        
        let statuses = ticTacToe.squares.map { $0.squareStatus }
        let boardNow = Board(position: statuses, turn: ticTacToe.playerToMove)
        let canWinNow = boardNow.legalMoves.contains { boardNow.move($0).isWin }
        let opponentTurn: SquareStatus = (ticTacToe.playerToMove == .x ? .o : .x)
        let opponentBoard = Board(position: statuses, turn: opponentTurn)
        let opponentCanWinNow = opponentBoard.legalMoves.contains { opponentBoard.move($0).isWin }
        
        if canWinNow && opponentCanWinNow {
            return ["⚠️", "💀"]
        } else if canWinNow {
            return ["🔥", "💪"]
        } else if opponentCanWinNow {
            return ["😰", "☠️"]
        }
        
        let moveCount = statuses.filter { $0 != .empty }.count
        
        if moveCount == 0 {
            return ["🎮", "✨"]
        } else if moveCount <= 2 {
            return ["😊", "👍"]
        } else if moveCount <= 4 {
            return ["🎯", "😀"]
        } else if moveCount <= 6 {
            return ["👀", "🤨"]
        } else {
            return ["😬", "⚡"]
        }
    }
    
    var body: some View {
        ZStack {
            premiumBackground
                .ignoresSafeArea()
            
            content
                .toolbar { toolbarContent }
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        animateBoardEntrance = true
                    }
                    setupGame()
                    startTimerIfNeeded()
                }
                .onChange(of: ticTacToe.gameOver) {
                    handleGameOverChanged(ticTacToe.gameOver)
                    if ticTacToe.gameOver { stopTimer() }
                }
                .onChange(of: ticTacToe.playerToMove) {
                    handlePlayerToMoveChanged()
                }
                .alert(Text(gameOverAlertTitle), isPresented: $ticTacToe.gameOver) {
                    Button("Play Again", action: resetForNextRound)
                    Button("Leave", action: exitToMenu)
                }
            
            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
                    .zIndex(3)
            }
            
            if showTurnBanner {
                turnBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: exitToMenu) {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .accessibilityLabel("Leave")
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 4) {
                if let timeLimit {
                    Text(timeLimit.emoji)
                        .font(.caption2)
                }
                ForEach(headerReactions, id: \.self) { emoji in
                    Text(emoji)
                        .font(.body)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: headerReactions)
        }
    }

    // MARK: - Time Limit Handling
    private func startTimerIfNeeded() {
        guard hasTimeLimit, let timeLimit else { return }
        totalSeconds = timeLimit.rawValue * 60
        remainingSeconds = totalSeconds
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                tick()
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func tick() {
        guard hasTimeLimit, remainingSeconds > 0, !ticTacToe.gameOver else {
            stopTimer()
            return
        }
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            stopTimer()
            endGameDueToTimeLimit()
        }
    }

    private func endGameDueToTimeLimit() {
        ticTacToe.winner = .empty
        ticTacToe.gameOver = true
    }
}
