//
//  GameLogicModel.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import Foundation

// MARK: - Skeleton map of the Board
/// Represents the TicTacToe board and contains the main game logic (UI-agnostic)
struct Board {
    /// Current state of each square on the board
    let pos: [SquareStatus]
    /// Current player's turn
    let turn: SquareStatus
    /// Opponent of the current turn (computed)
    var opposite: SquareStatus { turn == .x ? .o : .x }
    
    // MARK: - Initializer
    /// Initializes a new board with default or provided values
    init(
        position: [SquareStatus] = Array(repeating: .empty, count: 9),
        turn: SquareStatus = .x
    ) {
        self.pos = position
        self.turn = turn
    }
    
    // MARK: - Make a move
    /// Returns a new board after making a move at the specified location (unsafe, assumes valid move)
    func move(_ location: Int) -> Board {
        var tempPosition = pos
        tempPosition[location] = turn
        return Board(position: tempPosition, turn: opposite)
    }
    
    /// Safe move helper: returns nil if index invalid or cell not empty
    func safeMove(_ location: Int) -> Board? {
        guard pos.indices.contains(location), pos[location] == .empty else { return nil }
        return move(location)
    }
    
    // MARK: - Legal Moves
    /// Returns all indexes that are still empty and valid to play
    var legalMoves: [Int] {
        return pos.indices.filter { pos[$0] == .empty }
    }
    
    // MARK: - Winning Combinations
    /// Returns all possible winning combinations (rows, columns, diagonals)
    private var winningCombos: [[Int]] {
        [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
            [0, 4, 8], [2, 4, 6]             // diagonals
        ]
    }
    
    /// Returns the winning line (indices) and winner mark if any
    var winningLine: (indices: [Int], winner: SquareStatus)? {
        for combo in winningCombos {
            let a = combo[0], b = combo[1], c = combo[2]
            if pos[a] == pos[b], pos[b] == pos[c], pos[a] != .empty {
                return (combo, pos[a])
            }
        }
        return nil
    }
    
    /// Checks if the current board state is a win
    var isWin: Bool {
        winningLine != nil
    }
    
    /// Checks if the game is a draw (no empty squares and no winner)
    var isDraw: Bool {
        return !isWin && legalMoves.isEmpty
    }
    
    // MARK: - Minimax Algorithm
    /// Recursive minimax algorithm to evaluate board positions
    func minimax(_ board: Board, depth: Int, alpha: inout Int, beta: inout Int, maximizing: Bool, originalPlayer: SquareStatus) -> Int {
        if board.isWin && originalPlayer == board.opposite { return 10 - depth }
        else if board.isWin && originalPlayer != board.opposite { return depth - 10 }
        else if board.isDraw { return 0 }
        
        if maximizing {
            var maxEval = Int.min
            for move in board.legalMoves {
                var a = alpha, b = beta
                let eval = minimax(board.move(move), depth: depth + 1, alpha: &a, beta: &b, maximizing: false, originalPlayer: originalPlayer)
                maxEval = max(maxEval, eval)
                alpha = max(alpha, eval)
                if beta <= alpha { break }
            }
            return maxEval
        } else {
            var minEval = Int.max
            for move in board.legalMoves {
                var a = alpha, b = beta
                let eval = minimax(board.move(move), depth: depth + 1, alpha: &a, beta: &b, maximizing: true, originalPlayer: originalPlayer)
                minEval = min(minEval, eval)
                beta = min(beta, eval)
                if beta <= alpha { break }
            }
            return minEval
        }
    }
    
    // Optional: convenience wrapper to start minimax with defaults
    private func evaluateMove(_ board: Board, maximizing: Bool, originalPlayer: SquareStatus) -> Int {
        var alpha = Int.min
        var beta = Int.max
        return minimax(board, depth: 0, alpha: &alpha, beta: &beta, maximizing: maximizing, originalPlayer: originalPlayer)
    }
    
