//  ConfigurationCard.swift
//  TicTacToePro
//
//  Refactored: cleaner architecture, no duplicate code, better proportions
//

import SwiftUI

// MARK: - Environment Key for Compact Layout
private struct CompactHeightKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isCompactHeight: Bool {
        get { self[CompactHeightKey.self] }
        set { self[CompactHeightKey.self] = newValue }
    }
}

// MARK: - Reusable Selection Button Style
struct SelectionPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.body.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected
                              ? AnyShapeStyle(colorScheme == .dark ? Color(white: 0.88) : Color(white: 0.12))
                              : AnyShapeStyle(colorScheme == .dark ? Color(white: 0.18) : Color(white: 0.80))
                        )
                )
                .foregroundStyle(isSelected
                    ? (colorScheme == .dark ? Color.black : Color.white)
                    : (colorScheme == .dark ? Color.primary : Color(white: 0.15))
                )
                .overlay(
                    Group {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isSelected
                                    ? (colorScheme == .dark ? Color(white: 0.75) : Color(white: 0.18))
                                    : (colorScheme == .dark ? Color.clear : Color(white: 0.60)),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    }
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.15, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Reusable Grid Card
struct SelectionGridCard<Item: Identifiable & Hashable>: View {
    let items: [Item]
    let selected: Item
    let title: (Item) -> String
    let subtitle: (Item) -> String
    let onSelect: (Item) -> Void

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items) { item in
                GridCardItem(
                    title: title(item),
                    subtitle: subtitle(item),
                    isSelected: item == selected
                ) {
                    onSelect(item)
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                }
            }
        }
    }
}

struct GridCardItem: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private let cornerRadius: CGFloat = 14

    private var cardFill: Color {
        if isSelected {
            return colorScheme == .dark ? Color(white: 0.88) : Color(white: 0.12)
        }
        return colorScheme == .dark ? Color(white: 0.14) : Color(white: 0.80)
    }

    private var borderColor: Color {
        if isSelected {
            return colorScheme == .dark ? Color(white: 0.75) : Color(white: 0.18)
        }
        return Color(white: colorScheme == .dark ? 0.28 : 0.60)
    }

    private var labelColor: Color {
        isSelected ? (colorScheme == .dark ? .black : .white) : (colorScheme == .dark ? .primary : Color(white: 0.12))
    }

    private var subLabelColor: Color {
        isSelected
            ? (colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.78))
            : (colorScheme == .dark ? .secondary : Color(white: 0.35))
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.75)) { action() }
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(labelColor)

                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(subLabelColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(cardFill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.15, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Section Label
private struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Page 1: Game Settings
struct GameSettingsPage: View {
    @Binding var selectedPlayer: PlayerOption
    @Binding var selectedGameMode: GameMode
    @Binding var selectedDifficulty: DifficultyOption

    var body: some View {
        VStack(alignment: .leading, spacing: tvOSSpacing) {
            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(title: "Starting Player")
                HStack(spacing: 10) {
                    ForEach(PlayerOption.allCases, id: \.self) { player in
                        SelectionPill(
                            label: player.rawValue,
                            isSelected: selectedPlayer == player
                        ) {
                            withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                                selectedPlayer = player
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                SectionLabel(title: "Game Mode")
                HStack(spacing: 10) {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        SelectionPill(
                            label: mode.rawValue,
                            isSelected: selectedGameMode == mode
                        ) {
                            withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                                selectedGameMode = mode
                            }
                        }
                    }
                }
            }

            if !selectedGameMode.isPVP {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(title: "AI Difficulty")
                    HStack(spacing: 10) {
                        ForEach(DifficultyOption.allCases, id: \.self) { difficulty in
                            SelectionPill(
                                label: difficulty.rawValue,
                                isSelected: selectedDifficulty == difficulty
                            ) {
                                withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                                    selectedDifficulty = difficulty
                                }
                            }
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var tvOSSpacing: CGFloat {
        #if os(tvOS)
        return 22
        #else
        return 14
        #endif
    }
}

// MARK: - Page 2: Board Size
struct BoardSizePage: View {
    @Binding var selectedSize: BoardSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "Board Size")
            SelectionGridCard(
                items: BoardSize.allCases,
                selected: selectedSize,
                title: { $0.title },
                subtitle: { "\($0.emoji) \($0.description)" },
                onSelect: { selectedSize = $0 }
            )
        }
    }
}

// MARK: - Page 3: Time Limit
struct TimeLimitPage: View {
    @Binding var selectedTimeLimit: TimeLimitOption

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "Time Limit")
            SelectionGridCard(
                items: TimeLimitOption.allCases,
                selected: selectedTimeLimit,
                title: { $0.title },
                subtitle: { "\($0.emoji) \($0.description)" },
                onSelect: { selectedTimeLimit = $0 }
            )
        }
    }
}

