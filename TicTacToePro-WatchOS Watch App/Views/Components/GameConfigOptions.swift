//
//  GameConfigOptions.swift
//  TicTacToePro watchOS
//
//  Created by Sunnatbek on 20/09/25.
//  watchOS compatible - no changes needed
//

import SwiftUI

enum PlayerOption: String, CaseIterable {
    case x = "X"
    case o = "O"
}

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

enum GameMode: String, CaseIterable {
    case ai = "AI"
    case pvp = "P v P"
    
    var isPVP: Bool { self == .pvp }
}

enum TimeLimitOption: Int, CaseIterable, Identifiable {
    case fiveMinutes   = 5
    case tenMinutes    = 10
    case fifteenMinutes = 15
    case twentyMinutes = 20
    case thirtyMinutes = 30
    case unlimited     = 0
    
    var id: Int { rawValue }
    
    var title: String {
        rawValue == 0 ? "∞" : "\(rawValue)m"
    }
    
    var description: String {
        switch self {
        case .fiveMinutes:   return "Quick"
        case .tenMinutes:    return "Standard"
        case .fifteenMinutes: return "Moderate"
        case .twentyMinutes: return "Extended"
        case .thirtyMinutes: return "Long"
        case .unlimited:     return "No Limit"
        }
    }
    
    var emoji: String {
        switch self {
        case .fiveMinutes:   return "⚡"
        case .tenMinutes:    return "⏱️"
        case .fifteenMinutes: return "⌛"
        case .twentyMinutes: return "⏳"
        case .thirtyMinutes: return "🕰️"
        case .unlimited:     return "∞"
        }
    }
    
    var color: Color {
        switch self {
        case .fiveMinutes:   return .red
        case .tenMinutes:    return .blue
        case .fifteenMinutes: return .purple
        case .twentyMinutes: return .orange
        case .thirtyMinutes: return .green
        case .unlimited:     return .cyan
        }
    }
    
    var selectionGradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
