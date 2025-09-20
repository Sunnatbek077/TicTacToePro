//
//  GameViewModel.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import Foundation
import SwiftUI
import Combine

class ViewModel: ObservableObject {
    @Published var gameOver: Bool = false
    @Published var winner: SquareStatus = .empty
}

/// UI bilan ishlovchi ViewModel: taxta holati, navbat, o‘yin yakuni.
/// Core (Board, AI) bilan ishlaydi, lekin UI komponentlariga bevosita bog‘lanmaydi.
@MainActor
class GameViewModel: ObservableObject {
    @Published var squares = [Square]()
    // playerToMove: current mark to move (.x or .o)
    @Published var playerToMove: SquareStatus = .x
    
    // UI uchun holat
    @Published var gameOver: Bool = false
    @Published var winner: SquareStatus = .empty
    
    // Qaysi belgi AI tomonidan o‘ynaladi (.x yoki .o), faqat AI rejimida ishlatiladi
    var aiPlays: SquareStatus = .o
    
    init() {
        for _ in 0..<9 {
            squares.append(Square(status: .empty))
        }
    }
    
    // Reset Game
    func resetGame() {
        for i in 0..<9 {
            squares[i].squareStatus = .empty
        }
        playerToMove = .x
        gameOver = false
        winner = .empty
    }
    
    // Board state
    var boardArray: [SquareStatus] {
        squares.map { $0.squareStatus }
    }
    
    // Make Move
    // gameTypeIsPVP: false = AI mode, true = PvP
    @discardableResult
    func makeMove(index: Int, gameTypeIsPVP: Bool, difficulty: AIDifficulty = .hard) -> Bool {
        guard index >= 0 && index < squares.count else { return false }
        guard squares[index].squareStatus == .empty else { return false }
        guard gameOver == false else { return false }
        
        let player: SquareStatus = playerToMove
        squares[index].squareStatus = player
        
        // Check game state immediately after move
        evaluateGameOver()
        if gameOver { return true }
        
        // Toggle turn
        playerToMove = (playerToMove == .x) ? .o : .x
        
        // Let AI move if it's its turn
        if !gameTypeIsPVP, playerToMove == aiPlays {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task { await self.moveAIAsync(difficulty: difficulty, gameTypeIsPVP: gameTypeIsPVP) }
            }
        }
        
        return true
    }
    
    // AI Move (async, background compute)
    private func moveAI(difficulty: AIDifficulty, gameTypeIsPVP: Bool) {
        let board = Board(position: boardArray, turn: aiPlays)
        let answer = board.bestMove(difficulty: difficulty)
        guard answer >= 0 else { return }
        _ = makeMove(index: answer, gameTypeIsPVP: gameTypeIsPVP, difficulty: difficulty)
    }
    
    private func moveAIAsync(difficulty: AIDifficulty, gameTypeIsPVP: Bool) async {
        let currentBoard = Board(position: boardArray, turn: aiPlays)
        let answer: Int = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let best = currentBoard.bestMove(difficulty: difficulty)
                continuation.resume(returning: best)
            }
        }
        guard answer >= 0 else { return }
        _ = makeMove(index: answer, gameTypeIsPVP: gameTypeIsPVP, difficulty: difficulty)
    }
    
    // Winner Check using Board.winningLine
    private func evaluateGameOver() {
        let board = Board(position: boardArray, turn: playerToMove)
        
        if let (line, who) = board.winningLine {
            colorize(who, row: line)
            winner = who
            gameOver = true
            return
        }
        
        if board.isDraw {
            gameOver = true
            winner = .empty
        }
    }
    
    // Highlight Winner
    private func colorize(_ who: SquareStatus, row: [Int]) {
        withAnimation {
            if who == .x {
                squares[row[0]].squareStatus = .xw
                squares[row[1]].squareStatus = .xw
                squares[row[2]].squareStatus = .xw
            } else if who == .o {
                squares[row[0]].squareStatus = .ow
                squares[row[1]].squareStatus = .ow
                squares[row[2]].squareStatus = .ow
            }
        }
    }
}
