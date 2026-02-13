//
//  HeroHeader.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 20/09/25
//

import SwiftUI

struct HeroHeader: View {
    let configurationSummary: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            Text("Ready?")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
            
            Text("Choose your setup")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text(configurationSummary)
                .font(.system(size: 9).weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.1),
                            lineWidth: 0.5
                        )
                )
                .accessibilityLabel("Current configuration: \(configurationSummary)")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
