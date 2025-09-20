//
//  GameConfigOptions.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import Foundation

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
