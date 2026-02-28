//
//  ConfigurationCard.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 20/09/25.
//
//  watchOS Design principles applied:
//  - Base font: .footnote / .caption2 (never exceed .headline inside cards)
//  - Touch targets: min 44×44 pt (even on 40 mm watch)
//  - Spacing: tight but breathable – 4-8 pt between siblings
//  - Avoid LazyVGrid where HStack suffices (less layout overhead)
//  - Digital Crown scrolling via .focusable() on outer ScrollView
//

import SwiftUI

// MARK: - Root Card
struct ConfigurationCard: View {
    @Binding var selectedPlayer: PlayerOption
    @Binding var selectedGameMode: GameMode
    @Binding var selectedDifficulty: DifficultyOption
    @Binding var selectedBoardSize: BoardSize

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                SectionRow(label: "Player") {
                    PlayerPicker(selected: $selectedPlayer)
                }
                Divider().opacity(0.3)

                SectionRow(label: "Mode") {
                    GameModePicker(selected: $selectedGameMode)
                }

                if !selectedGameMode.isPVP {
                    Divider().opacity(0.3)
                    SectionRow(label: "Difficulty") {
                        DifficultyPicker(selected: $selectedDifficulty)
                    }
                }

                Divider().opacity(0.3)
                BoardSizePicker(selected: $selectedBoardSize)

                Divider().opacity(0.3)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
        .focusable()
    }
}

// MARK: - Generic section wrapper
private struct SectionRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)
            content()
        }
    }
}

// MARK: - Player Picker  (X / O chips)
private struct PlayerPicker: View {
    @Binding var selected: PlayerOption

    var body: some View {
        HStack(spacing: 8) {
            ForEach(PlayerOption.allCases, id: \.self) { option in
                ChipButton(
                    label: option.rawValue,
                    isSelected: selected == option,
                    accentColors: [.pink, .purple]
                ) {
                    selected = option
                }
                .frame(width: 44, height: 36)
            }
            Spacer()
        }
    }
}

// MARK: - Game Mode Picker  (AI / PvP)
private struct GameModePicker: View {
    @Binding var selected: GameMode

    var body: some View {
        HStack(spacing: 6) {
            ForEach(GameMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selected = mode }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 12))
                        Text(mode.rawValue)
                            .font(.footnote).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 9)
                            .fill(selected == mode ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(.ultraThinMaterial))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(
                                selected == mode
                                    ? LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing),
                                lineWidth: 1.5
                            )
                    )
                    .foregroundStyle(selected == mode ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(mode.rawValue) mode")
            }
        }
    }
}

// MARK: - Difficulty Picker  (3 chips in one row)
private struct DifficultyPicker: View {
    @Binding var selected: DifficultyOption

    var body: some View {
        HStack(spacing: 6) {
            ForEach(DifficultyOption.allCases, id: \.self) { diff in
                ChipButton(
                    label: diff.rawValue,
                    isSelected: selected == diff,
                    accentColors: difficultyColors(diff)
                ) {
                    selected = diff
                }
            }
        }
    }

    private func difficultyColors(_ d: DifficultyOption) -> [Color] {
        switch d {
        case .easy:   return [.green, .mint]
        case .medium: return [.orange, .yellow]
        case .hard:   return [.red, .pink]
        }
    }
}

// MARK: - Board Size Picker  (scrollable horizontal strip)
private struct BoardSizePicker: View {
    @Binding var selected: BoardSize

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Board")
                .font(.caption2).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(BoardSize.allCases) { size in
                        BoardSizeChip(size: size, isSelected: selected == size) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selected = size
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

private struct BoardSizeChip: View {
    let size: BoardSize
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(size.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isSelected ? size.color : .primary)
                Text(size.difficulty)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(size.color)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(size.color.opacity(0.18)))
            }
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color(white: isSelected ? 0.22 : 0.14).opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(
                        isSelected ? LinearGradient(colors: [size.color, size.color.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                                   : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}



// MARK: - Reusable chip button
private struct ChipButton: View {
    let label: String
    let isSelected: Bool
    let accentColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.18)) { action() }
        }) {
            Text(label)
                .font(.footnote).fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isSelected
                                ? AnyShapeStyle(LinearGradient(colors: accentColors.map { $0.opacity(0.85) }, startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Color(white: 0.18).opacity(0.8))
                        )
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isSelected
                                ? LinearGradient(colors: accentColors, startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.5
                        )
                )
                .scaleEffect(isSelected ? 1.04 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
