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
    
    var body: some View {
        VStack(spacing: isCompactHeightPhone ? 8 : 12) {
            Text("Ready to play?")
                .font(.system(isCompactHeightPhone ? .title : .largeTitle, design: .rounded).weight(.black)) // Heavier weight for impact
                .foregroundStyle(LinearGradient(colors: [.pink, .purple, .blue], startPoint: .leading, endPoint: .trailing)) // Gradient text
                .multilineTextAlignment(.center)
            
            Text("Choose your setup and start a game.")
                .font(isCompactHeightPhone ? .subheadline : .body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text(configurationSummary)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule()) // Updated to ultraThinMaterial for consistency
                .overlay(Capsule().strokeBorder(Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.1), lineWidth: 1)) // Softer stroke
                .accessibilityLabel("Current configuration: \(configurationSummary)")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, isCompactHeightPhone ? 4 : 8)
        .padding(.horizontal, 16) // Added horizontal padding for better framing
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.clear).shadow(color: .gray.opacity(0.1), radius: 8)) // Subtle container shadow
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
