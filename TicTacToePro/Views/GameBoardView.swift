//
//  GameBoardView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import SwiftUI
import Combine
import Foundation

// NOTE: This file assumes the existence of:
// - ViewModel, GameViewModel, Board, AIDifficulty, HapticManager, TieMessages, AIWinMessages, AILossMessages
// - Square: ObservableObject with @Published var squareStatus: SquareStatus
// If any of those types/values are different in your project, adapt accordingly.

// MARK: - GameBoardView

struct GameBoardView: View {
    var onExit: () -> Void

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass

    @ObservedObject var viewModel: ViewModel
    @ObservedObject var ticTacToe: GameViewModel

    let gameTypeIsPVP: Bool
    let difficulty: AIDifficulty
    let startingPlayerIsO: Bool

    // Small local state for subtle vibro toggle (if you want to expose)
    @State private var vibro: Bool = false

    // MARK: - Computed helpers

    private var currentPlayer: String { ticTacToe.playerToMove == .x ? "X" : "O" }
    private var headerTitle: String { "Tic Tac Toe" }
    private var headerSubtitle: String {
        if gameTypeIsPVP {
            return "\(currentPlayer)’s move"
        } else {
            return ticTacToe.playerToMove == ticTacToe.aiPlays ? "AI is thinking…" : "Your move"
        }
    }

    private var modeBadgeText: String {
        if gameTypeIsPVP {
            return "PvP"
        } else {
            let aiSide = ticTacToe.aiPlays == .x ? "X" : "O"
            let diff: String = {
                switch difficulty {
                case .easy: return "Easy"
                case .medium: return "Medium"
                case .hard: return "Hard"
                }
            }()
            return "AI: \(aiSide) • \(diff)"
        }
    }

    private var isCompactHeight: Bool {
#if os(iOS)
        return vSizeClass == .compact || UIScreen.main.bounds.height <= 667
#else
        return false
#endif
    }

    private var isWide: Bool {
#if os(macOS) || os(visionOS)
        return true
#else
        return hSizeClass == .regular
#endif
    }

