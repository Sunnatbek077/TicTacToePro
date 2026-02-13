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
        let delay: TimeInterval = isSESmallScreen ? 0.3 : 0.45
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
        let duration: TimeInterval = isSESmallScreen ? 1.0 : 1.4
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showTurnBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut) { showTurnBanner = false }
        }
    }
    
    func detectWinningIndices() -> [Int] {
        let statuses = ticTacToe.squares.map { $0.squareStatus }
        let board = Board(position: statuses, turn: ticTacToe.playerToMove)
        if let (line, _) = board.winningLine {
            return line
        }
        return []
    }
}

