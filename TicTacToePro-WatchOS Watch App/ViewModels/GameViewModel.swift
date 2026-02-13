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

/// UI bilan ishlovchi ViewModel: taxta holati, navbat, o'yin yakuni.
/// Core (Board, AI) bilan ishlaydi, lekin UI komponentlariga bevosita bog'lanmaydi.
@MainActor
class GameViewModel: ObservableObject {
    @Published var squares: [Square] = []
    // playerToMove: current mark to move (.x or .o)
    @Published var playerToMove: SquareStatus = .x
    
    // UI uchun holat
    @Published var gameOver: Bool = false
    @Published var winner: SquareStatus = .empty
    
    // AI hesablash holati
    @Published var isAIThinking: Bool = false
    
    // Qaysi belgi AI tomonidan o'ynaladi (.x yoki .o), faqat AI rejimida ishlatiladi
    var aiPlays: SquareStatus = .o
    
    // Taxta o'lchami (3x3 default, 4x4, 5x5, va h.k. uchun)
    private(set) var boardSize: Int = 3
    
    init(boardSize: Int = 3) {
        self.boardSize = boardSize
        let totalSquares = boardSize * boardSize
        for _ in 0..<totalSquares {
            squares.append(Square(status: .empty))
        }
    }
    
    // Reset Game
    func resetGame() {
        let totalSquares = boardSize * boardSize
        squares.removeAll()
        for _ in 0..<totalSquares {
            squares.append(Square(status: .empty))
        }
        playerToMove = .x
        gameOver = false
        winner = .empty
        isAIThinking = false
    }
    
    // Taxta o'lchamini o'zgartirish
    func setBoardSize(_ size: Int) {
        boardSize = size
        resetGame()
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
        guard !isAIThinking else { return false } // AI o'ylayotganda harakat qilish mumkin emas
        
        let player: SquareStatus = playerToMove
        squares[index].squareStatus = player
        
        // Check game state immediately after move
        evaluateGameOver()
        if gameOver { return true }
        
        // Toggle turn
        playerToMove = (playerToMove == .x) ? .o : .x
        
        // Let AI move if it's its turn
        if !gameTypeIsPVP, playerToMove == aiPlays {
            // Kichik kechikish bilan AI harakatini ishga tushirish
            let delay: TimeInterval = boardSize <= 3 ? 0.5 : 0.8
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                Task { await self.moveAIAsync(difficulty: difficulty, gameTypeIsPVP: gameTypeIsPVP) }
            }
        }
        
        return true
    }
    
    // AI Move (async, background compute)
    private func moveAIAsync(difficulty: AIDifficulty, gameTypeIsPVP: Bool) async {
        isAIThinking = true
        let isHard = (difficulty == .hard)
        
        let currentBoard = Board(position: boardArray, turn: aiPlays)
        
        // Taxta o'lchamiga qarab minimax turini tanlash
        let answer: Int = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let best: Int
                
                if currentBoard.boardSize == 3 {
                    // 3x3 uchun standart minimax (tezroq)
                    best = currentBoard.bestMove(difficulty: difficulty)
                } else if isHard {
                    // 4x4+ uchun superior minimax (faqat hard rejimda)
                    best = currentBoard.findSuperiorMove(timeLimit: 5.0) ?? currentBoard.bestMove(difficulty: .medium)
                } else {
                    // Easy/Medium rejimlar uchun oddiy strategiya
                    best = currentBoard.bestMove(difficulty: difficulty)
                }
                
                continuation.resume(returning: best)
            }
        }
        
        isAIThinking = false
        
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
            let winningMark: SquareStatus = (who == .x) ? .xw : .ow
            for index in row {
                if squares.indices.contains(index) {
                    squares[index].squareStatus = winningMark
                }
            }
        }
    }
    
    // MARK: - AI Difficulty Control
    
    /// AI qiyinlik darajasini o'zgartirish
    func setDifficulty(_ difficulty: AIDifficulty) {
        // Bu funksiya UI dan qiyinlik darajasini boshqarish uchun
        // Hozircha makeMove funksiyasiga parameter sifatida uzatiladi
    }
    
    // MARK: - Debug & Statistics
    
    /// AI haqida ma'lumot (debug uchun)
    func getAIInfo() -> String {
        let board = Board(position: boardArray, turn: aiPlays)
        let legalMovesCount = board.legalMoves.count
        let boardSizeInfo = "\(boardSize)x\(boardSize)"
        
        return """
        Board: \(boardSizeInfo)
        Legal Moves: \(legalMovesCount)
        AI Thinking: \(isAIThinking ? "Yes" : "No")
        Current Turn: \(playerToMove == .x ? "X" : "O")
        """
    }
}

