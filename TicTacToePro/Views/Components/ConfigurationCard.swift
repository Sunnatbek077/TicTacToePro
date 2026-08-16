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

    // Broken out of `body` deliberately: inline ternaries over AnyShapeStyle
    // inside a modifier chain push the type-checker into exponential inference.
    private var fill: AnyShapeStyle {
        isSelected ? AnyShapeStyle(AppTheme.selectionFill)
                   : AnyShapeStyle(AppTheme.restingFill(colorScheme))
    }

    private var labelColor: Color {
        isSelected ? .white : AppTheme.restingLabel(colorScheme)
    }

    private var borderColor: Color {
        isSelected ? .white.opacity(0.35) : AppTheme.restingBorder(colorScheme)
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.body.bold())
                // Long localisations ("Schwierigkeit", "Сложность") must shrink
                // rather than truncate inside a fixed-width pill.
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(labelColor)
                .background(shape.fill(fill))
                .overlay(shape.strokeBorder(borderColor, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .animation(.spring(response: 0.15, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Reusable Grid Card
struct SelectionGridCard<Item: Identifiable & Hashable>: View {
    let items: [Item]
    let selected: Item
    let title: (Item) -> String
    let subtitle: (Item) -> String
    var systemImage: (Item) -> String = { _ in "" }
    let onSelect: (Item) -> Void

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    /// With an odd number of options the last cell used to sit alone in the left
    /// column with a hole beside it. Spanning it across both columns keeps the
    /// grid balanced without changing the option count.
    private var hasOrphanedLastItem: Bool { items.count % 2 == 1 }

    private var gridItems: [Item] {
        hasOrphanedLastItem ? Array(items.dropLast()) : items
    }

    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(gridItems) { item in
                    cell(for: item)
                }
            }

            if hasOrphanedLastItem, let last = items.last {
                cell(for: last)
            }
        }
    }

    private func cell(for item: Item) -> some View {
        GridCardItem(
            title: title(item),
            subtitle: subtitle(item),
            systemImage: systemImage(item),
            isSelected: item == selected
        ) {
            onSelect(item)
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
    }
}

struct GridCardItem: View {
    let title: String
    let subtitle: String
    var systemImage: String = ""
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private let cornerRadius: CGFloat = 14

    private var labelColor: Color {
        isSelected ? .white : AppTheme.restingLabel(colorScheme)
    }

    private var subLabelColor: Color {
        isSelected ? Color.white.opacity(0.85) : (colorScheme == .dark ? .secondary : Color(white: 0.35))
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.75)) { action() }
        } label: {
            VStack(spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: 4) {
                    if !systemImage.isEmpty {
                        // SF Symbols instead of emoji: emoji render differently
                        // per OS version, ignore tint, and don't scale with
                        // Dynamic Type the way symbols do.
                        Image(systemName: systemImage)
                            .font(.caption2)
                            .foregroundStyle(subLabelColor)
                    }
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(subLabelColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isSelected
                          ? AnyShapeStyle(AppTheme.selectionFill)
                          : AnyShapeStyle(AppTheme.restingFill(colorScheme)))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.white.opacity(0.35) : AppTheme.restingBorder(colorScheme),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .animation(.spring(response: 0.15, dampingFraction: 0.75), value: isSelected)
    }
}

// MARK: - Section Label
private struct SectionLabel: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Small clarifying line under a section.
private struct SectionFootnote: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            // `.tertiary` at caption2 rendered these almost invisible against
            // the light card. They carry rules the player cannot find anywhere
            // else ("if it runs out, the game is a draw"), so they have to be
            // legible, not decorative.
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
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
                // Title and footnote both follow the mode, so the control always
                // says what it actually does.
                SectionLabel(title: selectedGameMode.symbolSectionTitle)
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
                SectionFootnote(text: selectedGameMode.symbolSectionFootnote)
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
            // No icon here on purpose. Seven board sizes only map to a handful
            // of distinct grid glyphs, so "9×9" ended up sitting next to a
            // `square.grid.3x3` symbol — actively contradicting the label it
            // was decorating. The title already states the size exactly.
            SelectionGridCard(
                items: BoardSize.allCases,
                selected: selectedSize,
                title: { $0.title },
                subtitle: { $0.winConditionText },
                onSelect: { selectedSize = $0 }
            )
            SectionFootnote(text: "Longer lines need more space, so bigger boards ask for more — up to five.")
        }
    }
}

