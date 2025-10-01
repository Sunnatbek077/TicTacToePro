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
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                action()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom)) // Gradient icon for appeal
                Text("Start Game")
                    .font(.headline.bold()) // Bolder font
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isCompactHeightPhone ? 12 : 16) // Slightly taller
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial) // Glass effect
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(colors: [.pink.opacity(0.5), .purple.opacity(0.5)], startPoint: .top, endPoint: .bottom), lineWidth: 2)
            )
            .shadow(color: Color.accentColor.opacity(colorScheme == .dark ? 0.35 : 0.25), radius: 12, x: 0, y: 8) // Adjusted shadow
        }
        .buttonStyle(.plain) // Remove default button style for custom look
        .accessibilityLabel("Start game")
        .accessibilityHint("Starts a new game with the selected configuration")
    }
}

