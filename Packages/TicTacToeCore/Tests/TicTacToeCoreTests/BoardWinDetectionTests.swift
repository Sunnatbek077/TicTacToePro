import Testing
@testable import TicTacToeCore

/// Regression tests for the win-detection rules.
///
/// These exist because the watchOS copy of `GameLogicModel` had drifted: it used
/// `winLength == boardSize` and generated only full-length rows/columns, so a 5x5
/// game needed five in a row on the watch but four on iOS. The rules below are the
/// iOS (correct) behaviour, pinned so no future copy can drift again.
@Suite("Board win detection")
struct BoardWinDetectionTests {

    // MARK: - Helpers

    private func empty(_ size: Int) -> [SquareStatus] {
        Array(repeating: .empty, count: size * size)
    }

    private func board(size: Int, marked cells: [Int]) -> Board {
        var pos = empty(size)
        for cell in cells { pos[cell] = .x }
        return Board(position: pos, turn: .o)
    }

    // MARK: - winLength

    @Test("winLength per board size",
          arguments: [(3, 3), (4, 4), (5, 4), (6, 5), (7, 5), (8, 5), (9, 5)])
    func winLengthPerBoardSize(size: Int, expected: Int) {
        #expect(Board(position: empty(size), turn: .x).winLength == expected)
    }

    /// The line length must never shrink as the board grows, and must never
    /// exceed five — a longer line on a bigger board is what makes the
    /// progression legible, and past five large boards become forced draws.
    @Test("winLength is non-decreasing and capped at five")
    func winLengthIsMonotonicAndCapped() {
        var previous = 0
        for size in 3...9 {
            let length = Board(position: empty(size), turn: .x).winLength
            #expect(length >= previous, "winLength dropped going from \(size - 1) to \(size)")
            #expect(length <= 5, "winLength exceeded the cap at \(size)x\(size)")
            #expect(length <= size, "winLength longer than the board at \(size)x\(size)")
            previous = length
        }
    }

