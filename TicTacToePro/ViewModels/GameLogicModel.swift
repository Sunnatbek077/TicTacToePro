//
//  GameLogicModel.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import Foundation

enum SquareStatus {
    case empty
    case x
    case o
    case xw
    case ow
}

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
    
    // MARK: - Board Size Properties
    
    /// Taxta o'lchami (3x3, 4x4, 5x5, va h.k.)
    var boardSize: Int {
        Int(sqrt(Double(pos.count)))
    }
    
    /// G'alaba uchun kerakli uzunlik
    var winLength: Int {
        boardSize
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
    
    // MARK: - Winning Combinations (Dynamic)
    
    /// Har qanday o'lchamdagi taxta uchun g'alaba kombinatsiyalarini yaratadi
    func generateWinningCombos() -> [[Int]] {
        let size = boardSize
        var combos: [[Int]] = []
        
        // Qatorlar (Rows)
        for row in 0..<size {
            var combo: [Int] = []
            for col in 0..<size {
                combo.append(row * size + col)
            }
            combos.append(combo)
        }
        
        // Ustunlar (Columns)
        for col in 0..<size {
            var combo: [Int] = []
            for row in 0..<size {
                combo.append(row * size + col)
            }
            combos.append(combo)
        }
        
        // Bosh diagonal (Main diagonal)
        var mainDiag: [Int] = []
        for i in 0..<size {
            mainDiag.append(i * size + i)
        }
        combos.append(mainDiag)
        
        // Teskari diagonal (Anti-diagonal)
        var antiDiag: [Int] = []
        for i in 0..<size {
            antiDiag.append(i * size + (size - 1 - i))
        }
        combos.append(antiDiag)
        
        return combos
    }
    
    /// Returns all possible winning combinations (3x3 uchun eski versiya)
    private var winningCombos: [[Int]] {
        if boardSize == 3 {
            return [
                [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
                [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
                [0, 4, 8], [2, 4, 6]             // diagonals
            ]
        } else {
            return generateWinningCombos()
        }
    }
    
    /// Returns the winning line (indices) and winner mark if any
    var winningLine: (indices: [Int], winner: SquareStatus)? {
        let combos = generateWinningCombos()
        for combo in combos {
            let first = combo[0]
            if pos[first] == .empty { continue }
            
            let allSame = combo.allSatisfy { pos[$0] == pos[first] }
            if allSame {
                return (combo, pos[first])
            }
        }
        return nil
    }
    
    /// Checks if the current board state is a win
    var isWin: Bool {
        winningLine != nil
    }
    
    /// Checks if the game is a draw (no empty squares and no winner)
    /// Checks if the game is a draw, meaning no player can achieve a winning combination
    var isDraw: Bool {
        if isWin { return false } // If there's a winner, it's not a draw
        
        let combos = generateWinningCombos()
        let size = boardSize
        
        // Check if any winning combination is still possible for either player
        for combo in combos {
            let xCount = combo.filter { pos[$0] == .x }.count
            let oCount = combo.filter { pos[$0] == .o }.count
            let emptyCount = combo.filter { pos[$0] == .empty }.count
            
            // A combination is achievable for a player if:
            // 1. It has no opponent marks
            // 2. The player has some marks or there are enough empty squares to complete the win
            let xCanWin = oCount == 0 && (xCount > 0 || emptyCount >= winLength)
            let oCanWin = xCount == 0 && (oCount > 0 || emptyCount >= winLength)
            
            // If any combination is achievable for either player, the game is not a draw
            if xCanWin || oCanWin {
                return false
            }
        }
        
        // No achievable winning combinations for either player
        return true
    }
    
    // MARK: - Minimax Algorithm (3x3 uchun)
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
    
    // MARK: - Find the Best Move for AI (Hard - 3x3 uchun)
    func findBestMove(_ board: Board) -> Int? {
        // 3x3 uchun eski minimax
        if boardSize == 3 {
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
        } else {
            // Katta taxtalar uchun superior minimax
            return findSuperiorMove(timeLimit: 5.0)
        }
    }
    
    // MARK: - Superior minimax for 4x4, 5x5, 6x6, 7x7, 8x8, 9x9
    func superiorminimax() -> Int? {
        return findSuperiorMove(timeLimit: 5.0)
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
        let blockProbability: Int = 70
        let randomOverrideProbability: Int = 30
        let suboptimalHeuristicProbability: Int = 35
        
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
                let opponentBoard = Board(position: self.pos, turn: self.opposite).move(candidate)
                if opponentBoard.isWin { return candidate }
            }
        }
        
        // 3️⃣ Dynamic heuristics based on board size
        let size = boardSize
        let center = size / 2
        
        var centerIndices: [Int] = []
        if size % 2 == 1 {
            centerIndices = [center * size + center]
        } else {
            centerIndices = [
                (center - 1) * size + (center - 1),
                (center - 1) * size + center,
                center * size + (center - 1),
                center * size + center
            ]
        }
        
        var corners: [Int] = []
        corners.append(0)
        corners.append(size - 1)
        corners.append(size * (size - 1))
        corners.append(size * size - 1)
        
        let centerMoves = centerIndices.filter { legalMoves.contains($0) }
        let cornerMoves = corners.filter { legalMoves.contains($0) }
        let otherMoves = legalMoves.filter { !centerIndices.contains($0) && !corners.contains($0) }
        
        func pick(_ arr: [Int]) -> Int? { arr.randomElement() }
        
        let roll = Int.random(in: 0..<100)
        if roll < suboptimalHeuristicProbability {
            if let m = pick(otherMoves) { return m }
            if let c = pick(cornerMoves) { return c }
            if let ce = pick(centerMoves) { return ce }
        } else {
            if let ce = pick(centerMoves) { return ce }
            if let c = pick(cornerMoves) { return c }
            if let m = pick(otherMoves) { return m }
        }
        
        // 4️⃣ Fallback to random
        return easyMove()
    }
}

