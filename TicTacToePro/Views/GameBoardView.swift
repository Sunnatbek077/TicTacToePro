//
//  GameBoardView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//  Updated with enhanced premium design on 01/10/25
//

import SwiftUI
import Combine
import Foundation

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
    
    // Local (session-only) scoreboard
    @State private var xWins: Int = 0
    @State private var oWins: Int = 0
    @State private var ties: Int = 0
    
    // Local transient states
    @State private var vibro: Bool = false
    @State private var showTurnBanner: Bool = false
    @State private var showConfetti: Bool = false
    @State private var aiThinking: Bool = false
    @State private var animateWinningGlow: Bool = false
    @State private var recentlyPlacedIndex: Int? = nil
    @State private var animateBoardEntrance: Bool = false
    
    // MARK: - Computed helpers
    
    private var currentPlayer: String { ticTacToe.playerToMove == .x ? "X" : "O" }
    private var headerTitle: String { "Tic Tac Toe" }
    private var headerSubtitle: String {
        if gameTypeIsPVP {
            return "\(currentPlayer)’s Move"
        } else {
            return ticTacToe.playerToMove == ticTacToe.aiPlays ? "AI is Thinking…" : "Your Move"
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
        guard ticTacToe.winner != .empty else { return TieMessages.messages.randomElement() ?? "It's a Tie! 🤝" }
        if gameTypeIsPVP {
            let winnerMark = ticTacToe.winner == .x ? "X" : "O"
            return "\(winnerMark) Won! 🎉"
        } else {
            if ticTacToe.winner == ticTacToe.aiPlays {
                return AIWinMessages.messages.randomElement() ?? "AI Won! 😎"
            } else {
                return AILossMessages.messages.randomElement() ?? "You Won! 🎉"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            premiumBackground
                .ignoresSafeArea()
            
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        animateBoardEntrance = true
                    }
                    setupGame()
                }
                .onChange(of: ticTacToe.gameOver) { handleGameOverChanged($1) }
                .onChange(of: ticTacToe.playerToMove) { _ in handlePlayerToMoveChanged() }
                .alert(Text(gameOverAlertTitle), isPresented: $ticTacToe.gameOver) {
                    Button("Play Again", action: resetForNextRound)
                    Button("Leave", action: exitToMenu)
                }
            
            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
                    .zIndex(3)
            }
            
            if showTurnBanner {
                turnBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
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
                GameScoreView(
                    xWins: xWins,
                    oWins: oWins,
                    ties: ties,
                    currentTurn: currentPlayer
                )
                .padding(.horizontal, isCompactHeight ? 8 : 16)
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
    
    var premiumBackground: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.11, green: 0.12, blue: 0.18), Color(red: 0.03, green: 0.04, blue: 0.06)]
                    : [Color(red: 0.98, green: 0.98, blue: 1.0), Color(red: 0.95, green: 0.96, blue: 0.99), Color(red: 0.90, green: 0.92, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Rectangle()
                .fill(LinearGradient(colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.02 : 0.08),
                    Color.black.opacity(colorScheme == .dark ? 0.02 : 0.01)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                .blendMode(.overlay)
                .opacity(0.6)
                .ignoresSafeArea()
            
            LinearGradient(
                colors: [Color.black.opacity(colorScheme == .dark ? 0.35 : 0.15), .clear, Color.black.opacity(colorScheme == .dark ? 0.35 : 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            NoiseTextureView()
                .opacity(colorScheme == .dark ? 0.05 : 0.03)
                .ignoresSafeArea()
            
            // Bokeh effect for premium look
            ZStack {
                Circle().fill(colorScheme == .dark ? Color.pink : Color.pink.opacity(0.25))
                    .frame(width: 220).blur(radius: 60).offset(x: -140, y: -180)
                Circle().fill(colorScheme == .dark ? Color.blue : Color.blue.opacity(0.22))
                    .frame(width: 260).blur(radius: 70).offset(x: 160, y: -120)
                Circle().fill(colorScheme == .dark ? Color.purple : Color.purple.opacity(0.24))
                    .frame(width: 280).blur(radius: 80).offset(x: 120, y: 220)
                Circle().fill(colorScheme == .dark ? Color.cyan.opacity(0.8) : Color.cyan.opacity(0.18))
                    .frame(width: 150).blur(radius: 50).offset(x: -80, y: 180)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateBoardEntrance)
        }
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
            GameScoreView(
                xWins: xWins,
                oWins: oWins,
                ties: ties,
                currentTurn: currentPlayer
            )
            statusCard
            footerButtonsOnly
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
    
    var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing))
            Text(headerSubtitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Divider()
            
            Text("Mode")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
            Text(modeBadgeText)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom), lineWidth: 1))
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.pink.opacity(0.3), .purple.opacity(0.3)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
        .shadow(color: Color.purple.opacity(colorScheme == .dark ? 0.4 : 0.2), radius: 8, x: 0, y: 4)
    }
    
    var header: some View {
        VStack(spacing: isCompactHeight ? 4 : 8) {
            Text(headerTitle)
                .font(isCompactHeight ? .system(.title, design: .rounded).weight(.black) : .system(.largeTitle, design: .rounded).weight(.black))
                .foregroundStyle(LinearGradient(colors: [.pink, .purple, .blue], startPoint: .leading, endPoint: .trailing))
                .accessibilityAddTraits(.isHeader)
            
            Text(headerSubtitle)
                .font(isCompactHeight ? .headline : .title3.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Text(modeBadgeText)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, isCompactHeight ? 8 : 12)
                .padding(.vertical, isCompactHeight ? 4 : 6)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom), lineWidth: 1))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .gray.opacity(0.1), radius: 8)
        )
    }
    
    var board: some View {
        GeometryReader { proxy in
            let maxSide = min(proxy.size.width, proxy.size.height)
            let side = min(maxSide, preferredBoardSide(for: proxy.size))
            let spacing: CGFloat = isCompactHeight ? max(6, side * 0.015) : max(8, side * 0.02)
            let cellSize = max(60, (side - spacing * 2) / 3)
            
            VStack(spacing: spacing) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<3, id: \.self) { column in
                            let index = row * 3 + column
                            if ticTacToe.squares.indices.contains(index) {
                                SquareButtonView(
                                    dataSource: ticTacToe.squares[index],
                                    size: cellSize,
                                    winningIndices: detectWinningIndices(),
                                    isRecentlyPlaced: recentlyPlacedIndex == index
                                ) {
                                    self.makeMove(at: index)
                                    recentlyPlacedIndex = index
                                }
                                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.purple.opacity(0.2), radius: 8, x: 2, y: 2)
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
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 28, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color.white.opacity(0.15), Color.white.opacity(0.05)]
                                : [Color.purple.opacity(0.1), Color.blue.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 1.5
                    )
            )
            .shadow(color: Color.purple.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 12, x: 0, y: 6)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .scaleEffect(animateBoardEntrance ? 1.0 : 0.9)
            .opacity(animateBoardEntrance ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateBoardEntrance)
            .accessibilityElement(children: .contain)
        }
        .frame(minHeight: isCompactHeight ? 360 : 420)
    }
    
    var footer: some View {
        HStack(spacing: isCompactHeight ? 8 : 12) {
            Button(action: resetForNextRound) {
                Label("Restart", systemImage: "arrow.counterclockwise.circle.fill")
                    .font(isCompactHeight ? .subheadline : .headline)
                    .padding(.vertical, isCompactHeight ? 10 : 12)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LinearGradient(colors: [.pink.opacity(0.5), .purple.opacity(0.5)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .accessibilityLabel("Restart game")
            .accessibilityHint("Starts a new round immediately")
            
            Spacer(minLength: isCompactHeight ? 8 : 12)
            
            Button(role: .destructive, action: exitToMenu) {
                Label("Exit", systemImage: "xmark.circle.fill")
                    .font(isCompactHeight ? .subheadline : .headline)
                    .padding(.vertical, isCompactHeight ? 10 : 12)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LinearGradient(colors: [.red.opacity(0.5), .orange.opacity(0.5)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .accessibilityLabel("Exit to menu")
            .accessibilityHint("Return to the main menu")
        }
        .padding(.horizontal, isCompactHeight ? 12 : 16)
        .padding(.top, isCompactHeight ? 2 : 6)
    }
    
    var footerButtonsOnly: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: resetForNextRound) {
                Label("Restart", systemImage: "arrow.counterclockwise.circle.fill")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LinearGradient(colors: [.pink.opacity(0.5), .purple.opacity(0.5)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            
            Button(role: .destructive, action: exitToMenu) {
                Label("Exit", systemImage: "xmark.circle.fill")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LinearGradient(colors: [.red.opacity(0.5), .orange.opacity(0.5)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
        }
        .padding(.top, 8)
    }
    
    var turnBanner: some View {
        HStack {
            if ticTacToe.playerToMove == ticTacToe.aiPlays && !gameTypeIsPVP {
                Label("AI is Thinking…", systemImage: "brain.head.profile")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom), lineWidth: 1))
                    .shadow(color: .purple.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 6)
                    .accessibilityLabel("AI is thinking")
            } else {
                Label("\(currentPlayer)’s Turn", systemImage: ticTacToe.playerToMove == .x ? "xmark" : "circle")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom), lineWidth: 1))
                    .shadow(color: .purple.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 6)
                    .accessibilityLabel("\(currentPlayer) turn")
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
    }
    
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
                    .foregroundStyle(LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
                    .accessibilityLabel("Exit to menu")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: resetForNextRound) {
                Label("Restart", systemImage: "arrow.counterclockwise.circle.fill")
                    .labelStyle(.iconOnly)
                    .imageScale(.large)
                    .foregroundStyle(LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom))
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
            bannerShowTemporarily()
        }
    }
    
    func makeMove(at index: Int) {
        guard ticTacToe.squares.indices.contains(index) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            _ = ticTacToe.makeMove(index: index, gameTypeIsPVP: gameTypeIsPVP, difficulty: difficulty)
        }
        HapticManager.trigger(style: .soft)
        bannerShowTemporarily()
    }
    
    func resetForNextRound() {
        resetGameState()
        performInitialAIMoveIfNeeded()
        bannerShowTemporarily()
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
        showConfetti = false
        aiThinking = false
        animateWinningGlow = false
        recentlyPlacedIndex = nil
    }
    
    func performInitialAIMoveIfNeeded() {
        guard !gameTypeIsPVP,
              ticTacToe.aiPlays == .x,
              ticTacToe.playerToMove == .x,
              ticTacToe.squares.allSatisfy({ $0.squareStatus == .empty })
        else { return }
        
        aiThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            let boardMoves = ticTacToe.boardArray
            let testBoard = Board(position: boardMoves, turn: .x)
            let answer = testBoard.bestMove(difficulty: difficulty)
            if answer >= 0 {
                _ = ticTacToe.makeMove(index: answer, gameTypeIsPVP: false, difficulty: difficulty)
                recentlyPlacedIndex = answer
            }
            withAnimation { aiThinking = false }
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
    
    func handleGameOverChanged(_ isOver: Bool) {
        guard isOver else { return }
        if ticTacToe.winner == .x {
            xWins += 1
            HapticManager.trigger(style: .heavy)
        } else if ticTacToe.winner == .o {
            oWins += 1
            HapticManager.trigger(style: .heavy)
        } else {
            ties += 1
            HapticManager.trigger(style: .medium)
        }
        
        if ticTacToe.winner != .empty {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showConfetti = true
                animateWinningGlow = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut) { showConfetti = false }
            }
        }
        
        bannerShowTemporarily()
    }
    
    func handlePlayerToMoveChanged() {
        if !gameTypeIsPVP && ticTacToe.playerToMove == ticTacToe.aiPlays {
            withAnimation(.spring()) { aiThinking = true }
        } else {
            withAnimation(.spring()) { aiThinking = false }
        }
    }
    
    func bannerShowTemporarily() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showTurnBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut) { showTurnBanner = false }
        }
    }
    
    func detectWinningIndices() -> [Int] {
        let statuses = ticTacToe.squares.map { $0.squareStatus }
        func allEqualAndNotEmpty(_ idxs: [Int]) -> Bool {
            guard let first = statuses[idxs[0]] as? AnyHashable else { return false }
            if "\(first)" == "\(SquareStatus.empty)" { return false }
            let base = statuses[idxs[0]]
            return idxs.allSatisfy { statuses[$0] == base }
        }
        
        let lines = [
            [0,1,2], [3,4,5], [6,7,8], // rows
            [0,3,6], [1,4,7], [2,5,8], // cols
            [0,4,8], [2,4,6]           // diags
        ]
        
        for line in lines {
            if line.allSatisfy({ $0 >= 0 && $0 < statuses.count }) {
                if allEqualAndNotEmpty(line) {
                    return line
                }
            }
        }
        return []
    }
}