// MARK: - Page 3: Time Limit
struct TimeLimitPage: View {
    @Binding var selectedTimeLimit: TimeLimitOption
    let boardSize: BoardSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "Time Limit")
            // The board's suggested duration says "Recommended" instead of its
            // pace. Pace names repeat across neighbouring durations by design
            // (5 and 10 min are both Rapid), which on screen read as a mistake;
            // this breaks the repetition and explains why that option is
            // preselected.
            SelectionGridCard(
                items: boardSize.timeLimitOptions,
                selected: selectedTimeLimit,
                title: { $0.title },
                subtitle: { $0 == boardSize.recommendedTimeLimit ? "Recommended" : $0.pace },
                systemImage: { $0 == boardSize.recommendedTimeLimit ? "hand.thumbsup.fill" : $0.systemImage },
                onSelect: { selectedTimeLimit = $0 }
            )
            // Neither of these facts was stated anywhere in the UI before.
            SectionFootnote(text: "Covers the whole match, not each move. If it runs out, the game is a draw.")
        }
    }
}

// MARK: - Card Navigation (dots + arrows)
private struct CardNavigationBar: View {
    let pageCount: Int
    @Binding var currentPage: Int

    @Environment(\.layoutDirection) private var layoutDirection

    private var canGoBack: Bool { currentPage > 0 }
    private var canGoForward: Bool { currentPage < pageCount - 1 }

    var body: some View {
        HStack(spacing: 14) {
            arrow(systemName: "chevron.backward",
                  enabled: canGoBack,
                  label: "Previous step") {
                move(by: -1)
            }

            HStack(spacing: 6) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            currentPage = index
                        }
                    } label: {
                        Capsule()
                            .fill(index == currentPage
                                  ? AnyShapeStyle(AppTheme.selectionFill)
                                  : AnyShapeStyle(Color.secondary.opacity(0.35)))
                            .frame(width: index == currentPage ? 20 : 8, height: 8)
                            // Keep the tap target usable even though the dot is small.
                            .contentShape(Rectangle().inset(by: -8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Step \(index + 1) of \(pageCount)")
                    .accessibilityAddTraits(index == currentPage ? [.isButton, .isSelected] : .isButton)
                    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: currentPage)
                }
            }

            arrow(systemName: "chevron.forward",
                  enabled: canGoForward,
                  label: "Next step") {
                move(by: 1)
            }
        }
    }

    private func move(by delta: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            currentPage = min(max(currentPage + delta, 0), pageCount - 1)
        }
    }

    private func arrow(systemName: String,
                       enabled: Bool,
                       label: String,
                       action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(enabled ? AnyShapeStyle(AppTheme.selectionAccent) : AnyShapeStyle(Color.secondary.opacity(0.3)))
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
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

    private let cornerRadius: CGFloat = 22
    static let pageCount = 3

    private var pageHeight: CGFloat {
        #if os(tvOS)
        switch currentPage {
        case 0: return selectedGameMode.isPVP ? 240 : 350
        case 1: return 470
        case 2: return 400
        default: return 470
        }
        #else
        // Tuned against the rendered screens: the first pass left roughly an
        // eighth of the card empty between the last control and the dots.
        switch currentPage {
        case 0:
            return selectedGameMode.isPVP
                ? (isCompactHeightPhone ? 158 : 174)
                : (isCompactHeightPhone ? 246 : 266)
        case 1: return isCompactHeightPhone ? 344 : 374
        case 2: return isCompactHeightPhone ? 256 : 276
        default: return isCompactHeightPhone ? 344 : 374
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

                TimeLimitPage(
                    selectedTimeLimit: $selectedTimeLimit,
                    boardSize: selectedBoardSize
                )
                #if os(tvOS)
                .padding(24)
                #else
                .padding(isCompactHeightPhone ? 12 : 16)
                #endif
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: pageHeight)

            CardNavigationBar(pageCount: Self.pageCount, currentPage: $currentPage)
                .padding(.bottom, 12)
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(borderGradient, lineWidth: 1)
        }
        // The long-press "breathing" scale was removed: the whole card is a
        // container full of buttons, so a gesture on the container competed with
        // its own contents and fired on any slow tap.
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: currentPage)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: selectedGameMode)
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
            selectedTimeLimit: .constant(.twoMinutes),
            currentPage: .constant(0),
            isCompactHeightPhone: false,
            shadowColor: .gray,
            cardBackground: AnyShapeStyle(.ultraThinMaterial)
        )
        .padding(24)
    }
}
