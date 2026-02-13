//
//  GameBoardHelpers.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 04/10/25
//

import SwiftUI

extension GameBoardView {
    var currentPlayer: String {
        ticTacToe.playerToMove == .x ? "X" : "O"
    }
    
    var headerTitle: String {
        "Tic Tac Toe"
    }
    
    var headerSubtitle: String {
        if gameTypeIsPVP {
            return "\(currentPlayer)'s Move"
        } else {
            return ticTacToe.playerToMove == ticTacToe.aiPlays ? "AI thinking..." : "Your Move"
        }
    }
    
    var modeBadgeText: String {
        if gameTypeIsPVP {
            return "PvP"
        } else {
            let aiSide = ticTacToe.aiPlays == .x ? "X" : "O"
            let diff: String = {
                switch difficulty {
                case .easy: return "Easy"
                case .medium: return "Medium"
                case .hard: return "Hard"
                }
            }()
            return "AI: \(aiSide) • \(diff)"
        }
    }
    
    // watchOS doesn't need device size checks - all watches use similar layout
    var isWide: Bool {
        false // watchOS is always portrait/compact
    }
    
    var gameOverAlertTitle: String {
        guard ticTacToe.winner != .empty else {
            return TieMessages.messages.randomElement() ?? "It's a Tie! 🤝"
        }
        
        if gameTypeIsPVP {
            let winnerMark = ticTacToe.winner == .x ? "X" : "O"
            return "\(winnerMark) Won! 🎉"
        } else {
            if ticTacToe.winner == ticTacToe.aiPlays {
                return AIWinMessages.messages.randomElement() ?? "AI Won! 😎"
            } else {
                return AILossMessages.messages.randomElement() ?? "You Won! 🎉"
            }
        }
    }
    
    func preferredBoardSide(for size: CGSize) -> CGFloat {
        // Optimized for Apple Watch screen sizes
        let minDimension = min(size.width, size.height)
        
        // Adaptive sizing based on board size
        let scaleFactor: CGFloat = {
            switch ticTacToe.boardSize {
            case 3:
                return 0.92 // Standard 3x3 can be larger
            case 4, 5:
                return 0.90 // Larger scale for better tap targets
            case 6, 7:
                return 0.85
            default:
                return 0.80 // Large boards need more compact layout
            }
        }()
        
        return min(200, max(160, minDimension * scaleFactor))
    }
}
