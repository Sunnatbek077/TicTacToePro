//
//  StartButton.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek
//

import SwiftUI

struct StartButton: View {
    let action: () -> Void
    var buttonName: String = "Start Game"
    var showGameBinding: Binding<Bool>? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let gradient = LinearGradient(
        colors: [.pink.opacity(0.8), .purple.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                action()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "play.circle.fill")
                    .imageScale(.medium)
                    .foregroundStyle(gradient)
                
                Text(buttonName)
                    .font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(gradient, lineWidth: 1)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
        .sensoryFeedback(.success, trigger: showGameBinding?.wrappedValue ?? false)
        .accessibilityLabel("Start Game")
        .accessibilityHint("Starts a new game")
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
