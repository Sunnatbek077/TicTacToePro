//
//  AboutView.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 04/11/2025.
//
//  Changes from iOS version:
//  - FeatureRow (iOS SettingsView component) → inline WatchFeatureRow
//  - NavigationStack removed (parent provides one)
//  - Toolbar xmark button removed (watchOS back swipe handles dismiss)
//  - .largeTitle → .headline, spacing tightened
//  - backgroundGradient removed (transparent, parent bg shows through)
//  - padding reduced for small screen
//

import SwiftUI

// MARK: - About View
struct AboutView: View {

    private let features: [(icon: String, title: String, desc: String)] = [
        ("brain.head.profile", "Smart AI",        "3 difficulty levels"),
        ("person.2.fill",      "Multiplayer",     "Play with friends"),
        ("square.grid.3x3",    "Custom Boards",   "3×3 up to 9×9"),
        ("paintbrush.fill",    "Premium Design",  "Beautiful UI/UX"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                // ── Header ───────────────────────────────────────────
                WatchHeader(icon: "info.circle.fill", title: "About")

                // ── App info ─────────────────────────────────────────
                VStack(spacing: 2) {
                    Text("Tic Tac Pro")
                        .font(.footnote.bold())
                        .foregroundStyle(.primary)
                    Text("Version 1.2.2")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }

                // ── Tagline ──────────────────────────────────────────
                Text("Classic game with stunning visuals, multiplayer & AI.")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)

                // ── Features ─────────────────────────────────────────
                WatchCard(title: "Features") {
                    VStack(spacing: 0) {
                        ForEach(Array(features.enumerated()), id: \.offset) { idx, f in
                            WatchFeatureRow(icon: f.icon, title: f.title, desc: f.desc)
                            if idx < features.count - 1 {
                                WatchDivider()
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }

                // ── Credits ──────────────────────────────────────────
                VStack(spacing: 2) {
                    Text("Made with ❤️ by")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text("Sunnatbek")
                        .font(.footnote.bold())
                        .foregroundStyle(
                            LinearGradient(colors: [.pink, .purple],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .focusable()
    }
}

// MARK: - Watch Feature Row (local, replaces iOS FeatureRow)
private struct WatchFeatureRow: View {
    let icon:  String
    let title: String
    let desc:  String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(colors: [.pink, .purple],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(desc)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 38)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { AboutView() }
}
