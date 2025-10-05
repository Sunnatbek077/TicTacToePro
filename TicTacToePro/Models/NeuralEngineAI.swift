//
//  NeuralEngineAI.swift
//  TicTacToePro - Neural Engine Implementation with Error Handling
//

import Foundation
import CoreML
import Accelerate
import os.log

// MARK: - Custom Errors
enum TicTacToeAIError: Error, LocalizedError {
    case modelNotLoaded
    case invalidBoardSize
    case noLegalMoves
    case predictionFailed(String)
    case timeoutExceeded
    case parallelComputingFailed
    case invalidMLArrayConversion
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Core ML model yuklanmadi"
        case .invalidBoardSize:
            return "Taxta o'lchami noto'g'ri"
        case .noLegalMoves:
            return "Hech qanday legal harakat yo'q"
        case .predictionFailed(let reason):
            return "Prediction failed: \(reason)"
        case .timeoutExceeded:
            return "Hisoblash vaqti tugadi"
        case .parallelComputingFailed:
            return "Parallel hisoblash xato"
        case .invalidMLArrayConversion:
            return "Board -> MLArray konvertatsiya xatosi"
        }
    }
}

// MARK: - Performance Metrics
struct AIPerformanceMetrics {
    let executionTime: TimeInterval
    let method: String
    let boardSize: Int
    let legalMovesCount: Int
    let success: Bool
    let errorMessage: String?
    
    func log() {
        let status = success ? "✅" : "❌"
        let timeFormatted = String(format: "%.3f", executionTime)
        print("\(status) [\(method)] Size:\(boardSize)x\(boardSize) | Moves:\(legalMovesCount) | Time:\(timeFormatted)s")
        if let error = errorMessage {
            print("   Error: \(error)")
        }
    }
}

// MARK: - Logger
class AILogger {
    static let shared = AILogger()
    private let logger: OSLog
    
    private init() {
        logger = OSLog(subsystem: "com.tictactoe.ai", category: "AI")
    }
    
    func info(_ message: String) {
        os_log(.info, log: logger, "%{public}@", message)
        print("ℹ️ [INFO] \(message)")
    }
    
    func debug(_ message: String) {
        os_log(.debug, log: logger, "%{public}@", message)
        #if DEBUG
        print("🔍 [DEBUG] \(message)")
        #endif
    }
    
    func error(_ message: String, error: Error? = nil) {
        os_log(.error, log: logger, "%{public}@", message)
        print("❌ [ERROR] \(message)")
        if let error = error {
            print("   Details: \(error.localizedDescription)")
        }
    }
    
    func success(_ message: String) {
        os_log(.info, log: logger, "%{public}@", message)
        print("✅ [SUCCESS] \(message)")
    }
    
    func warning(_ message: String) {
        os_log(.default, log: logger, "%{public}@", message)
        print("⚠️ [WARNING] \(message)")
    }
}

// MARK: - Option 1: Core ML Model (Neural Engine)
@available(iOS 14.0, *)
class CoreMLTicTacToeAI {
    
    private var model: MLModel?
    private let logger = AILogger.shared
    private var isModelLoaded = false
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        logger.info("Core ML model yuklanmoqda...")
        
