//
//  GameBoardComponents.swift
//  TicTacToePro
//

import SwiftUI

// MARK: - Layout constants (visionOS uchun kattaroq qiymatlar)
private enum Layout {
    // visionOS: SE yo'q, compact ham yo'q → faqat normal qiymatlar ishlatiladi
    static func hPad(_ se: Bool, _ compact: Bool) -> CGFloat { 20 }
    static func vPad(_ se: Bool, _ compact: Bool) -> CGFloat { 16 }
    static func gap(_ se: Bool, _ compact: Bool) -> CGFloat  { 14 }

    static func headerH(_ se: Bool) -> CGFloat  { 60 }
    static func stripH(_ se: Bool) -> CGFloat   { 56 }
    static func bannerH(_ se: Bool) -> CGFloat  { 52 }
}

extension GameBoardView {

    // MARK: - Background
    // visionOS: window chrome o'z glass effektini beradi.
    // Gradient faqat subtle ambient ranglar uchun — juda qo'pol bo'lmasligi kerak.
    var premiumBackground: some View {
        ZStack {
            // Subtle gradient — visionOS window glassmorphism bilan uyg'un
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.08, blue: 0.18).opacity(0.45),
                    Color(red: 0.06, green: 0.08, blue: 0.22).opacity(0.35),
                    Color(red: 0.04, green: 0.04, blue: 0.12).opacity(0.40)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Ambient bokeh — visionOS da blur radius kichik, opacity past
            bokehLayer
                .allowsHitTesting(false)
        }
    }

    // visionOS: bokeh kichikroq, opacity pastroq — oyna orqasidagi muhit ko'rinsin
    private var bokehLayer: some View {
        ZStack {
            Circle().fill(Color.pink.opacity(0.18))
                .frame(width: 180).blur(radius: 50).offset(x: -110, y: -140)
            Circle().fill(Color.blue.opacity(0.16))
                .frame(width: 220).blur(radius: 60).offset(x: 130, y: -90)
            Circle().fill(Color.purple.opacity(0.18))
                .frame(width: 240).blur(radius: 70).offset(x: 90, y: 180)
            Circle().fill(Color.cyan.opacity(0.12))
                .frame(width: 130).blur(radius: 42).offset(x: -65, y: 150)
        }
    }

    // MARK: - Content
    // visionOS: window har doim keng, HStack layout asosiy
    var content: some View {
        Group {
            if isWide {
                // Default visionOS layout: board chap, panel o'ng
                HStack(spacing: 28) {
                    board
                    rightPanel.frame(minWidth: 260, maxWidth: 360)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
            } else {
                // Tor oyna uchun portrait layout
                windowLayout
            }
        }
    }

    // MARK: - Window layout (visionOS portrait/narrow window)
    private var windowLayout: some View {
        GeometryReader { geo in
            let hPad = Layout.hPad(false, false)
            let vPad = Layout.vPad(false, false)
            let gap  = Layout.gap(false, false)

            let fixedV = Layout.headerH(false)
                       + Layout.stripH(false)
                       + Layout.bannerH(false)
                       + gap * 3
                       + vPad * 2

            let availH = max(0, geo.size.height - fixedV)
            let availW = max(0, geo.size.width  - hPad * 2)
            let side   = min(availW, availH)

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, hPad)
                    .padding(.bottom, gap)

                scoreStrip
                    .padding(.horizontal, hPad)
                    .padding(.bottom, gap)

                boardGrid(side: side)
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, gap)

                footer
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, vPad)
        }
    }

    // MARK: - Right panel
    var rightPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            scoreStrip
            statusCard
            footerButtonsOnly
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Status card
    // visionOS: .regularMaterial glass card, corner radius kattaroq
    var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            gradientLabel("Status", colors: [.pink, .purple])
            Text(headerSubtitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Divider()
                .overlay(Color.white.opacity(0.12))
            gradientLabel("Mode", colors: [.purple, .blue])
            modeBadge(modeBadgeText, colors: [.purple, .blue])
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [.pink.opacity(0.25), .purple.opacity(0.25)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Header
    // visionOS: HStack — title solda, subtitle+badge o'ngda. Kattaroq font.
    var header: some View {
        HStack(spacing: 12) {
            Text(headerTitle)
                .font(headerTitleFont)
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .purple, .blue],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 3) {
                Text(headerSubtitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                modeBadge(modeBadgeText, colors: [.purple, .blue])
                    .font(.system(size: 11, weight: .semibold))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var headerTitleFont: Font {
        // visionOS: SE yo'q → doim kattaroq font
        return .system(.title2, design: .rounded).weight(.black)
    }

    // MARK: - Score strip
    // visionOS: kattaroq padding, .regularMaterial
    var scoreStrip: some View {
        HStack(spacing: 0) {
            scoreStripItem(label: "X",   value: xWins, labelColor: .pink,
                           isActive: currentPlayer == "X" && !ticTacToe.gameOver)
            stripDivider
            scoreStripItem(label: "TIE", value: ties,  labelColor: Color(.secondaryLabel),
                           isActive: false)
            stripDivider
            scoreStripItem(label: "O",   value: oWins, labelColor: .blue,
                           isActive: currentPlayer == "O" && !ticTacToe.gameOver)
            stripDivider

            HStack(spacing: 6) {
                Text("TURN")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
                turnDot
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 11)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func scoreStripItem(label: String, value: Int,
                                labelColor: Color, isActive: Bool) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isActive ? labelColor : labelColor.opacity(0.4))
                .animation(.easeInOut(duration: 0.2), value: isActive)

            Text("\(value)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(isActive ? Color.primary : Color.secondary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)
        }
        .frame(maxWidth: .infinity)
    }

    private var stripDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 26)
    }

    private var turnDot: some View {
        let isX = currentPlayer == "X"
        let c: Color = isX ? .pink : .blue
        return Text(currentPlayer)
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(c)
            .frame(width: 32, height: 32)
            .background(c.opacity(0.15), in: Circle())
            .overlay(Circle().strokeBorder(c.opacity(0.5), lineWidth: 1.5))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPlayer)
    }

    // MARK: - Board (wide/landscape uchun GeometryReader)
    var board: some View {
        GeometryReader { proxy in
            let winning = detectWinningIndices()
            let side = min(proxy.size.width, proxy.size.height)
            boardGridContent(side: side, winning: winning)
                .frame(width: side, height: side)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .scaleEffect(animateBoardEntrance ? 1.0 : 0.94)
                .opacity(animateBoardEntrance ? 1.0 : 0.0)
                .animation(.spring(response: 0.55, dampingFraction: 0.84), value: animateBoardEntrance)
        }
    }

    // Narrow window uchun: aniq side tashqaridan beriladi
    func boardGrid(side: CGFloat) -> some View {
        let winning = detectWinningIndices()
        return boardGridContent(side: side, winning: winning)
            .scaleEffect(animateBoardEntrance ? 1.0 : 0.94)
            .opacity(animateBoardEntrance ? 1.0 : 0.0)
            .animation(.spring(response: 0.55, dampingFraction: 0.84), value: animateBoardEntrance)
    }

    @ViewBuilder
    private func boardGridContent(side: CGFloat, winning: [Int]) -> some View {
        let n = CGFloat(ticTacToe.boardSize)
        let isLarge = ticTacToe.boardSize >= 8
        // visionOS: kattaroq spacing, minCell kattaroq
        let spacing: CGFloat = isLarge ? 5 : 10
        let minCell: CGFloat = isLarge ? 36 : 52
        let cellSize = max(minCell, (side - spacing * (n - 1)) / n)

        VStack(spacing: spacing) {
            ForEach(0..<ticTacToe.boardSize, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<ticTacToe.boardSize, id: \.self) { col in
                        let idx = row * ticTacToe.boardSize + col
                        if ticTacToe.squares.indices.contains(idx) {
                            SquareButtonView(
                                dataSource: ticTacToe.squares[idx],
                                size: cellSize,
                                winningIndices: winning,
                                isRecentlyPlaced: recentlyPlacedIndex == idx,
                                isSELikeSmallScreen: false, // visionOS: SE yo'q
                                action: {
                                    if let handler = onCellTap { handler(idx) }
                                    else { makeMove(at: idx); recentlyPlacedIndex = idx }
                                }
                            )
                            // visionOS: hover effect
                            .hoverEffect(.lift)
                        } else {
                            Color.clear.frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .drawingGroup(opaque: false, colorMode: .extendedLinear)
        .transaction { txn in if isLarge { txn.disablesAnimations = true } }
    }

    // MARK: - Footer
    var footer: some View {
        turnBanner
    }

    // MARK: - Footer buttons
    // visionOS: .bordered buttonStyle native glass look beradi, kattaroq touch target
    var footerButtonsOnly: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: resetForNextRound) {
                Label("Restart", systemImage: "arrow.counterclockwise.circle.fill")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .hoverEffect(.highlight)

            Button(role: .destructive, action: exitToMenu) {
                Label("Exit", systemImage: "xmark.circle.fill")
                    .font(.headline)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .hoverEffect(.highlight)
        }
        .padding(.top, 8)
    }

    // MARK: - Turn banner
    // visionOS: kattaroq font, .regularMaterial, padding oshirildi
    var turnBanner: some View {
        let isAITurn = ticTacToe.playerToMove == ticTacToe.aiPlays && !gameTypeIsPVP
        let text: String   = isAITurn ? "AI is thinking..." : "\(currentPlayer)'s Turn"
        let icon: String   = isAITurn ? "brain.head.profile" : (ticTacToe.playerToMove == .x ? "xmark" : "circle")
        let colors: [Color] = isAITurn ? [.purple, .blue] : [.pink, .purple]

        return Label(text, systemImage: icon)
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .padding(.vertical, 11)
            .padding(.horizontal, 20)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                lineWidth: 1
            ))
            .accessibilityLabel(text)
            .padding(.bottom, 20)
    }

    // MARK: - leftPanel (visionOS uchun mavjud, ammo bo'sh)
    var leftPanel: some View {
        VStack { }
    }

    // MARK: - Shared helpers
    @ViewBuilder
    private func gradientLabel(_ text: String, colors: [Color]) -> some View {
        Text(text)
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
    }

    @ViewBuilder
    private func modeBadge(_ text: String, colors: [Color]) -> some View {
        Text(text)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(
                LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom),
                lineWidth: 1
            ))
            .foregroundStyle(.primary)
    }
}
