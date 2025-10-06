//
//  HapticsManager.swift
//  TicTacToePro
//
//  Created by Assistant on 06/10/25.
//

import Foundation
import UIKit

struct HapticsManager {
    static let hapticsEnabledKey = "enableHapticFeeling"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: hapticsEnabledKey)
    }

    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: hapticsEnabledKey)
    }

    static func playSelection(force: Bool = false) {
        guard force || isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    static func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, force: Bool = false) {
        guard force || isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType = .success, force: Bool = false) {
        guard force || isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func trigger(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        playImpact(style)
    }
}