    private var gameOverAlertTitle: String {
        guard ticTacToe.winner != .empty else { return TieMessages.messages.randomElement() ?? "It's a tie! 🤝" }
        if gameTypeIsPVP {
            let winnerMark = ticTacToe.winner == .x ? "X" : "O"
            return "\(winnerMark) won! 🎉"
        } else {
            if ticTacToe.winner == ticTacToe.aiPlays {
                return AIWinMessages.messages.randomElement() ?? "AI won! 😎"
            } else {
                return AILossMessages.messages.randomElement() ?? "You won! 🎉"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        content
            .background(background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear(perform: setupGame)
            .alert(Text(gameOverAlertTitle), isPresented: $ticTacToe.gameOver) {
                Button("Play Again", action: resetForNextRound)
                Button("Leave", action: exitToMenu)
            }
    }

    // MARK: - Layout

    @ViewBuilder
    private var content: some View {
        if isWide {
            HStack(spacing: 24) {
                leftPanel
                    .frame(minWidth: 260, maxWidth: 360)
                board
                rightPanel
                    .frame(minWidth: 220, maxWidth: 320)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        } else {
            VStack(spacing: isCompactHeight ? 8 : 16) {
                header
                    .padding(.top, isCompactHeight ? 2 : 0)
                board
                    .padding(.horizontal, isCompactHeight ? 8 : 16)
                footer
                    .padding(.bottom, isCompactHeight ? 6 : 12)
            }
            .padding(.top, isCompactHeight ? 4 : 12)
        }
    }
}

// MARK: - UI Components

private extension GameBoardView {

    var background: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(.black), Color.purple.opacity(0.28), Color.blue.opacity(0.22)]
                : [Color(.systemBackground), Color.blue.opacity(0.06), Color.purple.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    var leftPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    var rightPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusCard
            footerButtonsOnly
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status").font(.headline)
            Text(headerSubtitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            Divider()

            Text("Mode").font(.headline)
            Text(modeBadgeText)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    var header: some View {
        VStack(spacing: isCompactHeight ? 4 : 8) {
            Text(headerTitle)
                .font(isCompactHeight ? .system(.title, design: .rounded).weight(.bold)
                      : .system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            Text(headerSubtitle)
                .font(isCompactHeight ? .headline : .title3.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(modeBadgeText)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, isCompactHeight ? 8 : 10)
                .padding(.vertical, isCompactHeight ? 4 : 6)
                .background(.thinMaterial, in: Capsule())
                .foregroundStyle(.primary)
        }
        .padding(.horizontal)
    }

    var board: some View {
        GeometryReader { proxy in
            let maxSide = min(proxy.size.width, proxy.size.height)
            let side = min(maxSide, preferredBoardSide(for: proxy.size))
            let spacing: CGFloat = isCompactHeight ? max(6, side * 0.015) : max(8, side * 0.02)
            let cellSize = (side - spacing * 2) / 3

            VStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<3, id: \.self) { column in
                            let index = row * 3 + column
                            if ticTacToe.squares.indices.contains(index) {
                                SquareButtonView(
                                    dataSource: ticTacToe.squares[index],
                                    size: cellSize
                                ) {
                                    self.makeMove(at: index)
                                }
                                // subtle outer shadow for tile separation
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.12),
                                        radius: 6, x: 2, y: 3)
#if os(iOS) || os(visionOS)
                                .hoverEffect(.lift)
#endif
                            } else {
                                Color.clear.frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .padding(spacing)
            .frame(width: side, height: side)
            // Board container: lightweight glass card
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(LinearGradient(
                        colors: [Color.white.opacity(0.36), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing), lineWidth: 1.6)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: 8)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .frame(minHeight: isCompactHeight ? 360 : 420)
        .accessibilityElement(children: .contain)
    }

    var footer: some View {
        HStack(spacing: isCompactHeight ? 8 : 12) {
            Button(action: resetForNextRound) {
                Label("Restart", systemImage: "arrow.counterclockwise.circle.fill")
                    .font(isCompactHeight ? .subheadline : .headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            .accessibilityLabel("Restart game")

            Spacer(minLength: isCompactHeight ? 8 : 12)

            Button(role: .destructive, action: exitToMenu) {
                Label("Exit", systemImage: "xmark.circle.fill")
                    .font(isCompactHeight ? .subheadline : .headline)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Exit to menu")
        }
        .padding(.horizontal, isCompactHeight ? 12 : 16)
        .padding(.top, isCompactHeight ? 2 : 6)
    }

    var footerButtonsOnly: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: resetForNextRound) {
                Label("Restart", systemImage: "arrow.counterclockwise.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)

            Button(role: .destructive, action: exitToMenu) {
                Label("Exit", systemImage: "xmark.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 8)
    }

    // Toolbar
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
#if os(macOS)
        ToolbarItem(placement: .primaryAction) {
            Button(action: resetForNextRound) {
                Label("Restart", systemImage: "arrow.counterclockwise.circle")
            }
            .help("Restart game")
            .keyboardShortcut("r", modifiers: [.command])
        }
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .cancel, action: exitToMenu) {
                Label("Exit", systemImage: "xmark.circle")
            }
            .help("Exit to menu")
            .keyboardShortcut(.escape, modifiers: [])
        }
#else
        ToolbarItem(placement: .topBarLeading) {
            Button(role: .cancel, action: exitToMenu) {
                Label("Exit", systemImage: "xmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Exit to menu")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: resetForNextRound) {
                Label("Restart", systemImage: "arrow.counterclockwise.circle")
            }
            .accessibilityLabel("Restart game")
        }
#endif
    }
}

// MARK: - Actions & Logic

private extension GameBoardView {

    func setupGame() {
        if ticTacToe.squares.allSatisfy({ $0.squareStatus == .empty }) {
            ticTacToe.playerToMove = startingPlayerIsO ? .o : .x
            performInitialAIMoveIfNeeded()
        }
    }

    func makeMove(at index: Int) {
        guard ticTacToe.squares.indices.contains(index) else { return }
        // animation localized to view model changes
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            _ = ticTacToe.makeMove(index: index, gameTypeIsPVP: gameTypeIsPVP, difficulty: difficulty)
        }
        HapticManager.trigger(style: .medium)
    }

    func resetForNextRound() {
        resetGameState()
        performInitialAIMoveIfNeeded()
    }

    func exitToMenu() {
        resetGameState()
        onExit()
    }

    func resetGameState() {
        ticTacToe.resetGame()
        ticTacToe.playerToMove = startingPlayerIsO ? .o : .x
        viewModel.gameOver = false
        viewModel.winner = .empty
    }

    func performInitialAIMoveIfNeeded() {
        guard !gameTypeIsPVP,
              ticTacToe.aiPlays == .x,
              ticTacToe.playerToMove == .x,
              ticTacToe.squares.allSatisfy({ $0.squareStatus == .empty })
        else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let boardMoves = ticTacToe.boardArray
            let testBoard = Board(position: boardMoves, turn: .x)
            let answer = testBoard.bestMove(difficulty: difficulty)
            if answer >= 0 {
                _ = ticTacToe.makeMove(index: answer, gameTypeIsPVP: false, difficulty: difficulty)
            }
        }
    }

    func preferredBoardSide(for size: CGSize) -> CGFloat {
#if os(macOS)
        return min(640, max(420, min(size.width, size.height) * 0.8))
#elseif os(visionOS)
        return min(720, max(480, min(size.width, size.height) * 0.85))
#else
        if hSizeClass == .regular {
            return min(600, max(420, min(size.width, size.height) * 0.9))
        } else {
            if isCompactHeight {
                return min(420, max(340, min(size.width, size.height) * 0.98))
            } else {
                return min(440, max(360, min(size.width, size.height) * 0.95))
            }
        }
#endif
    }
}

// MARK: - Optimized Premium SquareButtonView

private struct SquareButtonView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var dataSource: Square
    let size: CGFloat
    var action: () -> Void

    @State private var isPressed: Bool = false
#if os(macOS)
    @State private var isHovering: Bool = false
#endif

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Tile background: lightweight gradient + single material
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundGradient)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(borderGradient, lineWidth: borderWidth)
                    )
                    // subtle light and dark emboss
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.10), radius: 6, x: 2, y: 3)
                    .overlay(
                        // conditional glow for winning highlight - inexpensive (no blur)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(backgroundGradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                            )
                            .scaleEffect(tileScale)
                            .animation(.easeOut(duration: 0.15), value: dataSource.squareStatus)
                    )
                    .scaleEffect(tileScale)
                    .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: dataSource.squareStatus)

