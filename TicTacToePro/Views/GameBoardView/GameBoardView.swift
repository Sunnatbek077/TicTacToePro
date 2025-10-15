//
//  GameBoardView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//  Updated with enhanced premium design on 01/10/25
//  Optimized for small 16:9 iPhones (e.g., iPhone SE 2nd/3rd gen) on 02/10/25
//  Fixed scope and range errors on 02/10/25
//  Enlarged board size for SE on 02/10/25
//

import SwiftUI
import Combine
import Foundation

struct GameBoardView: View {
    var onExit: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass
    
    @ObservedObject var viewModel: ViewModel
    @ObservedObject var ticTacToe: GameViewModel
    
    let gameTypeIsPVP: Bool
    let difficulty: AIDifficulty
    let startingPlayerIsO: Bool
    let timeLimit: TimeLimitOption?
    
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
    
    // MARK: - Header Reaction Emojis (12 holatli)
    private var headerReactions: [String] {
        // O'yin tugagan bo'lsa
        if ticTacToe.gameOver {
            if ticTacToe.winner == .empty {
                // 1. Durrang: Chalg'igan
                return ["🤷", "😐"]
            } else {
                if !gameTypeIsPVP && ticTacToe.winner == ticTacToe.aiPlays {
                    // 2. AI yutdi
                    return ["🤖", "😎"]
                } else {
                    // 3. Siz yutdingiz!
                    return ["🎉", "🏆"]
                }
            }
        }
        
        // AI o'ylayapti
        if !gameTypeIsPVP && ticTacToe.playerToMove == ticTacToe.aiPlays {
            // 4. AI o'ylayapti
            return ["🤔", "🧠"]
        }
        
        // Xavfli vaziyatlarni tekshirish
        let statuses = ticTacToe.squares.map { $0.squareStatus }
        let boardNow = Board(position: statuses, turn: ticTacToe.playerToMove)
        let canWinNow = boardNow.legalMoves.contains { boardNow.move($0).isWin }
        let opponentTurn: SquareStatus = (ticTacToe.playerToMove == .x ? .o : .x)
        let opponentBoard = Board(position: statuses, turn: opponentTurn)
        let opponentCanWinNow = opponentBoard.legalMoves.contains { opponentBoard.move($0).isWin }
        
        if canWinNow && opponentCanWinNow {
            // 5. Ikkalasi ham yutishi mumkin: Juda xavfli!
            return ["⚠️", "💀"]
        } else if canWinNow {
            // 6. Siz yutishingiz mumkin: Zo'r imkoniyat!
            return ["🔥", "💪"]
        } else if opponentCanWinNow {
            // 7. Raqib yutishi mumkin: Xavf!
            return ["😰", "☠️"]
        }
        
        // O'yin bosqichiga qarab
        let moveCount = statuses.filter { $0 != .empty }.count
        
        if moveCount == 0 {
            // 8. O'yin boshlanmagan: Tayyor
            return ["🎮", "✨"]
        } else if moveCount <= 2 {
            // 9. Boshlanish: Tinch
            return ["😊", "👍"]
        } else if moveCount <= 4 {
            // 10. O'rta bosqich: Qiziq
            return ["🎯", "😏"]
        } else if moveCount <= 6 {
            // 11. Murakkab vaziyat: Diqqat
            return ["👀", "🤨"]
        } else {
            // 12. Oxirgi bosqich: Tarang
            return ["😬", "⚡"]
        }
    }
    
    var body: some View {
        ZStack {
            premiumBackground
                .ignoresSafeArea()
            
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        animateBoardEntrance = true
                    }
                    setupGame()
                    startTimerIfNeeded()
                }
                .onChange(of: ticTacToe.gameOver) { isOver in
                    handleGameOverChanged(isOver)
                    if isOver { stopTimer() }
                }
                .onChange(of: ticTacToe.playerToMove) { _ in handlePlayerToMoveChanged() }
                .alert(Text(gameOverAlertTitle), isPresented: $ticTacToe.gameOver) {
                    Button("Play Again", action: resetForNextRound)
                    Button("Leave", action: exitToMenu)
                }
            
