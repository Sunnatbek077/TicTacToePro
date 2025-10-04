//
//  SquareButtonView.swift
//  TicTacToePro
//

import SwiftUI

struct SquareButtonView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var dataSource: Square
    let size: CGFloat
    let winningIndices: [Int]
    let isRecentlyPlaced: Bool
    let isSELikeSmallScreen: Bool
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    @State private var glowPulse: Bool = false
#if os(macOS)
    @State private var isHovering: Bool = false
#endif
    
    var body: some View {
        Button(action: handleTap) {
            ZStack {
                tileBackground
                symbolView
            }
            .frame(width: size, height: size)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressed {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { isPressed = true }
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { isPressed = false }
            }
        )
#if os(macOS)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { isHovering = hovering }
        }
#endif
        .onAppear {
            if isRecentlyPlaced {
                withAnimation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(dataSource.squareStatus == .empty ? "Double-tap to place your mark" : "")
    }
    
    private func handleTap() {
        guard dataSource.squareStatus == .empty else { return }
        action()
        withAnimation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true)) {
            glowPulse = true
        }
    }
    
    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(backgroundGradient)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderGradient, lineWidth: borderWidth)
            )
            .shadow(
                color: Color.purple.opacity(colorScheme == .dark ? 0.4 : 0.2),
                radius: glowPulse ? 10 : 6,
                x: 0, y: glowPulse ? 4 : 2
            )
            .scaleEffect(tileScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dataSource.squareStatus)
            .animation(.easeInOut(duration: 0.6), value: glowPulse)
    }
    
    private var symbolView: some View {
        let glowGradient = LinearGradient(
            colors: [Color.yellow.opacity(0.9), Color.orange.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return Text(symbol)
            .font(.system(size: size * (isSELikeSmallScreen ? 0.52 : 0.55), weight: .black, design: .rounded))
            .foregroundStyle(symbolGradient)
            .shadow(
                color: winningGlowActive || glowPulse ? Color.yellow.opacity(0.85) : Color.black.opacity(0.25),
                radius: winningGlowActive || glowPulse ? 12 : 4,
                x: 2, y: 2
            )
            .overlay {
                if winningGlowActive || glowPulse {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(glowGradient, lineWidth: 3)
                        .blendMode(.screen)
                }
            }
            .scaleEffect(isRecentlyPlaced ? 1.1 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRecentlyPlaced)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding(.zero)
            .contentShape(Rectangle())
    }
    
    private var symbol: String {
        switch dataSource.squareStatus {
        case .x, .xw: return "X"
        case .o, .ow: return "O"
        case .empty: return ""
        default: return ""
        }
    }
    
    private var winningGlowActive: Bool {
        switch dataSource.squareStatus {
        case .xw, .ow: return true
        default: return false
        }
    }
    
    private var symbolGradient: LinearGradient {
        switch dataSource.squareStatus {
        case .xw, .ow:
            return LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .x:
            return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .o:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.08), Color.white.opacity(0.03)]
                : [Color.white.opacity(0.98), Color.white.opacity(0.92)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.15), Color.white.opacity(0.05)]
                : [Color.purple.opacity(0.1), Color.blue.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderWidth: CGFloat { 1.5 }
    private var cornerRadius: CGFloat { max(8, size * 0.08) }
    
    private var tileScale: CGFloat {
#if os(macOS)
        return isPressed ? 0.98 : (isHovering ? 1.02 : 1.0)
#else
        return isPressed ? 0.96 : 1.0
#endif
    }
    
    private var accessibilityLabel: String {
        "Board square"
    }
    
    private var accessibilityValue: String {
        switch dataSource.squareStatus {
        case .x, .xw: return "X"
        case .o, .ow: return "O"
        case .empty: return "Empty"
        default: return "Empty"
        }
    }
}
