//  ConfigurationCard.swift
//  TicTacToePro
//
//  Refactored architecture + enhanced design (gradients, colored cards)
//  iOS, tvOS, visionOS optimized — pink/purple gradient selected states
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

// MARK: - Theme Colors
// Screenshotdagi dizayn sistemasiga mos:
// background: #1A1B2E navy, accent: #FF2D9B pink + #A855F7 purple
private enum ThemeColors {
    /// Pink/magenta: title va "Next" button bilan uyg'un asosiy accent
    static let accentPink   = Color(red: 1.0,  green: 0.18, blue: 0.60)
    /// Purple: gradient ikkinchi rangi
    static let accentPurple = Color(red: 0.66, green: 0.33, blue: 0.97)
    /// Tanlanmagan button fill: navy-grey (#2E3058)
    static let unselectedFill = Color(red: 0.18, green: 0.19, blue: 0.35)

    /// Pink → Purple gradient — tanlangan buttonlar uchun
    static var selectedGradient: LinearGradient {
        LinearGradient(
            colors: [accentPink, accentPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Glow effekti uchun (shadow color)
    static var glowColor: Color { accentPink.opacity(0.50) }
}

// MARK: - Selection Pill
struct SelectionPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.body.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(pillBackground)
                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.50))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    @ViewBuilder
    private var pillBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                isSelected
                    ? AnyShapeStyle(ThemeColors.selectedGradient)
                    : AnyShapeStyle(ThemeColors.unselectedFill)
            )
            .shadow(
                color: isSelected ? ThemeColors.glowColor : .clear,
                radius: isSelected ? 14 : 0,
                y: isSelected ? 4 : 0
            )
        #if os(visionOS)
        // visionOS: gradient ustiga ingichka material qatlami — depth uchun
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AnyShapeStyle(.ultraThinMaterial))
                .opacity(0.18)
        )
        #endif
    }
}

// MARK: - Player Pill (Circle style for X/O)
private struct PlayerPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title2.bold())
                .frame(width: 60, height: 60)
                .background(playerBackground)
                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.45))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
    }

    @ViewBuilder
    private var playerBackground: some View {
        Circle()
            .fill(
                isSelected
                    ? AnyShapeStyle(ThemeColors.selectedGradient)
                    : AnyShapeStyle(ThemeColors.unselectedFill)
            )
            .shadow(
                color: isSelected ? ThemeColors.glowColor : .clear,
                radius: isSelected ? 18 : 0
            )
        #if os(visionOS)
        .overlay(
            Circle()
                .fill(AnyShapeStyle(.ultraThinMaterial))
                .opacity(0.18)
        )
        #endif
    }
}

// MARK: - Colored Grid Card
struct SelectionGridCard<Item: Identifiable & Hashable>: View {
    let items: [Item]
    let selected: Item
    let title: (Item) -> String
    let subtitle: (Item) -> String
    let color: (Item) -> Color
    let onSelect: (Item) -> Void

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(items) { item in
                ColoredGridCardItem(
                    title: title(item),
                    subtitle: subtitle(item),
                    accentColor: color(item),
                    isSelected: item == selected
                ) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.4)) { onSelect(item) }
                    #if os(iOS)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    #endif
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 16)
    }
}

struct ColoredGridCardItem: View {
    let title: String
    let subtitle: String
    let accentColor: Color
    let isSelected: Bool
    let action: () -> Void

    private let cornerRadius: CGFloat = 16

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.body.bold())
                    .foregroundColor(isSelected ? .white : accentColor)

                Text(subtitle)
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(
                        isSelected ? Color.white.opacity(0.20) : accentColor.opacity(0.20)
                    ))
                    .foregroundColor(isSelected ? .white.opacity(0.90) : accentColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(cardBackground)
            .overlay(cardBorder)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var cardBackground: some View {
        #if os(visionOS)
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                isSelected
                    ? AnyShapeStyle(ThemeColors.selectedGradient)
                    : AnyShapeStyle(.regularMaterial)
            )
            .shadow(
                color: isSelected ? accentColor.opacity(0.45) : .clear,
                radius: 12
            )
        #else
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                isSelected
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(ThemeColors.unselectedFill)
            )
            .shadow(
                color: isSelected ? accentColor.opacity(0.45) : .black.opacity(0.15),
                radius: isSelected ? 12 : 6,
                y: 3
            )
        #endif
    }

    @ViewBuilder
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                isSelected ? Color.clear : accentColor.opacity(0.25),
                lineWidth: isSelected ? 0 : 1
            )
    }
}

// MARK: - Section Label
private struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Page 1: Game Settings
struct GameSettingsPage: View {
    @Binding var selectedPlayer: PlayerOption
    @Binding var selectedGameMode: GameMode
    @Binding var selectedDifficulty: DifficultyOption

    var body: some View {
        VStack(spacing: platformSpacing) {
            VStack(spacing: 8) {
                SectionLabel(title: "Starting Player")
                HStack(spacing: 12) {
                    ForEach(PlayerOption.allCases, id: \.self) { player in
                        PlayerPill(
                            label: player.rawValue,
                            isSelected: selectedPlayer == player
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPlayer = player
                            }
                        }
                    }
                }
            }

            VStack(spacing: 8) {
                SectionLabel(title: "Game Mode")
                HStack(spacing: 12) {
                    ForEach(GameMode.allCases, id: \.self) { mode in
                        SelectionPill(
                            label: mode.rawValue,
                            isSelected: selectedGameMode == mode
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedGameMode = mode
                            }
                        }
                    }
                }
            }

