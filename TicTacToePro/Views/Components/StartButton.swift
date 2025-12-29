//
//  StartButton.swift
//  TicTacToePro
//

import SwiftUI

struct StartButton: View {
    let isCompactHeightPhone: Bool
    let action: () -> Void
    var buttonName: String = "Start Game"
    
    // Optional binding – only trigger success feedback if provided
    var showGameBinding: Binding<Bool>? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let gradient = LinearGradient(
        colors: [.pink.opacity(0.8), .purple.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        Button {
//            triggerHaptic()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                action()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(gradient)
                
                Text(buttonName)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isCompactHeightPhone ? 14 : 18)
            .padding(.horizontal, 20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(gradient, lineWidth: 1.5)
            )
            .shadow(
                color: .purple.opacity(colorScheme == .dark ? 0.4 : 0.3),
                radius: 12,
                x: 0,
                y: 8
            )
        }
        .buttonStyle(PressScaleButtonStyle())
        // Only apply sensory feedback if binding exists and value becomes true
        .sensoryFeedback(.success, trigger: showGameBinding?.wrappedValue ?? false)
        .accessibilityLabel("Start game")
        .accessibilityHint("Opens board size selector and starts a new game")
    }
    
//    private func triggerHaptic() {
//        let impact = UIImpactFeedbackGenerator(style: .medium)
//        impact.impactOccurred()
//    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.indigo, .mint], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            StartButton(isCompactHeightPhone: false, action: {}, showGameBinding: .constant(false))
            StartButton(isCompactHeightPhone: true, action: {}, buttonName: "Play Now", showGameBinding: .constant(false))
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

