//
//  GameScoreView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 01/10/25.
//

import SwiftUI

struct GameScoreView: View {
    @Environment(\.colorScheme) private var colorScheme

    let xWins: Int
    let oWins: Int
    let ties: Int
    let currentTurn: String // "X" or "O"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Scooreboard")
                    .font(.headline)
                Spacer()
                HStack(spacing: 8) {
                    Text("Turn")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currentTurn)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                        .foregroundStyle(.primary)
                        .accessibilityLabel("Current turn")
                        .accessibilityValue(currentTurn)
                }
            }

            HStack(spacing: 12) {
                scorePill(title: "X", value: xWins, gradient: xGradient)
                scorePill(title: "Tie", value: ties, gradient: tieGradient)
                scorePill(title: "O", value: oWins, gradient: oGradient)
            }
        }
        .padding(16)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.12), Color.white.opacity(0.04)]
                            : [Color.black.opacity(0.08), Color.black.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 1
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Scoreboard")
    }

    // MARK: - Subviews

    private func scorePill(title: String, value: Int, gradient: LinearGradient) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(gradient)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.06), Color.white.opacity(0.02)]
                            : [Color.white.opacity(0.98), Color.white.opacity(0.90)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.10), Color.white.opacity(0.04)]
                            : [Color.black.opacity(0.06), Color.black.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 0.8
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title == "Tie" ? "Ties" : (title == "X" ? "X wins" : "O wins"))
        .accessibilityValue("\(value)")
    }

    // MARK: - Gradients

    private var xGradient: LinearGradient {
        LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var oGradient: LinearGradient {
        LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var tieGradient: LinearGradient {
        LinearGradient(colors: [.gray.opacity(0.6), .gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    VStack(spacing: 16) {
        GameScoreView(xWins: 3, oWins: 2, ties: 1, currentTurn: "X")
        GameScoreView(xWins: 10, oWins: 12, ties: 4, currentTurn: "O")
    }
    .padding()
    .background(
        LinearGradient(colors: [.black, .purple.opacity(0.25), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
    )
}
