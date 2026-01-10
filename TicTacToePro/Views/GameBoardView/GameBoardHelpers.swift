//
//  GameBoardHelpers.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 04/10/25.
//

import SwiftUI

extension GameBoardView {
    var currentPlayer: String { ticTacToe.playerToMove == .x ? "X" : "O" }
    var headerTitle: String { "Tic Tac Toe" }
    var headerSubtitle: String {
        if gameTypeIsPVP {
            return "\(currentPlayer)’s Move"
        } else {
            return ticTacToe.playerToMove == ticTacToe.aiPlays ? "AI is thinking..." : "Your Move"
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
    
    var isCompactHeight: Bool {
#if os(iOS)
        return vSizeClass == .compact || UIScreen.main.bounds.height <= 667
#else
        return false
#endif
    }
    
    var isSESmallScreen: Bool {
#if os(iOS)
        return isCompactHeight && hSizeClass == .compact && UIScreen.main.bounds.height <= 667 && UIScreen.main.bounds.width <= 375
#else
        return false
#endif
    }
    
    var isWide: Bool {
#if os(macOS) || os(visionOS)
        return true
#else
        return hSizeClass == .regular
#endif
    }
    
    var gameOverAlertTitle: String {
        guard ticTacToe.winner != .empty else { return TieMessages.messages.randomElement() ?? "It's a Tie! 🤝" }
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
#if os(macOS)
        return min(640, max(420, min(size.width, size.height) * 0.8))
#elseif os(visionOS)
        return min(720, max(480, min(size.width, size.height) * 0.85))
#else
        if hSizeClass == .regular {
            return min(600, max(420, min(size.width, size.height) * 0.9))
        } else {
            if isSESmallScreen {
                return min(400, max(340, min(size.width, size.height) * 0.98))
            } else if isCompactHeight {
                return min(420, max(340, min(size.width, size.height) * 0.98))
            } else {
                return min(440, max(360, min(size.width, size.height) * 0.95))
            }
        }
#endif
    }
}