// MARK: - Optimized Premium SquareButtonView

private struct SquareButtonView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var dataSource: Square
    let size: CGFloat
    let winningIndices: [Int]
    let isRecentlyPlaced: Bool
    var action: () -> Void
    
    @State private var isPressed: Bool = false
    @State private var glowPulse: Bool = false
#if os(macOS)
    @State private var isHovering: Bool = false
#endif
    
    var body: some View {
        Button(action: handleTap) {
            ZStack {
                tileBackground
                symbolView
            }
            .frame(width: size, height: size)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressed {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { isPressed = true }
                }
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { isPressed = false }
            }
        )
#if os(macOS)
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) { isHovering = hovering }
        }
#endif
        .onAppear {
            if isRecentlyPlaced {
                withAnimation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(dataSource.squareStatus == .empty ? "Double-tap to place your mark" : "")
    }
    
    private func handleTap() {
        guard dataSource.squareStatus == .empty else { return }
        action()
        withAnimation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true)) {
            glowPulse = true
        }
    }
    
    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(backgroundGradient)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderGradient, lineWidth: borderWidth)
            )
            .shadow(
                color: Color.purple.opacity(colorScheme == .dark ? 0.4 : 0.2),
                radius: glowPulse ? 12 : 8,
                x: 0, y: glowPulse ? 6 : 4
            )
            .scaleEffect(tileScale)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dataSource.squareStatus)
            .animation(.easeInOut(duration: 0.6), value: glowPulse)
    }
    
    private var symbolView: some View {
        let glowGradient = LinearGradient(
            colors: [Color.yellow.opacity(0.9), Color.orange.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return Text(symbol)
            .font(.system(size: size * 0.55, weight: .black, design: .rounded))
            .foregroundStyle(symbolGradient)
            .shadow(
                color: winningGlowActive || glowPulse ? Color.yellow.opacity(0.85) : Color.black.opacity(0.25),
                radius: winningGlowActive || glowPulse ? 18 : 6,
                x: 2, y: 2
            )
            .overlay {
                if winningGlowActive || glowPulse {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(glowGradient, lineWidth: 4)
                        .blendMode(.screen)
                }
            }
            .scaleEffect(isRecentlyPlaced ? 1.1 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRecentlyPlaced)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding(.zero)
            .contentShape(Rectangle())
    }
    
    private var symbol: String {
        switch dataSource.squareStatus {
        case .x, .xw: return "X"
        case .o, .ow: return "O"
        case .empty: return ""
        default: return ""
        }
    }
    
    private var winningGlowActive: Bool {
        switch dataSource.squareStatus {
        case .xw, .ow: return true
        default: return false
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
                ? [Color.white.opacity(0.08), Color.white.opacity(0.03)]
                : [Color.white.opacity(0.98), Color.white.opacity(0.92)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.15), Color.white.opacity(0.05)]
                : [Color.purple.opacity(0.1), Color.blue.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderWidth: CGFloat { 1.5 }
    private var cornerRadius: CGFloat { max(12, size * 0.12) }
    
    private var tileScale: CGFloat {
#if os(macOS)
        return isPressed ? 0.98 : (isHovering ? 1.02 : 1.0)
#else
        return isPressed ? 0.96 : 1.0
#endif
    }
    
    private var accessibilityValue: String {
        switch dataSource.squareStatus {
        case .x, .xw: return "X"
        case .o, .ow: return "O"
        case .empty: return "Empty"
        default: return "Empty"
        }
    }
    
    private var accessibilityLabel: String {
        "Board square"
    }
}

// MARK: - Enhanced Confetti View

private struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = (0..<40).map { _ in ConfettiParticle.random() }
    @State private var t: Double = 0.0
    
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                ctx.addFilter(.blur(radius: 2))
                for i in particles.indices {
                    var p = particles[i]
                    let x = p.startX * size.width + p.dx * t
                    let y = p.startY * size.height + p.dy * t + 0.5 * p.gravity * t * t
                    let rect = CGRect(x: x, y: y, width: p.size, height: p.size)
                    ctx.fill(Path(ellipseIn: rect), with: .color(p.color.opacity(1.0 - t * 0.3)))
                }
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeOut(duration: 2.2)) {
                    t = 2.2
                }
            }
        }
    }
}

private struct ConfettiParticle {
    var startX: Double
    var startY: Double
    var dx: Double
    var dy: Double
    var gravity: Double
    var size: CGFloat
    var color: Color
    
    static func random() -> ConfettiParticle {
        ConfettiParticle(
            startX: Double.random(in: 0.1...0.9),
            startY: Double.random(in: -0.1...0.2),
            dx: Double.random(in: -0.8...0.8) * 400,
            dy: Double.random(in: 0.3...1.2) * 400,
            gravity: Double.random(in: 150...500),
            size: CGFloat.random(in: 8...20),
            color: [Color.red, Color.green, Color.blue, Color.yellow, Color.purple, Color.orange, Color.pink, Color.cyan].randomElement() ?? Color.red
        )
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
