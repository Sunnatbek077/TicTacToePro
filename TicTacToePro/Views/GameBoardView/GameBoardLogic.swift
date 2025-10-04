//
//  GameBoardLogic.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 04/10/25.
//

import SwiftUI

extension GameBoardView {
    func setupGame() {
        if ticTacToe.squares.allSatisfy({ $0.squareStatus == .empty }) {
            ticTacToe.playerToMove = startingPlayerIsO ? .o : .x
            performInitialAIMoveIfNeeded()
            bannerShowTemporarily()
        }
    }
    
    func makeMove(at index: Int) {
        guard ticTacToe.squares.indices.contains(index) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            _ = ticTacToe.makeMove(index: index, gameTypeIsPVP: gameTypeIsPVP, difficulty: difficulty)
        }
        HapticManager.trigger(style: .soft)
        bannerShowTemporarily()
    }
    
    func resetForNextRound() {
        resetGameState()
        performInitialAIMoveIfNeeded()
        bannerShowTemporarily()
    }
    
    func exitToMenu() {
        resetGameState()
        onExit()
    }
    
    func resetGameState() {
        ticTacToe.resetGame()
        ticTacToe.playerToMove = startingPlayerIsO ? .o : .x
        viewModel.gameOver = false
        viewModel.winner = .empty
        showConfetti = false
        aiThinking = false
        animateWinningGlow = false
        recentlyPlacedIndex = nil
    }
    
    func performInitialAIMoveIfNeeded() {
        guard !gameTypeIsPVP,
              ticTacToe.aiPlays == .x,
              ticTacToe.playerToMove == .x,
              ticTacToe.squares.allSatisfy({ $0.squareStatus == .empty })
        else { return }
        
        aiThinking = true
        let delay: TimeInterval = isSELikeSmallScreen ? 0.3 : 0.45
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let boardMoves = ticTacToe.boardArray
            let testBoard = Board(position: boardMoves, turn: .x)
            let answer = testBoard.bestMove(difficulty: difficulty)
            if answer >= 0 {
                _ = ticTacToe.makeMove(index: answer, gameTypeIsPVP: false, difficulty: difficulty)
                recentlyPlacedIndex = answer
            }
            withAnimation { aiThinking = false }
        }
    }
    
    func handleGameOverChanged(_ isOver: Bool) {
        guard isOver else { return }
        if ticTacToe.winner == .x {
            xWins += 1
            HapticManager.trigger(style: .heavy)
        } else if ticTacToe.winner == .o {
            oWins += 1
            HapticManager.trigger(style: .heavy)
        } else {
            ties += 1
            HapticManager.trigger(style: .medium)
        }
        
        if ticTacToe.winner != .empty {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showConfetti = true
                animateWinningGlow = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut) { showConfetti = false }
            }
        }
        
        bannerShowTemporarily()
    }
    
    func handlePlayerToMoveChanged() {
        if !gameTypeIsPVP && ticTacToe.playerToMove == ticTacToe.aiPlays {
            withAnimation(.spring()) { aiThinking = true }
        } else {
            withAnimation(.spring()) { aiThinking = false }
        }
    }
    
    func bannerShowTemporarily() {
        let duration: TimeInterval = isSELikeSmallScreen ? 1.0 : 1.4
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showTurnBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut) { showTurnBanner = false }
        }
    }
    
    func detectWinningIndices() -> [Int] {
        let statuses = ticTacToe.squares.map { $0.squareStatus }
        func allEqualAndNotEmpty(_ idxs: [Int]) -> Bool {
            guard let first = statuses[idxs[0]] as? AnyHashable else { return false }
            if "\(first)" == "\(SquareStatus.empty)" { return false }
            let base = statuses[idxs[0]]
            return idxs.allSatisfy { statuses[$0] == base }
        }
        
        let lines = [
            [0,1,2], [3,4,5], [6,7,8], // rows
            [0,3,6], [1,4,7], [2,5,8], // cols
            [0,4,8], [2,4,6]           // diags
        ]
        
        for line in lines {
            if line.allSatisfy({ $0 >= 0 && $0 < statuses.count }) {
                if allEqualAndNotEmpty(line) {
                    return line
                }
            }
        }
        return []
    }
}