        do {
            // TODO: Actual model file nomini kiriting
            // let config = MLModelConfiguration()
            // config.computeUnits = .all // Neural Engine + GPU + CPU
            // model = try TicTacToeModel(configuration: config).model
            
            // Hozircha simulation
            logger.warning("Core ML model fayli topilmadi. Fallback mode.")
            isModelLoaded = false
            
        } catch {
            logger.error("Core ML model yuklashda xato", error: error)
            isModelLoaded = false
        }
    }
    
    func predictBestMove(board: Board) -> Result<Int, TicTacToeAIError> {
        let startTime = Date()
        
        guard isModelLoaded, model != nil else {
            logger.warning("Model yuklanmagan, fallback minimax ishlatilmoqda")
            
            if let move = board.findSuperiorMove(timeLimit: 1.0) {
                let metrics = AIPerformanceMetrics(
                    executionTime: Date().timeIntervalSince(startTime),
                    method: "Fallback Minimax",
                    boardSize: board.boardSize,
                    legalMovesCount: board.legalMoves.count,
                    success: true,
                    errorMessage: nil
                )
                metrics.log()
                return .success(move)
            } else {
                return .failure(.modelNotLoaded)
            }
        }
        
        do {
            logger.debug("Neural Engine prediction boshlandi...")
            
            let input = try boardToMLArray(board)
            
            guard let prediction = try model?.prediction(from: input) else {
                throw TicTacToeAIError.predictionFailed("Model prediction nil qaytardi")
            }
            
            guard let bestMove = extractBestMove(from: prediction, legalMoves: board.legalMoves) else {
                throw TicTacToeAIError.noLegalMoves
            }
            
            let metrics = AIPerformanceMetrics(
                executionTime: Date().timeIntervalSince(startTime),
                method: "Neural Engine",
                boardSize: board.boardSize,
                legalMovesCount: board.legalMoves.count,
                success: true,
                errorMessage: nil
            )
            metrics.log()
            logger.success("Neural Engine harakati: \(bestMove)")
            
            return .success(bestMove)
            
        } catch let error as TicTacToeAIError {
            let metrics = AIPerformanceMetrics(
                executionTime: Date().timeIntervalSince(startTime),
                method: "Neural Engine",
                boardSize: board.boardSize,
                legalMovesCount: board.legalMoves.count,
                success: false,
                errorMessage: error.localizedDescription
            )
            metrics.log()
            logger.error("Neural Engine xatosi", error: error)
            return .failure(error)
            
        } catch {
            logger.error("Kutilmagan xato", error: error)
            return .failure(.predictionFailed(error.localizedDescription))
        }
    }
    
    private func boardToMLArray(_ board: Board) throws -> MLFeatureProvider {
        let size = board.boardSize
        
        guard size >= 3 && size <= 9 else {
            throw TicTacToeAIError.invalidBoardSize
        }
        
        let array = try MLMultiArray(
            shape: [NSNumber(value: size), NSNumber(value: size), 3],
            dataType: .float32
        )
        
        for i in 0..<board.pos.count {
            let row = i / size
            let col = i % size
            
            switch board.pos[i] {
            case .empty:
                array[[row, col, 0] as [NSNumber]] = 1.0
            case .x, .xw:
                array[[row, col, 1] as [NSNumber]] = 1.0
            case .o, .ow:
                array[[row, col, 2] as [NSNumber]] = 1.0
            }
        }
        
        logger.debug("Board -> MLArray konvertatsiya muvaffaqiyatli")
        return try MLDictionaryFeatureProvider(dictionary: ["board_state": array])
    }
    
    private func extractBestMove(from prediction: MLFeatureProvider, legalMoves: [Int]) -> Int? {
        // TODO: Model output strukturasiga qarab implement qilish
        logger.debug("Prediction natijasi parse qilinmoqda...")
        return legalMoves.first
    }
}

// MARK: - Option 2: Parallel Computing with GCD
class ParallelMinimaxAI {
    
    private let queue = DispatchQueue(label: "com.tictactoe.parallel", attributes: .concurrent)
    private let logger = AILogger.shared
    
