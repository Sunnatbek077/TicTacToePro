//
//  StartButton.swift
//  TicTacToePro
//

import SwiftUI

struct StartButton: View {
    enum Role {
        /// Filled, high-contrast. The one action the screen exists for.
        case primary
        /// Quiet. Sits next to a primary without competing with it.
        case secondary
    }

    let isCompactHeightPhone: Bool
    let action: () -> Void
    var buttonName: String = "Start Game"
    var systemImage: String = "play.fill"
    var role: Role = .primary

    /// Optional binding – only trigger success feedback if provided
    var showGameBinding: Binding<Bool>? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                action()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline)
                Text(buttonName)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, 20)
            .foregroundStyle(foreground)
            .background(background)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
            .shadow(
                color: role == .primary
                    ? Color.purple.opacity(colorScheme == .dark ? 0.45 : 0.30)
                    : .clear,
                radius: role == .primary ? 14 : 0,
                x: 0,
                y: role == .primary ? 8 : 0
            )
        }
        .buttonStyle(PressScaleButtonStyle())
        .sensoryFeedback(.success, trigger: showGameBinding?.wrappedValue ?? false)
        // Previously hard-coded to "Start Game" even when the button read
        // "Next", so VoiceOver announced the wrong action on two of three pages.
        .accessibilityLabel(buttonName)
    }

    private var verticalPadding: CGFloat {
        let base: CGFloat = isCompactHeightPhone ? 14 : 18
        return role == .primary ? base : base - 4
    }

    private var foreground: Color {
        switch role {
        case .primary: return .white
        case .secondary: return AppTheme.selectionAccent
        }
    }

    @ViewBuilder
    private var background: some View {
        switch role {
        case .primary:
            // Filled, not outlined. As a translucent outline the primary action
            // read as *less* prominent than the selection chips behind it.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.selectionFill)
        case .secondary:
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    private var borderColor: Color {
        switch role {
        case .primary: return .white.opacity(0.25)
        case .secondary: return AppTheme.selectionAccent.opacity(0.35)
        }
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.indigo, .mint], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        VStack(spacing: 16) {
            StartButton(isCompactHeightPhone: false, action: {}, showGameBinding: .constant(false))
            StartButton(isCompactHeightPhone: false,
                        action: {},
                        buttonName: "Next",
                        systemImage: "chevron.forward",
                        role: .secondary,
                        showGameBinding: .constant(false))
        }
        .padding()
    }
}