    /// A length greater than the board would make `0...(size - length)` in the
    /// combo generator an invalid range and trap at runtime.
    @Test("degenerate board sizes never produce a length longer than the board")
    func degenerateBoardsStayInRange() {
        for cells in [0, 1, 4, 100, 144] {
            let b = Board(position: Array(repeating: .empty, count: cells), turn: .x)
            #expect(b.winLength <= max(b.boardSize, 0),
                    "\(cells) cells -> boardSize \(b.boardSize), winLength \(b.winLength)")
        }
    }

    /// The specific regression: five-in-a-row must NOT be required on a 5x5 board.
    @Test("5x5 wins on four in a row, not five")
    func fiveByFiveWinsOnFourInARow() {
        let b = board(size: 5, marked: [0, 1, 2, 3])   // top row, fifth cell left empty
        #expect(b.isWin, "4-in-a-row must win on a 5x5 board")
        #expect(b.winningLine?.winner == .x)
    }

    // MARK: - Combination generation

    @Test("3x3 reproduces the classic eight lines")
    func threeByThreeMatchesClassicEightLines() {
        let generated = Set(Board(position: empty(3), turn: .x)
            .generateWinningCombos()
            .map { $0.sorted() })
        let classic: Set<[Int]> = Set([
            [0, 1, 2], [3, 4, 5], [6, 7, 8],
            [0, 3, 6], [1, 4, 7], [2, 5, 8],
            [0, 4, 8], [2, 4, 6]
        ].map { $0.sorted() })
        #expect(generated == classic)
    }

    @Test("combos are in bounds, correct length, and unique", arguments: 3...9)
    func combosAreWellFormed(size: Int) {
        let b = Board(position: empty(size), turn: .x)
        let combos = b.generateWinningCombos()
        let cellCount = size * size

        #expect(!combos.isEmpty, "size \(size) produced no combos")

        for combo in combos {
            #expect(combo.count == b.winLength,
                    "size \(size): combo length must equal winLength")
            #expect(Set(combo).count == combo.count,
                    "size \(size): a combo repeated a cell")
            #expect(combo.allSatisfy { (0..<cellCount).contains($0) },
                    "size \(size): combo out of bounds -> \(combo)")
        }

        #expect(Set(combos.map { $0.sorted() }).count == combos.count,
                "size \(size): duplicate combos generated")
    }

    /// Every orientation must be detected, not just rows and columns.
    @Test("all four orientations win on 4x4",
          arguments: [[0, 1, 2, 3],      // row
                      [0, 4, 8, 12],     // column
                      [0, 5, 10, 15],    // main diagonal
                      [3, 6, 9, 12]])    // anti-diagonal
    func allFourOrientationsWinOnFourByFour(cells: [Int]) {
        let b = board(size: 4, marked: cells)
        #expect(b.isWin, "expected win for \(cells) on 4x4")
        #expect(b.winningLine?.winner == .x)
    }

    /// Offset lines (not starting at an edge) are exactly what the stale watch
    /// generator missed.
    @Test("offset lines win on 5x5",
          arguments: [[6, 12, 18, 24],   // diagonal from (1,1)
                      [11, 12, 13, 14]]) // row 2, shifted one column right
    func offsetLinesWinOnFiveByFive(cells: [Int]) {
        #expect(board(size: 5, marked: cells).isWin,
                "expected win for offset line \(cells) on 5x5")
    }

    // MARK: - Negative cases

    @Test("empty board is neither win nor draw", arguments: 3...9)
    func emptyBoardIsNeitherWinNorDraw(size: Int) {
        let b = Board(position: empty(size), turn: .x)
        #expect(!b.isWin, "size \(size) empty board reported a win")
        #expect(!b.isDraw, "size \(size) empty board reported a draw")
    }

    @Test("three in a row does not win on 5x5")
    func threeInARowDoesNotWinOnFiveByFive() {
        #expect(!board(size: 5, marked: [0, 1, 2]).isWin,
                "3-in-a-row must not win when winLength is 4")
    }

    @Test("a line broken by the opponent is not a win")
    func lineBrokenByOpponentIsNotAWin() {
        var pos = empty(4)
        pos[0] = .x; pos[1] = .x; pos[2] = .o; pos[3] = .x
        #expect(!Board(position: pos, turn: .o).isWin)
    }

    @Test("classic 3x3 draw is detected")
    func classicThreeByThreeDraw() {
        // x o x
        // x o o
        // o x x
        let pos: [SquareStatus] = [.x, .o, .x,
                                   .x, .o, .o,
                                   .o, .x, .x]
        let b = Board(position: pos, turn: .x)
        #expect(!b.isWin)
        #expect(b.isDraw)
    }

    // MARK: - Moves

    @Test("safeMove rejects occupied and out-of-range indices")
    func safeMoveRejectsInvalidMoves() {
        var pos = empty(3)
        pos[4] = .x
        let b = Board(position: pos, turn: .o)
        #expect(b.safeMove(4) == nil, "occupied cell must be rejected")
        #expect(b.safeMove(-1) == nil, "negative index must be rejected")
        #expect(b.safeMove(9) == nil, "out-of-range index must be rejected")
        #expect(b.safeMove(0) != nil)
    }

    @Test("move alternates turn and leaves the original board untouched")
    func moveAlternatesTurnAndIsNonMutating() {
        let b = Board(position: empty(3), turn: .x)
        let next = b.move(0)
        #expect(next.turn == .o)
        #expect(next.pos[0] == .x)
        #expect(b.pos[0] == .empty, "Board is a value type; original must not mutate")
    }

    @Test("legalMoves shrinks as the board fills")
    func legalMovesShrinkAsBoardFills() {
        var pos = empty(3)
        #expect(Board(position: pos, turn: .x).legalMoves.count == 9)
        pos[0] = .x
        pos[8] = .o
        #expect(Board(position: pos, turn: .x).legalMoves.count == 7)
    }

    // MARK: - Zobrist hashing

    @Test("zobrist hash is stable and distinguishes positions")
    func zobristHashIsStableAndDistinct() {
        var a = empty(3); a[0] = .x
        var b = empty(3); b[0] = .o

        let boardA = Board(position: a, turn: .o)
        #expect(boardA.zobristHash() == boardA.zobristHash(),
                "hash must be stable across calls")
        #expect(boardA.zobristHash() != Board(position: b, turn: .x).zobristHash(),
                "different marks must hash differently")
        #expect(Board(position: empty(3), turn: .x).zobristHash() == 0,
                "empty board hashes to 0")
    }
}