    func findBestMoveParallel(board: Board, maxDepth: Int = 4, timeout: TimeInterval = 5.0) -> Result<Int, TicTacToeAIError> {
        let startTime = Date()
        
        let moves = board.legalMoves
        guard !moves.isEmpty else {
            logger.error("Legal harakatlar yo'q")
            return .failure(.noLegalMoves)
        }
        
        logger.info("Parallel minimax boshlandi: \(moves.count) ta harakat")
        
        var results: [Int: Int] = [:]
        let lock = NSLock()
        let group = DispatchGroup()
        var hasTimedOut = false
        
        for move in moves {
            group.enter()
            
            queue.async {
                defer { group.leave() }
                
                // Timeout tekshiruvi
                if Date().timeIntervalSince(startTime) > timeout {
                    hasTimedOut = true
                    return
                }
                
                do {
                    let newBoard = board.move(move)
                    var transTable: [Int: (score: Int, depth: Int)] = [:]
                    
                    let (score, _) = newBoard.superiorMinimaxCore(
                        maxDepth: maxDepth - 1,
                        transTable: &transTable
                    )
                    
                    lock.lock()
                    results[move] = -score
                    lock.unlock()
                    
                    self.logger.debug("Harakat \(move) baholandi: \(score)")
                    
                } catch {
                    self.logger.error("Harakat \(move) baholashda xato", error: error)
                }
            }
        }
        
        // Timeout bilan kutish
        let waitResult = group.wait(timeout: .now() + timeout)
        
        if waitResult == .timedOut || hasTimedOut {
            logger.warning("Timeout: \(timeout)s. Mavjud natijalardan foydalaniladi.")
        }
        
        guard let bestMove = results.max(by: { $0.value < $1.value })?.key else {
            let metrics = AIPerformanceMetrics(
                executionTime: Date().timeIntervalSince(startTime),
                method: "Parallel Minimax",
                boardSize: board.boardSize,
                legalMovesCount: moves.count,
                success: false,
                errorMessage: "Hech qanday natija topilmadi"
            )
            metrics.log()
            return .failure(.parallelComputingFailed)
        }
        
        let metrics = AIPerformanceMetrics(
            executionTime: Date().timeIntervalSince(startTime),
            method: "Parallel Minimax",
            boardSize: board.boardSize,
            legalMovesCount: moves.count,
            success: true,
            errorMessage: nil
        )
        metrics.log()
        logger.success("Eng yaxshi harakat topildi: \(bestMove)")
        
        return .success(bestMove)
    }
}

// MARK: - Option 3: Metal Performance Shaders (GPU)
class MetalGPUAI {
    
    private let logger = AILogger.shared
    
    func findBestMoveGPU(board: Board) -> Result<Int, TicTacToeAIError> {
        logger.info("Metal GPU hisoblash (hozircha qo'llab-quvvatlanmaydi)")
        logger.warning("Fallback minimax ishlatilmoqda")
        
        if let move = board.findSuperiorMove(timeLimit: 1.0) {
            return .success(move)
        } else {
            return .failure(.noLegalMoves)
        }
    }
}

// MARK: - Smart AI Manager (Adaptive with Error Handling)
class SmartAIManager {
    
    private let coreMLAI: CoreMLTicTacToeAI?
    private let parallelAI = ParallelMinimaxAI()
    private let metalAI = MetalGPUAI()
    private let logger = AILogger.shared
    
    // Statistics
    private(set) var totalCalls = 0
    private(set) var successfulCalls = 0
    private(set) var averageExecutionTime: TimeInterval = 0
    
