//
//  GameConfigOptions.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//
//  All of the start-menu configuration options live here. `BoardSize` used to be
//  declared inside StartMenuView.swift; it is a configuration model, not a view,
//  so it belongs next to the other option enums.
//

import SwiftUI

// MARK: - Player

enum PlayerOption: String, CaseIterable {
    case x = "X"
    case o = "O"
}

// MARK: - Difficulty

enum DifficultyOption: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var mapped: AIDifficulty {
        switch self {
        case .easy: return .easy
        case .medium: return .medium
        case .hard: return .hard
        }
    }
}

// MARK: - Game Mode

enum GameMode: String, CaseIterable {
    case ai = "AI"
    case pvp = "P v P"

    var isPVP: Bool { self == .pvp }

    /// The "Starting Player" label was ambiguous: it never said whether you were
    /// picking your own mark or who moves first. In AI mode both are true of the
    /// same choice (you play the mark you pick, and it moves first), so each mode
    /// gets the wording that actually describes it.
    var symbolSectionTitle: LocalizedStringKey {
        isPVP ? "First Move" : "You Play"
    }

    var symbolSectionFootnote: LocalizedStringKey {
        isPVP ? "This mark moves first." : "You take this mark and move first."
    }
}

// MARK: - Board Size

enum BoardSize: Int, CaseIterable, Identifiable {
    case small = 3
    case medium = 4
    case large = 5
    case xlarge = 6
    case xxlarge = 7
    case huge = 8
    case massive = 9

    var id: Int { rawValue }

    var title: String { "\(rawValue)×\(rawValue)" }

    /// How many marks in a row actually win on this board.
    ///
    /// The progression is non-decreasing and caps at five:
    ///
    /// | Board | Line | Why |
    /// |---|---|---|
    /// | 3×3 | 3 | The classic game. |
    /// | 4×4, 5×5 | 4 | Four is the standard for these; 5×5 needing five would force full lines only. |
    /// | 6×6 – 9×9 | 5 | Gomoku's line length, and the cap: beyond five, large boards turn into forced draws. |
    ///
    /// The previous table gave 6×6 and 7×7 a length of four, which was the one
    /// genuinely broken step: 7×7 asked for the same four in a row as 4×4 while
    /// being presented as far harder, and the extra space made it *easier* to
    /// complete a line, not harder.
    ///
    /// - Important: This must stay in step with `Board.winLength` in the game
    ///   logic. It is mirrored here only so the menu can show the rule without
    ///   building a `Board`; once `TicTacToeCore` is linked into the app target,
    ///   delete this and read `Board.winLength` directly.
    var winLength: Int {
        switch self {
        case .small: return 3
        case .medium, .large: return 4
        case .xlarge, .xxlarge, .huge, .massive: return 5
        }
    }

    /// The real rule, shown instead of the old flavour names.
    ///
    /// Those names ("Classic" → "Challenging" → … → "Legendary") implied a
    /// difficulty that rises with board size, which the rules did not deliver.
    /// The rule itself has since been corrected (see the note on `winLength`),
    /// and it is now shown directly — the one thing a player needs in order to
    /// choose between seven boards.
    var winConditionText: String {
        "\(winLength) in a row"
    }

    // NOTE: there was a `systemImage` here. SF Symbols only offer a few distinct
    // grid glyphs, so seven board sizes collapsed onto three icons and "9×9"
    // rendered beside a 3×3 grid symbol. An icon that contradicts its own label
    // is worse than no icon, and `title` already states the size precisely.

    var color: Color {
        switch self {
        case .small: return .green
        case .medium: return .blue
        case .large: return .purple
        case .xlarge: return .orange
        case .xxlarge: return .red
        case .huge: return .pink
        case .massive: return .indigo
        }
    }

    // MARK: Time limits

    /// Time options scaled to the board.
    ///
    /// Previously every board offered the same 5–30 minute range. A 3×3 game is
    /// over in well under a minute, so "5 min ⚡ Quick Match" was roughly ten
    /// times longer than the game it timed, and "30 min" was meaningless. Each
    /// tier returns exactly six options so the two-column grid fills evenly.
    var timeLimitOptions: [TimeLimitOption] {
        switch self {
        case .small:
            return [.oneMinute, .twoMinutes, .threeMinutes, .fiveMinutes, .tenMinutes, .unlimited]
        case .medium, .large:
            return [.twoMinutes, .threeMinutes, .fiveMinutes, .tenMinutes, .fifteenMinutes, .unlimited]
        case .xlarge, .xxlarge:
            return [.threeMinutes, .fiveMinutes, .tenMinutes, .fifteenMinutes, .twentyMinutes, .unlimited]
        case .huge, .massive:
            return [.fiveMinutes, .tenMinutes, .fifteenMinutes, .twentyMinutes, .thirtyMinutes, .unlimited]
        }
    }

    var recommendedTimeLimit: TimeLimitOption {
        switch self {
        case .small: return .twoMinutes
        case .medium, .large: return .fiveMinutes
        case .xlarge, .xxlarge: return .tenMinutes
        case .huge, .massive: return .fifteenMinutes
        }
    }

    /// Keeps a selection valid when the board size changes.
    func resolvedTimeLimit(from current: TimeLimitOption) -> TimeLimitOption {
        timeLimitOptions.contains(current) ? current : recommendedTimeLimit
    }
}

// MARK: - Time Limit

enum TimeLimitOption: Int, CaseIterable, Identifiable {
    case oneMinute      = 1
    case twoMinutes     = 2
    case threeMinutes   = 3
    case fiveMinutes    = 5
    case tenMinutes     = 10
    case fifteenMinutes = 15
    case twentyMinutes  = 20
    case thirtyMinutes  = 30
    case unlimited      = 0

    var id: Int { rawValue }

    var isUnlimited: Bool { self == .unlimited }

    var title: String {
        isUnlimited ? "Unlimited" : "\(rawValue) min"
    }

    /// Pace category, named in absolute terms.
    ///
    /// The old labels ranked options within a fixed list ("Quick Match",
    /// "Standard", "Extended"…), which stopped being true once the list varies
    /// by board size — five minutes is the *shortest* option on 9×9 and a long
    /// one on 3×3. These names describe the duration itself, so they hold on
    /// every board. Repeats across neighbouring durations are intentional.
    var pace: String {
        switch self {
        case .oneMinute:                    return "Bullet"
        case .twoMinutes, .threeMinutes:    return "Blitz"
        case .fiveMinutes, .tenMinutes:     return "Rapid"
        case .fifteenMinutes, .twentyMinutes: return "Classical"
        case .thirtyMinutes:                return "Marathon"
        case .unlimited:                    return "No clock"
        }
    }

    var systemImage: String {
        switch self {
        case .oneMinute:      return "bolt.fill"
        case .twoMinutes, .threeMinutes: return "hare.fill"
        case .fiveMinutes, .tenMinutes:  return "stopwatch"
        case .fifteenMinutes, .twentyMinutes: return "clock"
        case .thirtyMinutes:  return "tortoise.fill"
        case .unlimited:      return "infinity"
        }
    }

    var color: Color {
        switch self {
        case .oneMinute, .twoMinutes:  return .red
        case .threeMinutes:            return .orange
        case .fiveMinutes, .tenMinutes: return .blue
        case .fifteenMinutes:          return .purple
        case .twentyMinutes:           return .indigo
        case .thirtyMinutes:           return .green
        case .unlimited:               return .cyan
        }
    }

    /// Re-usable gradient for the selected border
    var selectionGradient: LinearGradient {
        LinearGradient(colors: [color, color.opacity(0.6)],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
    }
}
