//
//  HapticManager.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import UIKit
import Foundation

enum HapticFeedbackStyle {
    case soft, medium, rigid, heavy
}

struct HapticManager {
    static func trigger(style: HapticFeedbackStyle, override: Bool = false) {
#if os(iOS) || os(tvOS) || os(visionOS)
        let vibrationEnabled = UserDefaults.standard.bool(forKey: "vibration")
        guard vibrationEnabled || override else { return }
        
        let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .soft: feedbackStyle = .soft
        case .medium: feedbackStyle = .medium
        case .rigid: feedbackStyle = .rigid
        case .heavy: feedbackStyle = .heavy
        }
        
        let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
        generator.impactOccurred()
#endif
    }
}
