//
//  GameScoreView.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 01/10/25
//

import SwiftUI

struct GameScoreView: View {
    @Environment(\.colorScheme) private var colorScheme

    let xWins: Int
    let oWins: Int
    let ties: Int
    let currentTurn: String // "X" or "O"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Score")
                    .font(.caption.weight(.semibold))
                Spacer()
                HStack(spacing: 4) {
                    Text("Turn")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text(currentTurn)
                        .font(.system(size: 10).weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.thinMaterial, in: Capsule())
                        .foregroundStyle(.primary)
                        .accessibilityLabel("Current turn")
                        .accessibilityValue(currentTurn)
                }
            }

            HStack(spacing: 6) {
                scorePill(title: "X", value: xWins, gradient: xGradient)
                scorePill(title: "Tie", value: ties, gradient: tieGradient)
                scorePill(title: "O", value: oWins, gradient: oGradient)
            }
        }
        .padding(8)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.12), Color.white.opacity(0.04)]
                            : [Color.black.opacity(0.08), Color.black.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 0.5
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Scoreboard")
    }

    // MARK: - Subviews

    private func scorePill(title: String, value: Int, gradient: LinearGradient) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9).weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.body.weight(.bold))
                .foregroundStyle(gradient)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
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
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.10), Color.white.opacity(0.04)]
                            : [Color.black.opacity(0.06), Color.black.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 0.5
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
    ScrollView {
        VStack(spacing: 12) {
            GameScoreView(xWins: 3, oWins: 2, ties: 1, currentTurn: "X")
            GameScoreView(xWins: 10, oWins: 12, ties: 4, currentTurn: "O")
        }
        .padding()
    }
}