    init() {
        logger.info("SmartAIManager ishga tushirilmoqda...")
        
        if #available(iOS 14.0, *) {
            coreMLAI = CoreMLTicTacToeAI()
            logger.info("Core ML support: ✅")
        } else {
            coreMLAI = nil
            logger.warning("Core ML support: ❌ (iOS 14+ kerak)")
        }
    }
    
    func findBestMove(board: Board, difficulty: AIDifficulty) -> Result<Int, TicTacToeAIError> {
        let startTime = Date()
        totalCalls += 1
        
        logger.info("=== AI Move Request ===")
        logger.info("Difficulty: \(difficulty)")
        logger.info("Board Size: \(board.boardSize)x\(board.boardSize)")
        logger.info("Legal Moves: \(board.legalMoves.count)")
        
        let result: Result<Int, TicTacToeAIError>
        
        switch difficulty {
        case .easy:
            logger.debug("Easy mode: random harakat")
            let move = board.bestMove(difficulty: .easy)
            result = .success(move)
            
        case .medium:
            logger.debug("Medium mode: heuristic AI")
            let move = board.bestMove(difficulty: .medium)
            result = .success(move)
            
        case .hard:
            // Strategy: Neural Engine -> Parallel -> Fallback
            result = findHardMove(board: board)
        }
        
        // Update statistics
        let executionTime = Date().timeIntervalSince(startTime)
        averageExecutionTime = (averageExecutionTime * Double(totalCalls - 1) + executionTime) / Double(totalCalls)
        
        if case .success = result {
            successfulCalls += 1
        }
        
        logger.info("=== Request Complete ===")
        logger.info("Success Rate: \(successfulCalls)/\(totalCalls) (\(Int(Double(successfulCalls)/Double(totalCalls)*100))%)")
        logger.info("Avg Execution Time: \(String(format: "%.3f", averageExecutionTime))s")
        logger.info("=======================\n")
        
        return result
    }
    
    private func findHardMove(board: Board) -> Result<Int, TicTacToeAIError> {
        // 1️⃣ Try Neural Engine (fastest)
        if #available(iOS 14.0, *), let coreMLAI = coreMLAI {
            logger.info("🧠 Trying Neural Engine...")
            
            let result = coreMLAI.predictBestMove(board: board)
            if case .success(let move) = result {
                logger.success("Neural Engine muvaffaqiyatli!")
                return .success(move)
            } else {
                logger.warning("Neural Engine fallback")
            }
        }
        
        // 2️⃣ Try Parallel Computing (for large boards)
        if board.boardSize >= 5 {
            logger.info("⚡️ Trying Parallel Computing...")
            
            let depth = adaptiveDepth(board)
            let result = parallelAI.findBestMoveParallel(
                board: board,
                maxDepth: depth,
                timeout: 5.0
            )
            
            if case .success(let move) = result {
                logger.success("Parallel computing muvaffaqiyatli!")
                return .success(move)
            } else {
                logger.warning("Parallel computing fallback")
            }
        }
        
        // 3️⃣ Fallback: Standard optimized minimax
        logger.info("🔄 Using fallback minimax...")
        
        if let move = board.findBestMove(board) {
            logger.success("Fallback minimax muvaffaqiyatli!")
            return .success(move)
        }
        
        // 4️⃣ Last resort: random legal move
        if let move = board.legalMoves.first {
            logger.warning("Last resort: random move")
            return .success(move)
        }
        
        logger.error("Hech qanday harakat topilmadi!")
        return .failure(.noLegalMoves)
    }
    
    private func adaptiveDepth(_ board: Board) -> Int {
        let size = board.boardSize
        let emptyCount = board.legalMoves.count
        
        let depth: Int
        switch size {
        case 3: depth = 9
        case 4: depth = emptyCount > 10 ? 5 : 7
        case 5: depth = emptyCount > 15 ? 3 : 5
        case 6: depth = emptyCount > 20 ? 3 : 4
        case 7...9: depth = 2
        default: depth = 3
        }
        
        logger.debug("Adaptive depth: \(depth) (size: \(size), empty: \(emptyCount))")
        return depth
    }
    
    // Public statistics
    func printStatistics() {
        logger.info("📊 === AI Statistics ===")
        logger.info("Total Calls: \(totalCalls)")
        logger.info("Successful: \(successfulCalls)")
        logger.info("Failed: \(totalCalls - successfulCalls)")
        logger.info("Success Rate: \(Int(Double(successfulCalls)/Double(max(totalCalls, 1))*100))%")
        logger.info("Avg Time: \(String(format: "%.3f", averageExecutionTime))s")
        logger.info("========================")
    }
}

// MARK: - Optimized Board Extension with Error Handling
extension Board {
    
    func lightweightBestMove(maxDepth: Int = 3) -> Result<Int, TicTacToeAIError> {
        let startTime = Date()
        
        guard !legalMoves.isEmpty else {
            return .failure(.noLegalMoves)
        }
        
        var transTable: [Int: (score: Int, depth: Int)] = [:]
        let priorityMoves = orderedLegalMoves().prefix(min(10, legalMoves.count))
        
        var bestScore = Int.min
        var bestMove: Int? = nil
        
        for move in priorityMoves {
            let newBoard = self.move(move)
            let (score, _) = newBoard.superiorMinimaxCore(
                maxDepth: maxDepth,
                transTable: &transTable
            )
            
            if -score > bestScore {
                bestScore = -score
                bestMove = move
            }
        }
        
        if let move = bestMove {
            let metrics = AIPerformanceMetrics(
                executionTime: Date().timeIntervalSince(startTime),
                method: "Lightweight",
                boardSize: boardSize,
                legalMovesCount: legalMoves.count,
                success: true,
                errorMessage: nil
            )
            metrics.log()
            return .success(move)
        }
        
        return .failure(.noLegalMoves)
    }
}