    // MARK: - Find the Best Move for AI (Hard)
    func findBestMove(_ board: Board) -> Int? {
        var bestEval = Int.min
        var bestMove = -1
        for move in board.legalMoves {
            let childBoard = board.move(move)
            let result = evaluateMove(childBoard, maximizing: false, originalPlayer: board.turn)
            if result > bestEval {
                bestEval = result
                bestMove = move
            }
        }
        return bestMove >= 0 ? bestMove : nil
    }
}

// MARK: - AI Difficulty Enum (core)
enum AIDifficulty {
    case easy
    case medium
    case hard
}

// MARK: - Difficulty-based AI
extension Board {
    /// Returns the best move for the AI depending on the difficulty
    func bestMove(difficulty: AIDifficulty) -> Int {
        switch difficulty {
        case .easy:
            return easyMove()
        case .medium:
            return mediumMove()
        case .hard:
            return findBestMove(self) ?? easyMove()
        }
    }
    
    private func easyMove() -> Int {
        legalMoves.randomElement() ?? -1
    }
    
    private func mediumMove() -> Int {
        // Medium should feel beatable: allow some mistakes, but still take immediate wins
        // Tunable probabilities
        let blockProbability: Int = 70   // % chance to block an imminent loss
        let randomOverrideProbability: Int = 30 // % chance to just play random early
        let suboptimalHeuristicProbability: Int = 35 // % chance to pick a worse square in heuristic stage
        
        // 0️⃣ Occasionally play random right away to feel human-like
        if Int.random(in: 0..<100) < randomOverrideProbability {
            return easyMove()
        }
        
        // 1️⃣ Always take a winning move if available
        for candidate in legalMoves {
            let newBoard = self.move(candidate)
            if newBoard.isWin { return candidate }
        }
        
        // 2️⃣ Block opponent with some probability (not always)
        if Int.random(in: 0..<100) < blockProbability {
            for candidate in legalMoves {
                // simulate opponent taking this square next
                let opponentBoard = Board(position: self.pos, turn: self.opposite).move(candidate)
                if opponentBoard.isWin { return candidate }
            }
        }
        
        // 3️⃣ Heuristics with occasional suboptimal choices
        // Prefer center > corners > edges, but sometimes pick a suboptimal bucket
        let center = [4].filter { legalMoves.contains($0) }
        let corners = [0, 2, 6, 8].filter { legalMoves.contains($0) }
        let edges = [1, 3, 5, 7].filter { legalMoves.contains($0) }
        
        // Helper to pick from a bucket
        func pick(_ arr: [Int]) -> Int? { arr.randomElement() }
        
        let roll = Int.random(in: 0..<100)
        if roll < suboptimalHeuristicProbability {
            // Suboptimal branch: try edges first, then corners, then center
            if let e = pick(edges) { return e }
            if let c = pick(corners) { return c }
            if let ce = pick(center) { return ce }
        } else {
            // Normal heuristic: center > corners > edges
            if let ce = pick(center) { return ce }
            if let c = pick(corners) { return c }
            if let e = pick(edges) { return e }
        }
        
        // 4️⃣ Fallback to random
        return easyMove()
    }
}

// MARK: - Future Optimizations (skeleton only)
extension Board {
    /// Compact bitmask representation (future use)
    var bitmaskRepresentation: (xMask: Int, oMask: Int) {
        // TODO
        return (0, 0)
    }
    
    /// Transposition table (future use)
    static var transpositionTable: [Int: Int] = [:]
    
    func stateHash() -> Int {
        // TODO
        return pos.hashValue
    }
    
    /// Move ordering heuristic (future use)
    func orderedMoves() -> [Int] {
        // TODO
        return legalMoves
    }
    
    /// Heuristic evaluation for non-terminal states (future use)
    func heuristicScore(for player: SquareStatus) -> Int {
        // TODO
        return 0
    }
}