            if showConfetti {
                ConfettiView(isSELikeSmallScreen: isSELikeSmallScreen)
                    .transition(.opacity)
                    .zIndex(3)
            }
            
            if showTurnBanner {
                turnBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }

            if hasTimeLimit {
                            VStack(spacing: 8) {
                                // Container
                                VStack(spacing: isSELikeSmallScreen ? 6 : 8) {
                                    // Progress bar
                                    GeometryReader { geo in
                                        let totalWidth = geo.size.width
                                        let fillWidth = max(0, min(totalWidth, totalWidth * timeProgress))
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: isSELikeSmallScreen ? 4 : 6, style: .continuous)
                                                .fill(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.08))
                                            RoundedRectangle(cornerRadius: isSELikeSmallScreen ? 4 : 6, style: .continuous)
                                                .fill((timeLimit?.color ?? .blue).opacity(0.85))
                                                .frame(width: fillWidth)
                                        }
                                    }
                                    .frame(height: isSELikeSmallScreen ? 6 : (isCompactHeight ? 8 : 10))

                                    // Remaining time pill
                                    HStack(spacing: isSELikeSmallScreen ? 4 : 6) {
                                        Image(systemName: "timer")
                                            .font((isSELikeSmallScreen ? .caption2 : .caption))
                                        Text(formattedRemaining)
                                            .font((isSELikeSmallScreen ? .caption2 : .caption))
                                    }
                                    .padding(.horizontal, isSELikeSmallScreen ? 8 : 10)
                                    .padding(.vertical, isSELikeSmallScreen ? 4 : 6)
                                    .background(.thinMaterial, in: Capsule())
                                    .foregroundStyle((timeLimit?.color ?? .blue))
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Time remaining")
                                    .accessibilityValue(formattedRemaining)
                                }
                                .padding(.horizontal, isSELikeSmallScreen ? 8 : 12)
                                .padding(.vertical, isSELikeSmallScreen ? 6 : 10)
                                .background(
                                    .ultraThinMaterial,
                                    in: RoundedRectangle(cornerRadius: isSELikeSmallScreen ? 10 : 14, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: isSELikeSmallScreen ? 10 : 14, style: .continuous)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: colorScheme == .dark
                                                    ? [Color.white.opacity(0.10), Color.white.opacity(0.04)]
                                                    : [Color.black.opacity(0.08), Color.black.opacity(0.03)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ), lineWidth: isSELikeSmallScreen ? 0.5 : 1
                                        )
                                )
                                .padding(.top, isSELikeSmallScreen ? 4 : 8)
                                .padding(.horizontal, isSELikeSmallScreen ? 8 : (isCompactHeight ? 12 : 16))

                                Spacer()
                            }
                            .transition(.opacity)
                            .zIndex(4)
                        }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: exitToMenu) {
                Label("Leave", systemImage: "xmark")
            }
            .accessibilityLabel("Leave")
        }
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 8) {
                if let timeLimit {
                    Text(timeLimit.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(timeLimit.color)
                        .padding(.trailing, 4)
                        .accessibilityLabel("Time limit \(timeLimit.title)")
                }
                HStack(spacing: 4) {
                    ForEach(headerReactions, id: \.self) { emoji in
                        Text(emoji)
                            .font(.title2)
                            .transition(.scale.combined(with: .opacity))
                    }
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
            // Time's up: end game as a tie for now
            stopTimer()
            endGameDueToTimeLimit()
        }
    }

    private func endGameDueToTimeLimit() {
        // Decide outcome when time runs out. For now, treat as tie.
        ticTacToe.winner = .empty
        ticTacToe.gameOver = true
    }
}
