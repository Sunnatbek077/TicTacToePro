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

// Platform-agnostic stand-ins so non-iOS platforms don't see UIKit-only types
enum HapticNotificationType {
    case success, warning, error
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
#if os(iOS) || os(visionOS)
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

    // Convenience shims to map platform-agnostic enums to UIKit-only types on supported OSes
    static func playImpact(_ style: HapticFeedbackStyle, force: Bool = false) {
        let mapped: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .soft: mapped = .soft
        case .medium: mapped = .medium
        case .rigid: mapped = .rigid
        case .heavy: mapped = .heavy
        }
        playImpact(mapped, force: force)
    }

    static func playNotification(_ type: HapticNotificationType, force: Bool = false) {
        let mapped: UINotificationFeedbackGenerator.FeedbackType
        switch type {
        case .success: mapped = .success
        case .warning: mapped = .warning
        case .error: mapped = .error
        }
        playNotification(mapped, force: force)
    }
#else
    // No-op implementations for platforms without UIFeedbackGenerator (e.g., tvOS, macOS, watchOS)
    static func playSelection(force: Bool = false) {}

    // Avoid referencing UIKit-only types here
    static func playImpact(_ style: HapticFeedbackStyle = .medium, force: Bool = false) {}

    static func playNotification(_ type: HapticNotificationType = .success, force: Bool = false) {}

    static func trigger(style: HapticFeedbackStyle, override: Bool = false) {}
#endif
}