            if !selectedGameMode.isPVP {
                VStack(spacing: 8) {
                    SectionLabel(title: "AI Difficulty")
                    HStack(spacing: 12) {
                        ForEach(DifficultyOption.allCases, id: \.self) { difficulty in
                            SelectionPill(
                                label: difficulty.rawValue,
                                isSelected: selectedDifficulty == difficulty
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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

    private var platformSpacing: CGFloat {
        #if os(tvOS)
        return 22
        #elseif os(visionOS)
        return 18
        #else
        return 14
        #endif
    }
}

// MARK: - Page 2: Board Size
struct BoardSizePage: View {
    @Binding var selectedSize: BoardSize

    var body: some View {
        VStack(spacing: 8) {
            SectionLabel(title: "Board Size")
            ScrollView(.vertical, showsIndicators: false) {
                SelectionGridCard(
                    items: BoardSize.allCases,
                    selected: selectedSize,
                    title: { $0.title },
                    subtitle: { $0.difficulty },
                    color: { $0.color },
                    onSelect: { selectedSize = $0 }
                )
            }
        }
    }
}

// MARK: - Page 3: Time Limit
struct TimeLimitPage: View {
    @Binding var selectedTimeLimit: TimeLimitOption

    var body: some View {
        VStack(spacing: 8) {
            SectionLabel(title: "Time Limit")
            ScrollView(.vertical, showsIndicators: false) {
                SelectionGridCard(
                    items: TimeLimitOption.allCases,
                    selected: selectedTimeLimit,
                    title: { $0.title },
                    subtitle: { $0.description },
                    color: { $0.color },
                    onSelect: { selectedTimeLimit = $0 }
                )
            }
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
                    .fill(
                        i == currentPage
                            ? AnyShapeStyle(ThemeColors.selectedGradient)
                            : AnyShapeStyle(Color.white.opacity(0.20))
                    )
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

    @State private var isPressed = false

    private let cornerRadius: CGFloat = 24

    // MARK: - Page Height
    private var pageHeight: CGFloat {
        #if os(visionOS)
        switch currentPage {
        case 0: return selectedGameMode.isPVP ? 180 : 290
        case 1: return 380
        case 2: return 320
        default: return 380
        }
        #elseif os(tvOS)
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
        case 1:
            return isCompactHeightPhone ? 290 : 320
        case 2:
            return isCompactHeightPhone ? 230 : 258
        default:
            return isCompactHeightPhone ? 290 : 320
        }
        #endif
    }

    // MARK: - Card Border Gradient
    private var borderGradient: LinearGradient {
        #if os(visionOS)
        return LinearGradient(
            colors: [.white.opacity(0.25), .white.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        #else
        return LinearGradient(
            colors: [.white.opacity(0.12), .white.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        #endif
    }

    // MARK: - Page Padding
    private var pagePadding: CGFloat {
        #if os(visionOS)
        return 22
        #elseif os(tvOS)
        return 28
        #else
        return isCompactHeightPhone ? 16 : 24
        #endif
    }

    // MARK: - Resolved Background
    // visionOS da cardBackground bekor qilinadi — .regularMaterial ishlatiladi
    private var resolvedBackground: AnyShapeStyle {
        #if os(visionOS)
        return AnyShapeStyle(.regularMaterial)
        #else
        return cardBackground
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                GameSettingsPage(
                    selectedPlayer: $selectedPlayer,
                    selectedGameMode: $selectedGameMode,
                    selectedDifficulty: $selectedDifficulty
                )
                .padding(pagePadding)
                .tag(0)

                BoardSizePage(selectedSize: $selectedBoardSize)
                    .padding(pagePadding)
                    .tag(1)

                TimeLimitPage(selectedTimeLimit: $selectedTimeLimit)
                    .padding(pagePadding)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: pageHeight)

            PageIndicator(pageCount: 3, currentPage: currentPage)
                .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(resolvedBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(borderGradient, lineWidth: 1)
                )
        )
        .overlay(
            // Press feedback: pink glow border
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    ThemeColors.accentPink.opacity(isPressed ? 0.60 : 0),
                    lineWidth: 3
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPressed)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .scaleEffect(isPressed ? 1.015 : 1.0)
        #if !os(tvOS) && !os(visionOS)
        .onLongPressGesture(
            minimumDuration: 0.5,
            pressing: { pressing in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
        #elseif os(visionOS)
        .hoverEffect(.highlight)
        #endif
    }
}

// MARK: - Preview
#Preview("Configuration Card") {
    ZStack {
        #if os(tvOS) || os(iOS) || os(macOS)
        // Screenshotdagi navy background
        Color(red: 0.10, green: 0.11, blue: 0.18).ignoresSafeArea()
        #elseif os(visionOS)
        Color.clear.ignoresSafeArea()
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
            cardBackground: AnyShapeStyle(Color(red: 0.15, green: 0.15, blue: 0.24))
        )
        .padding(24)
    }
}
