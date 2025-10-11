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
                }
                .onChange(of: ticTacToe.gameOver) { handleGameOverChanged($1) }
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
            HStack(spacing: 4) {
                ForEach(headerReactions, id: \.self) { emoji in
                    Text(emoji)
                        .font(.title2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: headerReactions)
        }
    }
}
