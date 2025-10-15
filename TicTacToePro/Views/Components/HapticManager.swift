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
    // Single source of truth for the Settings toggle
    static let hapticsEnabledKey = "EnableHapticsFeeling"

    // Programmatic control (used by SettingsView)
    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: hapticsEnabledKey)
    }

    // Read current state; defaults to false when key is unset
    private static func isEnabled() -> Bool {
        UserDefaults.standard.bool(forKey: hapticsEnabledKey)
    }

    // MARK: - Public API (Selection / Impact / Notification)
#if os(iOS) || os(tvOS) || os(visionOS)
    static func playSelection(force: Bool = false) {
        guard force || isEnabled() else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        if Thread.isMainThread {
            generator.selectionChanged()
        } else {
            DispatchQueue.main.sync { generator.selectionChanged() }
        }
    }

    static func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, force: Bool = false) {
        guard force || isEnabled() else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        if Thread.isMainThread {
            generator.impactOccurred()
        } else {
            DispatchQueue.main.sync { generator.impactOccurred() }
        }
    }

    static func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType = .success, force: Bool = false) {
        guard force || isEnabled() else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        if Thread.isMainThread {
            generator.notificationOccurred(type)
        } else {
            DispatchQueue.main.sync { generator.notificationOccurred(type) }
        }
    }

    // Backwards-compatible trigger using our custom style enum
    static func trigger(style: HapticFeedbackStyle, override: Bool = false) {
        guard override || isEnabled() else { return }
        let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .soft:   feedbackStyle = .soft
        case .medium: feedbackStyle = .medium
        case .rigid:  feedbackStyle = .rigid
        case .heavy:  feedbackStyle = .heavy
        }
        playImpact(feedbackStyle, force: override)
    }
#else
    // No-op implementations for non-supported platforms
    static func setEnabled(_ enabled: Bool) {}
    static func playSelection(force: Bool = false) {}
    static func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium, force: Bool = false) {}
    static func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType = .success, force: Bool = false) {}
    static func trigger(style: HapticFeedbackStyle, override: Bool = false) {}
#endif
}