// MARK: - Training Data Generator with Error Handling
class TrainingDataGenerator {
    
    private let logger = AILogger.shared
    
    func generateTrainingData(
        boardSize: Int,
        games: Int = 10000,
        progressCallback: ((Int, Int) -> Void)? = nil
    ) -> Result<[(input: [Float], output: Int)], TicTacToeAIError> {
        
        logger.info("Training data yaratish boshlandi...")
        logger.info("Board Size: \(boardSize)x\(boardSize)")
        logger.info("Games: \(games)")
        
        guard boardSize >= 3 && boardSize <= 9 else {
            logger.error("Noto'g'ri board size: \(boardSize)")
            return .failure(.invalidBoardSize)
        }
        
        var dataset: [(input: [Float], output: Int)] = []
        var successfulGames = 0
        
        for gameNum in 0..<games {
            var board = Board(
                position: Array(repeating: .empty, count: boardSize * boardSize),
                turn: .x
            )
            
            var movesInGame = 0
            
            while !board.isWin && !board.isDraw && movesInGame < boardSize * boardSize {
                guard let move = board.findSuperiorMove(timeLimit: 0.5) ?? board.legalMoves.randomElement() else {
                    break
                }
                
                let input = boardToVector(board)
                dataset.append((input: input, output: move))
                
                board = board.move(move)
                movesInGame += 1
            }
            
            successfulGames += 1
            
            if (gameNum + 1) % 100 == 0 {
                logger.debug("Progress: \(gameNum + 1)/\(games) games")
                progressCallback?(gameNum + 1, games)
            }
        }
        
        logger.success("Training data tayyor: \(dataset.count) samples, \(successfulGames) games")
        return .success(dataset)
    }
    
    private func boardToVector(_ board: Board) -> [Float] {
        return board.pos.map { square -> Float in
            switch square {
            case .empty: return 0.0
            case .x, .xw: return 1.0
            case .o, .ow: return -1.0
            }
        }
    }
    
    func exportToCSV(
        data: [(input: [Float], output: Int)],
        filename: String
    ) -> Result<Void, TicTacToeAIError> {
        
        logger.info("CSV export: \(filename)")
        logger.info("Samples: \(data.count)")
        
        // TODO: Actual CSV writing
        logger.success("CSV export muvaffaqiyatli (simulation)")
        
        return .success(())
    }
}

// MARK: - Usage Examples
/*
 // 1. Smart AI Manager (Production)
 let aiManager = SmartAIManager()
 let board = Board(position: Array(repeating: .empty, count: 25), turn: .x)
 
 switch aiManager.findBestMove(board: board, difficulty: .hard) {
 case .success(let move):
     print("✅ Best move: \(move)")
     let newBoard = board.move(move)
 case .failure(let error):
     print("❌ Error: \(error.localizedDescription)")
     // Fallback logic
 }
 
 // Statistics ko'rish
 aiManager.printStatistics()
 
 // 2. Parallel computing
 let parallelAI = ParallelMinimaxAI()
 switch parallelAI.findBestMoveParallel(board: board, maxDepth: 4, timeout: 3.0) {
 case .success(let move):
     print("Parallel AI move: \(move)")
 case .failure(let error):
     print("Error: \(error)")
 }
 
 // 3. Lightweight minimax
 switch board.lightweightBestMove(maxDepth: 3) {
 case .success(let move):
     print("Lightweight move: \(move)")
 case .failure(let error):
     print("Error: \(error)")
 }
 
 // 4. Training data with progress
 let generator = TrainingDataGenerator()
 switch generator.generateTrainingData(boardSize: 5, games: 1000) { data, total in
     print("Progress: \(data)/\(total)")
 } {
 case .success(let trainingData):
     print("✅ Generated \(trainingData.count) samples")
     _ = generator.exportToCSV(data: trainingData, filename: "training.csv")
 case .failure(let error):
     print("❌ Error: \(error)")
 }
 */
