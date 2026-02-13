//
//  GameBoardComponents.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 04/10/25.
//

import SwiftUI

extension GameBoardView {
    
    // MARK: - Background (Simplified for watchOS)
    var premiumBackground: some View {
        ZStack {
            // Simpler gradient for better performance on watch
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.11, green: 0.12, blue: 0.18)]
                    : [Color(red: 0.95, green: 0.96, blue: 0.99), Color(red: 0.90, green: 0.92, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Reduced ambient orbs for performance
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? Color.pink.opacity(0.3) : Color.pink.opacity(0.15))
                        .frame(width: 80)
                        .blur(radius: 30)
                        .offset(x: -40, y: -60)
                    
                    Circle()
                        .fill(colorScheme == .dark ? Color.purple.opacity(0.3) : Color.purple.opacity(0.15))
                        .frame(width: 100)
                        .blur(radius: 40)
                        .offset(x: 50, y: 70)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
    
    // MARK: - Main Content Layout
    var content: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Compact header
                headerWatchOS
                
                // Score display
                GameScoreView(
                    xWins: xWins,
                    oWins: oWins,
                    ties: ties,
                    currentTurn: currentPlayer
                )
                .padding(.horizontal, 4)
                
                // Game board
                board
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                
                // Action buttons
                footerWatchOS
            }
            .padding(.vertical, 8)
        }
        .focusable() // Enable Digital Crown scrolling
    }
    
    // MARK: - Header (watchOS optimized)
    var headerWatchOS: some View {
        VStack(spacing: 4) {
            Text(headerTitle)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(LinearGradient(
                    colors: [.pink, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
            
            Text(headerSubtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            // Mode badge
            Text(modeBadgeText)
                .font(.system(size: 9).weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.purple.opacity(0.5), .blue.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Game Board (watchOS optimized)
    var board: some View {
        GeometryReader { proxy in
            let winningArray = detectWinningIndices()
            let winning: Set<Int> = Set(winningArray)
            let side = min(proxy.size.width, proxy.size.height)
            
            // Adaptive spacing based on board size
            let isLargeGrid = ticTacToe.boardSize >= 5
            let baseSpacing: CGFloat = isLargeGrid ? 3 : 4
            let sideCells = CGFloat(ticTacToe.boardSize)
            
            // Calculate cell size
            let minCell: CGFloat = isLargeGrid ? 20 : 28
            let cellSize = max(minCell, (side - baseSpacing * (sideCells + 1)) / sideCells)
            
            VStack(spacing: baseSpacing) {
                ForEach(0..<ticTacToe.boardSize, id: \.self) { row in
                    HStack(spacing: baseSpacing) {
                        ForEach(0..<ticTacToe.boardSize, id: \.self) { column in
                            let index = row * ticTacToe.boardSize + column
                            if ticTacToe.squares.indices.contains(index) {
                                SquareButtonViewWatch(
                                    dataSource: ticTacToe.squares[index],
                                    index: index,
                                    size: cellSize,
                                    winningIndices: winning,
                                    isRecentlyPlaced: recentlyPlacedIndex == index,
                                    action: {
                                        if let handler = onCellTap {
                                            handler(index)
                                        } else {
                                            self.makeMove(at: index)
                                            recentlyPlacedIndex = index
                                        }
                                    }
                                )
                            } else {
                                Color.clear.frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .scaleEffect(animateBoardEntrance ? 1.0 : 0.95)
            .opacity(animateBoardEntrance ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animateBoardEntrance)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
    }
    
    // MARK: - Footer Actions (watchOS)
    var footerWatchOS: some View {
        VStack(spacing: 8) {
            // Restart button
            Button(action: resetForNextRound) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                    Text("Restart")
                        .font(.caption.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .cornerRadius(20)
            
            // Exit button
            Button(role: .destructive, action: exitToMenu) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.caption)
                    Text("Exit")
                        .font(.caption.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .cornerRadius(20)
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Status Banner (watchOS)
    var turnBanner: some View {
        HStack {
            if ticTacToe.playerToMove == ticTacToe.aiPlays && !gameTypeIsPVP {
                Label("AI thinking", systemImage: "brain")
                    .font(.system(size: 10, design: .rounded).weight(.semibold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .accessibilityLabel("AI is thinking")
            } else {
                Label("\(currentPlayer)", systemImage: ticTacToe.playerToMove == .x ? "xmark" : "circle")
                    .font(.system(size: 10, design: .rounded).weight(.semibold))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .accessibilityLabel("\(currentPlayer) turn")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Simplified Square Button for watchOS
struct SquareButtonViewWatch: View {
    private let dataSource: SquareStatus?
    let index: Int
    let size: CGFloat
    let winningIndices: Set<Int>
    let isRecentlyPlaced: Bool
    let action: () -> Void
    
    // Allow passing either SquareStatus? or Square? to avoid mismatches
    init(dataSource: SquareStatus?, index: Int, size: CGFloat, winningIndices: Set<Int>, isRecentlyPlaced: Bool, action: @escaping () -> Void) {
        self.dataSource = dataSource
        self.index = index
        self.size = size
        self.winningIndices = winningIndices
        self.isRecentlyPlaced = isRecentlyPlaced
        self.action = action
    }
    
    init(dataSource: Square?, index: Int, size: CGFloat, winningIndices: Set<Int>, isRecentlyPlaced: Bool, action: @escaping () -> Void) {
        // Map Square? to SquareStatus? if types differ in the project
        if let ds = dataSource as? SquareStatus { self.dataSource = ds } else {
            // Fallback mapping based on common case names
            if let ds = dataSource {
                switch String(describing: ds) {
                case "x", "X", "cross": self.dataSource = .x
                case "o", "O", "nought", "circle": self.dataSource = .o
                default: self.dataSource = .empty
                }
            } else {
                self.dataSource = nil
            }
        }
        self.index = index
        self.size = size
        self.winningIndices = winningIndices
        self.isRecentlyPlaced = isRecentlyPlaced
        self.action = action
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isWinning: Bool {
        return winningIndices.contains(index)
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                            .strokeBorder(
                                isWinning
                                    ? LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)], startPoint: .top, endPoint: .bottom),
                                lineWidth: isWinning ? 2 : 1
                            )
                    )
                
                // Symbol
                if let square = dataSource, square != .empty {
                    symbolView(for: square)
                        .frame(width: size * 0.6, height: size * 0.6)
                        .scaleEffect(isRecentlyPlaced ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecentlyPlaced)
                }
            }
        }
        .frame(width: size, height: size)
        .buttonStyle(.plain)
        .disabled({
            guard let ds = dataSource else { return false }
            return ds != .empty
        }())
    }
    
    @ViewBuilder
    private func symbolView(for value: SquareStatus) -> some View {
        switch value {
        case .x:
            Image(systemName: "xmark")
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .red],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .o:
            Image(systemName: "circle")
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        case .empty:
            EmptyView()
        @unknown default:
            EmptyView()
        }
    }
}

// MARK: - Helper Extension
private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

