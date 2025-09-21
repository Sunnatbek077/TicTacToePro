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
    
    var body: some View {
        VStack(spacing: isCompactHeightPhone ? 8 : 12) {
            Text("Ready to play?")
                .font(.system(isCompactHeightPhone ? .title : .largeTitle, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
            
            Text("Choose your setup and start a game.")
                .font(isCompactHeightPhone ? .subheadline : .body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text(configurationSummary)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1))
                .accessibilityLabel("Current configuration: \(configurationSummary)")
        }
        .frame(maxWidth: .infinity)
        .padding(.top, isCompactHeightPhone ? 4 : 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
