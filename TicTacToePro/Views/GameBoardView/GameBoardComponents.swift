//
//  GameBoardComponents.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 04/10/25.
//

import SwiftUI

extension GameBoardView {
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
            
            GeometryReader { geo in
                let scaleFactor: CGFloat = isSELikeSmallScreen ? 0.6 : 1.0
                let baseWidth = geo.size.width
                let baseHeight = geo.size.height
                ZStack {
                    Circle().fill(colorScheme == .dark ? Color.pink : Color.pink.opacity(0.25))
                        .frame(width: 220 * scaleFactor).blur(radius: 60 * scaleFactor).offset(x: -140 * scaleFactor, y: -180 * scaleFactor)
                    Circle().fill(colorScheme == .dark ? Color.blue : Color.blue.opacity(0.22))
                        .frame(width: 260 * scaleFactor).blur(radius: 70 * scaleFactor).offset(x: 160 * scaleFactor, y: -120 * scaleFactor)
                    Circle().fill(colorScheme == .dark ? Color.purple : Color.purple.opacity(0.24))
                        .frame(width: 280 * scaleFactor).blur(radius: 80 * scaleFactor).offset(x: 120 * scaleFactor, y: 220 * scaleFactor)
                    Circle().fill(colorScheme == .dark ? Color.cyan.opacity(0.8) : Color.cyan.opacity(0.18))
                        .frame(width: 150 * scaleFactor).blur(radius: 50 * scaleFactor).offset(x: -80 * scaleFactor, y: 180 * scaleFactor)
                }
                .frame(width: baseWidth, height: baseHeight)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateBoardEntrance)
        }
    }
    
    var content: some View {
        Group {
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
                VStack(spacing: isSELikeSmallScreen ? 4 : (isCompactHeight ? 6 : 16)) {
                    header
                        .padding(.top, isSELikeSmallScreen ? 0 : (isCompactHeight ? 2 : 0))
                    GameScoreView(
                        xWins: xWins,
                        oWins: oWins,
                        ties: ties,
                        currentTurn: currentPlayer
                    )
                    .padding(.horizontal, isSELikeSmallScreen ? 4 : (isCompactHeight ? 8 : 16))
                    board
                        .padding(.horizontal, isSELikeSmallScreen ? 4 : (isCompactHeight ? 8 : 16))
                    footer
                        .padding(.bottom, isSELikeSmallScreen ? 2 : (isCompactHeight ? 6 : 12))
                }
                .padding(.top, isSELikeSmallScreen ? 0 : (isCompactHeight ? 4 : 12))
                .padding(.bottom, isSELikeSmallScreen ? 0 : (isCompactHeight ? 4 : 12))
            }
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
        VStack(spacing: isSELikeSmallScreen ? 2 : (isCompactHeight ? 4 : 8)) {
            Text(headerTitle)
                .font(isSELikeSmallScreen ? .system(.title2, design: .rounded).weight(.black) :
                      (isCompactHeight ? .system(.title, design: .rounded).weight(.black) : .system(.largeTitle, design: .rounded).weight(.black)))
                .foregroundStyle(LinearGradient(colors: [.pink, .purple, .blue], startPoint: .leading, endPoint: .trailing))
                .accessibilityAddTraits(.isHeader)
            
            Text(headerSubtitle)
                .font(isSELikeSmallScreen ? .caption : (isCompactHeight ? .headline : .title3.weight(.semibold)))
                .foregroundStyle(.secondary)
            
            Text(modeBadgeText)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, isSELikeSmallScreen ? 4 : (isCompactHeight ? 8 : 12))
                .padding(.vertical, isSELikeSmallScreen ? 2 : (isCompactHeight ? 4 : 6))
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom), lineWidth: 1))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, isSELikeSmallScreen ? 4 : 8)
        .padding(.vertical, isSELikeSmallScreen ? 2 : 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .gray.opacity(0.1), radius: 6)
        )
    }
    
    var board: some View {
        GeometryReader { proxy in
            let winning = detectWinningIndices()
            let horizontalMargin: CGFloat = isSELikeSmallScreen ? 8 : (isCompactHeight ? 12 : 16)
            let availableWidth = max(0, proxy.size.width - horizontalMargin * 2)
            let maxSide = min(availableWidth, proxy.size.height)
            let side = min(maxSide, preferredBoardSide(for: proxy.size))
            let spacing: CGFloat = isSELikeSmallScreen ? max(5, side * 0.012) : (isCompactHeight ? max(6, side * 0.015) : max(8, side * 0.02))
            let sideCells = CGFloat(ticTacToe.boardSize)
            
            let isLargeGrid = ticTacToe.boardSize >= 8
            let minCell: CGFloat = isLargeGrid ? 32 : 44
            let adjustedSpacing = isLargeGrid ? max(4, spacing * 0.6) : spacing
            let corner: CGFloat = isLargeGrid ? 10 : 16
            
            let useGPU = true
            
            // GRID START
            VStack(spacing: adjustedSpacing) {
                ForEach(0..<ticTacToe.boardSize, id: \.self) { row in
                    HStack(spacing: adjustedSpacing) {
                        ForEach(0..<ticTacToe.boardSize, id: \.self) { column in
                            let index = row * ticTacToe.boardSize + column
                            if ticTacToe.squares.indices.contains(index) {
                                let cellSize = max(minCell, (side - adjustedSpacing * (sideCells - 1)) / sideCells)
                                SquareButtonView(
                                    dataSource: ticTacToe.squares[index],
                                    size: cellSize,
                                    winningIndices: winning,
                                    isRecentlyPlaced: recentlyPlacedIndex == index,
                                    isSELikeSmallScreen: isSELikeSmallScreen,
                                    action: {
                                        self.makeMove(at: index)
                                        recentlyPlacedIndex = index
                                    }
                                )
                                .shadow(color: (colorScheme == .dark ? Color.black.opacity(0.22) : Color.purple.opacity(0.14)), radius: 4, x: 1, y: 1)
                                .if(isLargeGrid) { view in
                                    view.compositingGroup().drawingGroup(opaque: false, colorMode: .extendedLinear)
                                }
                            } else {
                                let cellSize = max(minCell, (side - adjustedSpacing * (sideCells - 1)) / sideCells)
                                Color.clear.frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
            .compositingGroup()
            .drawingGroup(opaque: false, colorMode: .extendedLinear)
            .transaction { txn in
                if isLargeGrid {
                    txn.disablesAnimations = true
                }
            }
            .padding(adjustedSpacing)
            .frame(width: side, height: side)
            .aspectRatio(1, contentMode: .fit)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .shadow(color: Color.purple.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 8, x: 0, y: 4)
            .scaleEffect(animateBoardEntrance ? 1.0 : 0.9)
            .opacity(animateBoardEntrance ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateBoardEntrance)
            .accessibilityElement(children: .contain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    var footer: some View {
        HStack(spacing: isSELikeSmallScreen ? 4 : (isCompactHeight ? 8 : 12)) {
            
        }
        .padding(.horizontal, isSELikeSmallScreen ? 6 : (isCompactHeight ? 12 : 16))
        .padding(.vertical, isSELikeSmallScreen ? 2 : (isCompactHeight ? 2 : 6))
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
                    .font(.system((isSELikeSmallScreen ? .caption2 : .subheadline), design: .rounded).weight(.semibold))
                    .padding(.vertical, isSELikeSmallScreen ? 4 : 8)
                    .padding(.horizontal, isSELikeSmallScreen ? 6 : 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom), lineWidth: 1))
                    .shadow(color: .purple.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 4)
                    .accessibilityLabel("AI is thinking")
            } else {
                Label("\(currentPlayer)’s Turn", systemImage: ticTacToe.playerToMove == .x ? "xmark" : "circle")
                    .font(.system((isSELikeSmallScreen ? .caption2 : .subheadline), design: .rounded).weight(.semibold))
                    .padding(.vertical, isSELikeSmallScreen ? 4 : 8)
                    .padding(.horizontal, isSELikeSmallScreen ? 6 : 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom), lineWidth: 1))
                    .shadow(color: .purple.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 4)
                    .accessibilityLabel("\(currentPlayer) turn")
            }
        }
        .padding(.horizontal, isSELikeSmallScreen ? 8 : 20)
        .padding(.bottom, isSELikeSmallScreen ? 8 : 18)
        .frame(maxWidth: .infinity)
        .frame(height: isSELikeSmallScreen ? 32 : 44)
    }
}

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
