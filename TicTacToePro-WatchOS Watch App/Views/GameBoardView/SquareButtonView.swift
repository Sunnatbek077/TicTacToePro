//
//  SquareButtonView.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//

import SwiftUI

// MARK: - Square Button View
/// A button representing a single square on the Tic-Tac-Toe board
struct SquareButtonView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var dataSource: Square
    let size: CGFloat
    let winningIndices: [Int]
    let isRecentlyPlaced: Bool
    let isSELikeSmallScreen: Bool // Not used on watchOS but kept for compatibility
    let action: () -> Void
    
    var body: some View {
        Button(action: handleTap) {
            ZStack {
                tileBackground
                symbolView
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Board square")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(dataSource.squareStatus == .empty ? "Double-tap to place mark" : "")
    }
    
    // MARK: - Button Action
    /// Handles button tap, executes action if square is empty
    private func handleTap() {
        guard dataSource.squareStatus == .empty else { return }
        action()
    }
    
    // MARK: - Tile Background
    /// Renders the background of the square with a gradient and border
    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(backgroundGradient)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderGradient, lineWidth: borderWidth)
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.12 : 0.08),
                radius: 2,
                x: 0,
                y: 1
            )
    }
    
    // MARK: - Symbol View
    /// Renders the symbol (X or O) with conditional styling
    private var symbolView: some View {
        Text(symbol)
            .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            .foregroundStyle(symbolGradient)
            .shadow(
                color: winningGlowActive ? Color.yellow.opacity(0.4) : Color.black.opacity(0.12),
                radius: winningGlowActive ? 4 : 1
            )
            .scaleEffect(isRecentlyPlaced ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isRecentlyPlaced)
    }
    
    // MARK: - Symbol Logic
    /// Determines the symbol to display based on square status
    private var symbol: String {
        switch dataSource.squareStatus {
        case .x, .xw: return "X"
        case .o, .ow: return "O"
        case .empty: return ""
        }
    }
    
    // MARK: - Winning Glow Logic
    /// Indicates if the square is part of a winning line
    private var winningGlowActive: Bool {
        dataSource.squareStatus == .xw || dataSource.squareStatus == .ow
    }
    
    // MARK: - Gradients
    /// Gradient for the symbol based on square status
    private var symbolGradient: LinearGradient {
        switch dataSource.squareStatus {
        case .xw, .ow:
            return LinearGradient(
                colors: [.green, .teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .x:
            return LinearGradient(
                colors: [.pink, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .o:
            return LinearGradient(
                colors: [.cyan, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [.gray.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    /// Gradient for the background
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.08), Color.white.opacity(0.04)]
                : [Color.white.opacity(0.9), Color.white.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Gradient for the border
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.15), Color.white.opacity(0.08)]
                : [Color.gray.opacity(0.25), Color.gray.opacity(0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Styling Constants
    private var borderWidth: CGFloat { 0.6 } // Thinner for watchOS
    private var cornerRadius: CGFloat { size * 0.15 } // Slightly more rounded
    
    // MARK: - Accessibility Value
    /// Provides accessibility value based on square status
    private var accessibilityValue: String {
        switch dataSource.squareStatus {
        case .x, .xw: return "X"
        case .o, .ow: return "O"
        case .empty: return "Empty"
        }
    }
}