// MARK: - Superior Minimax Implementation
extension Board {
    
    // MARK: - Advanced Heuristic Evaluation
    
    /// Pozitsiyani heuristic baholash (terminal bo'lmagan holatlar uchun)
    func advancedHeuristic(for player: SquareStatus) -> Int {
        let opponent = player == .x ? SquareStatus.o : .x
        let combos = generateWinningCombos()
        var score = 0
        
        for combo in combos {
            let playerCount = combo.filter { pos[$0] == player }.count
            let opponentCount = combo.filter { pos[$0] == opponent }.count
            
            // Faqat bir o'yinchi belgilari bo'lgan chiziqlar
            if playerCount > 0 && opponentCount == 0 {
                score += scoreForLine(playerCount: playerCount)
            }
            
            // Raqib bloklagan chiziqlar (manfiy ball)
            if opponentCount > 0 && playerCount == 0 {
                score -= scoreForLine(playerCount: opponentCount)
            }
        }
        
        // Markaziy pozitsiyalarga bonus
        score += centerControlBonus(for: player)
        
        return score
    }
    
    /// Chiziq uchun ball hisoblash (reduced values to prevent overflow)
    private func scoreForLine(playerCount: Int) -> Int {
        switch playerCount {
        case 1: return 1
        case 2: return 10
        case 3: return 100
        case 4: return 500
        case 5: return 1000
        default: return playerCount * 1000
        }
    }
    