// MARK: - Page Indicator Dots
private struct PageIndicator: View {
    let pageCount: Int
    let currentPage: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<pageCount, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? Color.primary : Color.secondary.opacity(0.35))
                    .frame(width: i == currentPage ? 18 : 6, height: 6)
                    .animation(.spring(response: 0.2, dampingFraction: 0.75), value: currentPage)
            }
        }
    }
}

// MARK: - Configuration Card
struct ConfigurationCard: View {
    @Binding var selectedPlayer: PlayerOption
    @Binding var selectedGameMode: GameMode
    @Binding var selectedDifficulty: DifficultyOption
    @Binding var selectedBoardSize: BoardSize
    @Binding var selectedTimeLimit: TimeLimitOption
    @Binding var currentPage: Int
    var isCompactHeightPhone: Bool
    var shadowColor: Color
    var cardBackground: AnyShapeStyle

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    private let cornerRadius: CGFloat = 22

    private var pageHeight: CGFloat {
        #if os(tvOS)
        switch currentPage {
        case 0: return selectedGameMode.isPVP ? 200 : 310
        case 1: return 420
        case 2: return 360
        default: return 420
        }
        #else
        switch currentPage {
        case 0:
            return selectedGameMode.isPVP
                ? (isCompactHeightPhone ? 148 : 162)
                : (isCompactHeightPhone ? 248 : 268)
        case 1: return isCompactHeightPhone ? 290 : 320
        case 2: return isCompactHeightPhone ? 230 : 258
        default: return isCompactHeightPhone ? 290 : 320
        }
        #endif
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(colorScheme == .dark ? 0.12 : 0.20),
                .white.opacity(colorScheme == .dark ? 0.04 : 0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                GameSettingsPage(
                    selectedPlayer: $selectedPlayer,
                    selectedGameMode: $selectedGameMode,
                    selectedDifficulty: $selectedDifficulty
                )
                #if os(tvOS)
                .padding(28)
                #else
                .padding(isCompactHeightPhone ? 16 : 20)
                #endif
                .tag(0)

                BoardSizePage(selectedSize: $selectedBoardSize)
                #if os(tvOS)
                .padding(24)
                #else
                .padding(isCompactHeightPhone ? 12 : 16)
                #endif
                .tag(1)

                TimeLimitPage(selectedTimeLimit: $selectedTimeLimit)
                #if os(tvOS)
                .padding(24)
                #else
                .padding(isCompactHeightPhone ? 12 : 16)
                #endif
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: pageHeight)

            PageIndicator(pageCount: 3, currentPage: currentPage)
                .padding(.bottom, 14)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(borderGradient, lineWidth: 1)
        )
        .scaleEffect(isPressed ? 1.015 : 1.0)
        #if !os(tvOS)
        .onLongPressGesture(
            minimumDuration: 0.4,
            pressing: { pressing in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
        #endif
    }
}

// MARK: - Preview
#Preview("Configuration Card") {
    ZStack {
        #if os(tvOS)
        Color.black.opacity(0.9).ignoresSafeArea()
        #else
        Color(.systemGroupedBackground).ignoresSafeArea()
        #endif
        ConfigurationCard(
            selectedPlayer: .constant(.x),
            selectedGameMode: .constant(.ai),
            selectedDifficulty: .constant(.medium),
            selectedBoardSize: .constant(.small),
            selectedTimeLimit: .constant(.tenMinutes),
            currentPage: .constant(0),
            isCompactHeightPhone: false,
            shadowColor: .gray,
            cardBackground: AnyShapeStyle(.ultraThinMaterial)
        )
        .padding(24)
    }
}
