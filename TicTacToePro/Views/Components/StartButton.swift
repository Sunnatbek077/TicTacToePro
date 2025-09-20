//
//  StartButton.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import SwiftUI

struct StartButton: View {
    let isCompactHeightPhone: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                action()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill").imageScale(.large)
                Text("Start Game").font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isCompactHeightPhone ? 10 : 14)
            .padding(.horizontal, 12)
            .shadow(color: Color.accentColor.opacity(0.35), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.glass)
        .padding(.top, isCompactHeightPhone ? 2 : 4)
        .accessibilityLabel("Start game")
        .accessibilityHint("Starts a new game with the selected configuration")
    }
}