                // Symbol
                Text(symbol)
                    .font(.system(size: size * 0.55, weight: .black, design: .rounded))
                    .foregroundStyle(symbolGradient)
                    .shadow(color: Color.black.opacity(0.22), radius: 6, x: 2, y: 2)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.zero)
                    .contentShape(Rectangle())
            }
            .frame(width: size, height: size)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        // simple gesture to provide quick pressed feedback without heavy animations
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressed {
                    withAnimation(.easeOut(duration: 0.12)) { isPressed = true }
                }
            }
            .onEnded { _ in
                withAnimation(.easeOut(duration: 0.12)) { isPressed = false }
            }
        )
#if os(macOS)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isHovering = hovering }
        }
#endif
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Board square")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(dataSource.squareStatus == .empty ? "Double-tap to place your mark" : "")
    }

    private func handleTap() {
        guard dataSource.squareStatus == .empty else { return }
        action()
    }

    // MARK: - Visual helpers

    private var symbol: String {
        switch dataSource.squareStatus {
        case .x, .xw: return "X"
        case .o, .ow: return "O"
        case .empty: return ""
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
                ? [Color.white.opacity(0.03), Color.gray.opacity(0.06)]
                : [Color.white.opacity(0.8), Color.gray.opacity(0.02)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.22), Color.white.opacity(0.02)]
                : [Color.white.opacity(0.6), Color.white.opacity(0.04)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var winningGlowColor: Color {
        switch dataSource.squareStatus {
        case .xw, .ow: return .green
        default: return .clear
        }
    }

    private var borderWidth: CGFloat { 1.2 }

    private var cornerRadius: CGFloat { max(10, size * 0.08) }

    private var tileScale: CGFloat {
#if os(macOS)
        return isPressed ? 0.98 : (isHovering ? 1.02 : 1.0)
#else
        return isPressed ? 0.96 : 1.0
#endif
    }

    // MARK: - Accessibility

    private var accessibilityValue: String {
        switch dataSource.squareStatus {
        case .x, .xw: return "X"
        case .o, .ow: return "O"
        case .empty: return "Empty"
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ViewModel()
    let model = GameViewModel()
    NavigationStack {
        GameBoardView(
            onExit: {},
            viewModel: viewModel,
            ticTacToe: model,
            gameTypeIsPVP: false,
            difficulty: .hard,
            startingPlayerIsO: false
        )
    }
}
