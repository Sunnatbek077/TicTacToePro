//
//  GameConfigOptions.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 20/09/25.
//

import SwiftUI

enum PlayerOption: String, CaseIterable {
    case x = "X"
    case o = "O"
}

enum DifficultyOption: String, CaseIterable {
    case easy   = "Easy"
    case medium = "Med"
    case hard   = "Hard"

    var mapped: AIDifficulty {
        switch self {
        case .easy:   return .easy
        case .medium: return .medium
        case .hard:   return .hard
        }
    }
}

enum GameMode: String, CaseIterable {
    case ai  = "vs AI"
    case pvp = "PvP"

    var isPVP: Bool { self == .pvp }
    var icon: String { self == .ai ? "cpu" : "person.2.fill" }
}

// MARK: - BoardSize
enum BoardSize: Int, CaseIterable, Identifiable {
    case small   = 3
    case medium  = 4
    case large   = 5
    case xlarge  = 6
    case xxlarge = 7
    case huge    = 8
    case massive = 9

    var id: Int { rawValue }

    var title: String { "\(rawValue)×\(rawValue)" }

    var difficulty: String {
        switch self {
        case .small:           return "Easy"
        case .medium:          return "Med"
        case .large:           return "Hard"
        case .xlarge, .xxlarge: return "V.Hard"
        case .huge, .massive:  return "Extreme"
        }
    }

    var color: Color {
        switch self {
        case .small:   return .green
        case .medium:  return .blue
        case .large:   return .purple
        case .xlarge:  return .orange
        case .xxlarge: return .red
        case .huge:    return .pink
        case .massive: return .indigo
        }
    }
}

