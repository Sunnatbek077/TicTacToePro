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
    

    var id: Int { rawValue }

    var title: String { "\(rawValue)×\(rawValue)" }

    var color: Color {
        switch self {
        case .small:   return .green
        case .medium:  return .blue
        }
    }
}

