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
    
    @ObservedObject var ticTacToe: GameViewModel
    
    let gameTypeIsPVP: Bool
    let difficulty: AIDifficulty
    let startingPlayerIsO: Bool
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
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        animateBoardEntrance = true
                    }
                    setupGame()
                }
                .onChange(of: ticTacToe.gameOver) {
                    handleGameOverChanged(ticTacToe.gameOver)
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
    
    private func endGameDueToTimeLimit() {
        ticTacToe.winner = .empty
        ticTacToe.gameOver = true
    }
}
