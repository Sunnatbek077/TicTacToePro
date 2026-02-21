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
/// Tek bir yerda aniqlangan — PlayerSelection, GameMode, Difficulty hammasi shu komponentdan foydalanadi
struct SelectionPill: View {
    let label: String
    let isSelected: Bool
    let accentColors: [Color]
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // Gradient bir marta hisoblangan, har render da qayta yaratilmaydi
    private var gradient: LinearGradient {
        LinearGradient(colors: accentColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.body.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                // Background: gradient vs flat color — shadow yo'q (GPU load kamaytirish uchun)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected
                              ? AnyShapeStyle(gradient)
                              : AnyShapeStyle(colorScheme == .dark ? Color(white: 0.18) : Color(white: 0.93))
                        )
                )
                .foregroundStyle(isSelected ? .white : .primary)
                // Overlay faqat isSelected bo'lganda chiziladi
                .overlay(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(gradient, lineWidth: 1.5)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Reusable Grid Card (BoardSize & TimeLimit share this)
struct SelectionGridCard<Item: Identifiable & Hashable>: View {
    let items: [Item]
    let selected: Item
    let title: (Item) -> String
    let subtitle: (Item) -> String
    let color: (Item) -> Color
    let onSelect: (Item) -> Void

    // LazyVGrid emas, oddiy VGrid — item soni oz (max 9), lazy kerak emas
    // ScrollView ichida ScrollView muammosini oldini olish uchun static grid
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items) { item in
                GridCardItem(
                    title: title(item),
                    subtitle: subtitle(item),
                    accentColor: color(item),
                    isSelected: item == selected
                ) {
                    // withAnimation ni tashqariga chiqardik — closure ichida withAnimation = extra render
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
    let accentColor: Color
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private let cornerRadius: CGFloat = 14

    // Computed color bir marta — isSelected va colorScheme ga bog'liq
    private var cardFill: Color {
        if isSelected {
            return colorScheme == .dark ? Color(white: 0.22) : accentColor.opacity(0.09)
        }
        return colorScheme == .dark ? Color(white: 0.14) : .white
    }

    private var borderColor: Color {
        isSelected ? accentColor : Color(white: colorScheme == .dark ? 0.28 : 0.88)
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { action() }
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? accentColor : .primary)

                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? accentColor.opacity(0.75) : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            // Yagona background — shadow YO'Q (shadow eng katta GPU yuki)
            .background(cardFill)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            // scaleEffect olib tashlandi — TabView ichida scaleEffect = har frame recompose
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isSelected)
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
        VStack(alignment: .leading, spacing: 14) {
            // Starting Player
            VStack(alignment: .leading, spacing: 5) {
                SectionLabel(title: "Starting Player")
                HStack(spacing: 10) {
                    ForEach(PlayerOption.allCases, id: \.self) { player in
                        SelectionPill(
                            label: player.rawValue,
                            isSelected: selectedPlayer == player,
                            accentColors: [.pink.opacity(0.9), .purple.opacity(0.9)]
                        ) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                selectedPlayer = player
                            }
                        }
                    }
                }
            }

            // Game Mode
            VStack(alignment: .leading, spacing: 5) {
                SectionLabel(title: "Game Mode")
                HStack(spacing: 10) {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        SelectionPill(
                            label: mode.rawValue,
                            isSelected: selectedGameMode == mode,
                            accentColors: [.purple.opacity(0.9), .blue.opacity(0.9)]
                        ) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                selectedGameMode = mode
                            }
                        }
                    }
                }
            }

            // AI Difficulty (only when AI mode selected)
            if !selectedGameMode.isPVP {
                VStack(alignment: .leading, spacing: 5) {
                    SectionLabel(title: "AI Difficulty")
                    HStack(spacing: 10) {
                        ForEach(DifficultyOption.allCases, id: \.self) { difficulty in
                            SelectionPill(
                                label: difficulty.rawValue,
                                isSelected: selectedDifficulty == difficulty,
                                accentColors: [.blue.opacity(0.9), .cyan.opacity(0.9)]
                            ) {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
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
                color: { $0.color },
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
                color: { $0.color },
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
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)
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

    // Har page o'z fixed height'iga ega — animation yo'q, layout stable
    private var pageHeight: CGFloat {
        switch currentPage {
        case 0:
            return selectedGameMode.isPVP
                ? (isCompactHeightPhone ? 148 : 162)
                : (isCompactHeightPhone ? 218 : 238)
        case 1:
            return isCompactHeightPhone ? 290 : 320
        case 2:
            return isCompactHeightPhone ? 230 : 258
        default:
            return isCompactHeightPhone ? 290 : 320
        }
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
                .padding(isCompactHeightPhone ? 16 : 20)
                .tag(0)

                BoardSizePage(selectedSize: $selectedBoardSize)
                    .padding(isCompactHeightPhone ? 12 : 16)
                    .tag(1)

                TimeLimitPage(selectedTimeLimit: $selectedTimeLimit)
                    .padding(isCompactHeightPhone ? 12 : 16)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            // pageHeight animatsiyasiz o'zgaradi — cardHeight animation = har frame layout pass
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
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
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
        Color(.systemGroupedBackground).ignoresSafeArea()
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