    /// Markazni nazorat qilish bonusi (reduced bonus to prevent large accumulations)
    private func centerControlBonus(for player: SquareStatus) -> Int {
        let size = boardSize
        let center = size / 2
        let centerIndices: [Int]
        
        if size % 2 == 1 {
            // Toq o'lcham: bitta markaz
            centerIndices = [center * size + center]
        } else {
            // Juft o'lcham: 4 ta markaziy katak
            centerIndices = [
                (center - 1) * size + (center - 1),
                (center - 1) * size + center,
                center * size + (center - 1),
                center * size + center
            ]
        }
        
        var bonus = 0
        for idx in centerIndices where pos.indices.contains(idx) {
            if pos[idx] == player {
                bonus += 2 // Reduced from 5 to avoid large scores
            }
        }
        return bonus
    }
    
    // MARK: - Zobrist Hashing
    
    /// Zobrist hash uchun tasodifiy sonlar (static)
    private static var zobristTable: [[Int]] = {
        var table: [[Int]] = []
        let maxSize = 81 // 9x9 maksimal
        for _ in 0..<maxSize {
            table.append([Int.random(in: 0..<Int.max), Int.random(in: 0..<Int.max)])
        }
        return table
    }()
    
    /// Pozitsiyaning Zobrist hash qiymati
    func zobristHash() -> Int {
        var hash = 0
        for i in pos.indices {
            if pos[i] == .x {
                hash ^= Board.zobristTable[i][0]
            } else if pos[i] == .o {
                hash ^= Board.zobristTable[i][1]
            }
        }
        return hash
    }
    
    // MARK: - Move Ordering
    
    /// Harakatlarni prioritet bo'yicha tartiblash
    func orderedLegalMoves() -> [Int] {
        let size = boardSize
        let center = size / 2
        
        return legalMoves.sorted { move1, move2 in
            let score1 = movePriority(move1, center: center, size: size)
            let score2 = movePriority(move2, center: center, size: size)
            return score1 > score2
        }
    }
    
    /// Harakat prioritetini hisoblash
    private func movePriority(_ move: Int, center: Int, size: Int) -> Int {
        let row = move / size
        let col = move % size
        
        // Markazga yaqinroq - yuqoriroq prioritet
        let distanceFromCenter = abs(row - center) + abs(col - center)
        var priority = 100 - distanceFromCenter * 10
        
        // Diagonal pozitsiyalarga bonus
        if row == col || row + col == size - 1 {
            priority += 5
        }
        
        return priority
    }
    
    // MARK: - Core Superior Minimax with Negamax
    
    /// Superior Minimax with Transposition Table and Error Handling
    /// This function implements a negamax-style minimax with alpha-beta pruning,
    /// using transposition tables for optimization and safe negation to prevent arithmetic overflows.
    func superiorMinimaxCore(
        maxDepth: Int,
        alpha: Int = Int.min / 2, // Safer initial value to prevent overflow
        beta: Int = Int.max / 2, // Safer initial value to prevent overflow
        transTable: inout [Int: (score: Int, depth: Int)]
    ) -> (score: Int, bestMove: Int?) {
        // Helper function to safely negate values and prevent overflow
        func safeNegate(_ value: Int) -> Int {
            if value == Int.min {
                return Int.max // Approximate negation for Int.min to avoid overflow
            }
            return -value
        }
        
        // Validate maxDepth to prevent invalid recursion
        guard maxDepth >= 0 else {
            return (0, nil)
        }
        
        
        let hash = zobristHash()
        
        // Check transposition table for previously computed results
        if let entry = transTable[hash], entry.depth >= maxDepth {
            return (entry.score, nil)
        }
        
        // Check terminal states (win or draw)
        if isWin {
            let score = (opposite == turn) ? 1000 - maxDepth : -1000 + maxDepth // Reduced scores to prevent overflow
            return (score, nil)
        }
        
        if isDraw {
            return (0, nil)
        }
        
        // Check for empty legal moves
        let moves = orderedLegalMoves()
        guard !moves.isEmpty else {
            return (0, nil)
        }
        
        // Validate board size consistency
        guard boardSize * boardSize == pos.count else {
            return (0, nil)
        }
        
        var bestScore = Int.min / 2 // Safer initial best score
        var bestMove: Int? = nil
        var currentAlpha = alpha
        
        // Log moves being evaluated for debugging
        
        // Evaluate each move recursively
        for move in moves {
            // Validate move index
            guard pos.indices.contains(move), pos[move] == .empty else {
                continue
            }
            
            let newBoard = self.move(move)
            
            let (score, _) = newBoard.superiorMinimaxCore(
                maxDepth: maxDepth - 1,
                alpha: safeNegate(beta),
                beta: safeNegate(currentAlpha),
                transTable: &transTable
            )
            let negatedScore = safeNegate(score)
            
            if negatedScore > bestScore {
                bestScore = negatedScore
                bestMove = move
            }
            
            currentAlpha = max(currentAlpha, negatedScore)
            
            // Alpha-beta pruning to optimize search
            if currentAlpha >= beta {
                break
            }
        }
        
        // Warn if no valid move was found
        if bestMove == nil {
        }
        
        // Save result to transposition table
        transTable[hash] = (bestScore, maxDepth)
        
        return (bestScore, bestMove)
    }
    
