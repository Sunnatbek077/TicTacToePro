//
//  AppTheme.swift
//  TicTacToePro
//
//  One place for the brand colours. The pink→purple→blue gradient was previously
//  re-declared in StartMenuView, StartButton and HeroHeader with slightly
//  different opacities each time, so the "same" accent rendered three ways.
//

import SwiftUI

enum AppTheme {

    /// Decorative gradient — titles, icons, thin strokes.
    /// Bright and saturated; not safe to put white text on.
    static let brand = LinearGradient(
        colors: [.pink, .purple, .blue],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Fill gradient for selected controls and the primary button.
    ///
    /// Deliberately darker than `brand`: white text on it measures roughly
    /// 4.7:1 to 6.9:1 contrast, so it clears WCAG AA. The bright `brand`
    /// gradient does not, which is why the two are separate.
    static let selectionFill = LinearGradient(
        colors: [
            Color(red: 0.85, green: 0.15, blue: 0.45),
            Color(red: 0.45, green: 0.20, blue: 0.80)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Softer version of `selectionFill` for large surfaces.
    static let selectionFillSoft = LinearGradient(
        colors: [
            Color(red: 0.85, green: 0.15, blue: 0.45).opacity(0.14),
            Color(red: 0.45, green: 0.20, blue: 0.80).opacity(0.14)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let selectionAccent = Color(red: 0.62, green: 0.18, blue: 0.65)

    /// Unselected control fill.
    static func restingFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.17) : Color(white: 0.90)
    }

    /// Unselected control border.
    static func restingBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.30) : Color(white: 0.72)
    }

    /// Text colour on an unselected control.
    static func restingLabel(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.92) : Color(white: 0.15)
    }
}
