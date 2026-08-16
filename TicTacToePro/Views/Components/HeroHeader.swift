//
//  HeroHeader.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import SwiftUI

struct HeroHeader: View {
    let isCompactHeightPhone: Bool
    let configurationSummary: String

    @Environment(\.colorScheme) private var colorScheme

    /// Local contrast pad for the title. Sized generously and heavily blurred so
    /// it reads as a soft glow of the page background rather than a visible box.
    private var titleScrim: some View {
        Capsule()
            .fill(scrimColor)
            .blur(radius: 26)
            .padding(.horizontal, -28)
            .padding(.vertical, -14)
    }

    private var scrimColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.55)
            : Color.white.opacity(0.72)
    }

    var body: some View {
        VStack(spacing: isCompactHeightPhone ? 8 : 12) {
            Text("Ready to play?")
                .font(.system(isCompactHeightPhone ? .title : .largeTitle, design: .rounded).weight(.black))
                .foregroundStyle(AppTheme.brand)
                .multilineTextAlignment(.center)
                // A drop shadow alone was not enough: the background's magenta
                // orb drifts, and when it parks behind the title it sits at
                // almost the same luminance as the pink end of the gradient, so
                // the letterforms disappear. This lays down a soft, blurred
                // patch of the system background first, which pulls the local
                // contrast back no matter where the orb happens to be.
                .background(titleScrim)
                .accessibilityAddTraits(.isHeader)

            Text("Choose your setup and start a game.")
                .font(isCompactHeightPhone ? .subheadline : .body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(configurationSummary)
                .font(.footnote.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(
                        Color.secondary.opacity(colorScheme == .dark ? 0.18 : 0.12),
                        lineWidth: 1
                    )
                }
                .accessibilityLabel("Current setup: \(configurationSummary)")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, isCompactHeightPhone ? 4 : 8)
        .padding(.horizontal, 16)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

#Preview {
    VStack(spacing: 32) {
        HeroHeader(isCompactHeightPhone: false,
                   configurationSummary: "You: X vs AI • Easy • 3×3 · 3 in a row • 2 min")
        HeroHeader(isCompactHeightPhone: true,
                   configurationSummary: "Local match • X first • 9×9 · 5 in a row • No clock")
    }
    .padding()
}