    // MARK: - Adaptive Depth
    
    /// Taxta o'lchamiga qarab adaptive chuqurlik
    /// Determines the maximum search depth based on board size and empty cells
    private func adaptiveMaxDepth() -> Int {
        let size = boardSize
        let emptyCount = legalMoves.count
        
        switch size {
        case 3: return 9 // 3x3: full search possible
        case 4: return emptyCount > 10 ? 6 : 8
        case 5: return emptyCount > 15 ? 4 : 6
        case 6: return emptyCount > 20 ? 3 : 5
        case 7: return emptyCount > 30 ? 3 : 4
        case 8: return emptyCount > 40 ? 2 : 3
        case 9: return emptyCount > 50 ? 2 : 3
        default: return 4
        }
    }
    
    // MARK: - Main Entry Point
    
    /// Eng yaxshi harakatni topish (iterative deepening bilan)
    /// Finds the best move using iterative deepening within a time limit
    func findSuperiorMove(timeLimit: TimeInterval = 5.0) -> Int? {
        let startTime = Date()
        var transTable: [Int: (score: Int, depth: Int)] = [:]
        var bestMove: Int?
        var currentDepth = 1
        let maxPossibleDepth = min(legalMoves.count, adaptiveMaxDepth())
        
        
        // Validate legal moves
        guard !legalMoves.isEmpty else {
            return nil
        }
        
        // Iterative deepening loop to progressively deepen the search
        while currentDepth <= maxPossibleDepth {
            
            let (score, move) = superiorMinimaxCore(
                maxDepth: currentDepth,
                transTable: &transTable
            )
            
            if let move = move {
                bestMove = move
            } else {
            }
            
            // Check time limit to prevent exceeding computation time
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed > timeLimit {

                break
            }
            
            currentDepth += 1
        }
        
        // Log final result
        if let finalMove = bestMove {

        } else {

            bestMove = legalMoves.first
        }
        
        return bestMove
    }
    
    // MARK: - Helper for Logging Board State
    
    
}

// MARK: - Future Optimizations (skeleton only)
extension Board {
    /// Compact bitmask representation (future use)
    var bitmaskRepresentation: (xMask: Int, oMask: Int) {
        // TODO: Implement bitmask for efficient state representation
        return (0, 0)
    }
    
    /// Transposition table (future use)
    static var transpositionTable: [Int: Int] = [:]
    
    func stateHash() -> Int {
        // TODO: Implement alternative state hashing
        return pos.hashValue
    }
    
    /// Move ordering heuristic (future use)
    func orderedMoves() -> [Int] {
        // TODO: Advanced move ordering
        return legalMoves
    }
    
    /// Heuristic evaluation for non-terminal states (future use)
    func heuristicScore(for player: SquareStatus) -> Int {
        // TODO: Additional heuristic refinements
        return 0
    }
}
