//
//  GameBoardComponents.swift
//  TicTacToePro
//
//  Fixes:
//  1. Board celllar vertikal cho'zilgan → portraitLayout GeometryReader bilan aniq boardSide hisoblaydi
//  2. Board va banner orasida bo'shliq → footer board bilan bevosita VStack ichida
//  3. Tab bar hisobga olinmagan → geo.size SwiftUI safe area ni hisoblab beradi (NavigationStack ichida)
//

import SwiftUI

// MARK: - Layout constants
private enum Layout {
    static func hPad(_ se: Bool, _ compact: Bool) -> CGFloat { se ? 6 : (compact ? 10 : 16) }
    static func vPad(_ se: Bool, _ compact: Bool) -> CGFloat { se ? 4 : (compact ? 6 : 10) }
    static func gap(_ se: Bool, _ compact: Bool) -> CGFloat  { se ? 6 : (compact ? 7 : 10) }

    // Fixed element balandliklari — taxminiy, lekin kichik tomon
    // (haqiqiy o'lcham kichik bo'lsa board katta bo'ladi, katta bo'lsa board kichik — xavfsiz)
    static func headerH(_ se: Bool) -> CGFloat  { se ? 44 : 52 }
    static func stripH(_ se: Bool) -> CGFloat   { se ? 40 : 48 }
    static func bannerH(_ se: Bool) -> CGFloat  { se ? 36 : 46 }
}

extension GameBoardView {

    // MARK: - Background
    var premiumBackground: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.08, green: 0.08, blue: 0.10),
                       Color(red: 0.11, green: 0.12, blue: 0.18),
                       Color(red: 0.03, green: 0.04, blue: 0.06)]
                    : [Color(red: 0.98, green: 0.98, blue: 1.0),
                       Color(red: 0.95, green: 0.96, blue: 0.99),
                       Color(red: 0.90, green: 0.92, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            NoiseTextureView()
                .opacity(colorScheme == .dark ? 0.05 : 0.03)
                .ignoresSafeArea()

            bokehLayer
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    private var bokehLayer: some View {
        ZStack {
            Circle().fill(colorScheme == .dark ? Color.pink : Color.pink.opacity(0.25))
                .frame(width: 200).blur(radius: 55).offset(x: -120, y: -160)
            Circle().fill(colorScheme == .dark ? Color.blue : Color.blue.opacity(0.22))
                .frame(width: 240).blur(radius: 65).offset(x: 140, y: -100)
            Circle().fill(colorScheme == .dark ? Color.purple : Color.purple.opacity(0.24))
                .frame(width: 260).blur(radius: 75).offset(x: 100, y: 200)
            Circle().fill(colorScheme == .dark ? Color.cyan.opacity(0.7) : Color.cyan.opacity(0.18))
                .frame(width: 140).blur(radius: 45).offset(x: -70, y: 160)
        }
    }

    // MARK: - Content
    var content: some View {
        Group {
            if isWide {
                // Landscape / iPad
                HStack(spacing: 24) {
                    board
                    rightPanel.frame(minWidth: 220, maxWidth: 320)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            } else {
                portraitLayout
            }
        }
    }

    // MARK: - Portrait layout
    // Muammo: board GeometryReader ichida proxy.size.height ni to'liq mavjud bo'shliq
    // sifatida qabul qilmoqda, holbuki header + strip + banner ham joy olmoqda.
    // Yechim: barcha fixed elementlar balandligini ayirib, qolganini boardga beramiz.
    // boardSide = min(availableWidth, availableHeight) → kvadrat kafolatlangan.
    private var portraitLayout: some View {
        GeometryReader { geo in
            let hPad   = Layout.hPad(isSESmallScreen, isCompactHeight)
            let vPad   = Layout.vPad(isSESmallScreen, isCompactHeight)
            let gap    = Layout.gap(isSESmallScreen, isCompactHeight)

            // Fixed elementlar umumiy balandligi:
            // header + strip + banner + 3 gap (ular orasida) + 2 vPad (yuqori/past)
            let fixedV = Layout.headerH(isSESmallScreen)
                       + Layout.stripH(isSESmallScreen)
                       + Layout.bannerH(isSESmallScreen)
                       + gap * 3
                       + vPad * 2

            // Board uchun qolgan joy
            let availH = max(0, geo.size.height - fixedV)
            let availW = max(0, geo.size.width  - hPad * 2)

            // Kvadrat: kichigini ol
            let side = min(availW, availH)

            VStack(spacing: 0) {

                // ① Header — kompakt, ~52pt
                header
                    .padding(.horizontal, hPad)
                    .padding(.bottom, gap)

                // ② Score strip — yupqa, ~48pt
                scoreStrip
                    .padding(.horizontal, hPad)
                    .padding(.bottom, gap)

                // ③ Board — kvadrat, ekranning dominant qismi
                boardGrid(side: side)
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, gap)

                // ④ Turn banner — board bilan bog'liq, pastda
                footer
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, vPad)
        }
    }

    // MARK: - Right panel (landscape / iPad)
    var rightPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            GameScoreView(xWins: xWins, oWins: oWins, ties: ties, currentTurn: currentPlayer)
            statusCard
            footerButtonsOnly
            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Status card (faqat landscape/iPad)
    var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            gradientLabel("Status", colors: [.pink, .purple])
            Text(headerSubtitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Divider()
            gradientLabel("Mode", colors: [.purple, .blue])
            modeBadge(modeBadgeText, colors: [.purple, .blue])
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Header
    // HStack bir qatorda: title chap, subtitle+badge o'ng.
    // Balandlik: SE ~44pt, normal ~52pt.
    var header: some View {
        HStack(spacing: 10) {
            Text(headerTitle)
                .font(headerTitleFont)
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .purple, .blue],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)

            Spacer()
        }
        .padding(.horizontal, isSESmallScreen ? 10 : 14)
        .padding(.vertical, isSESmallScreen ? 8 : 11)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var headerTitleFont: Font {
        if isSESmallScreen { return .system(.headline, design: .rounded).weight(.black) }
        if isCompactHeight  { return .system(.title3,   design: .rounded).weight(.black) }
        return .system(.title2, design: .rounded).weight(.black)
    }

    // MARK: - Score strip
    // Yupqa HStack: X | TIE | O | TURN.
    // Balandlik: SE ~40pt, normal ~48pt.
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

            HStack(spacing: 5) {
                Text("TURN")
                    .font(.system(size: isSESmallScreen ? 9 : 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                turnDot
            }
            .padding(.horizontal, isSESmallScreen ? 10 : 14)
        }
        .padding(.vertical, isSESmallScreen ? 7 : 9)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func scoreStripItem(label: String, value: Int,
                                labelColor: Color, isActive: Bool) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: isSESmallScreen ? 10 : 11, weight: .bold))
                .foregroundStyle(isActive ? labelColor : labelColor.opacity(0.4))
                .animation(.easeInOut(duration: 0.2), value: isActive)

            Text("\(value)")
                .font(.system(size: isSESmallScreen ? 17 : 21, weight: .black, design: .rounded))
                .foregroundStyle(isActive ? Color.primary : Color.secondary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)
        }
        .frame(maxWidth: .infinity)
    }

    private var stripDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 22)
    }

    private var turnDot: some View {
        let isX = currentPlayer == "X"
        let c: Color = isX ? .pink : .blue
        return Text(currentPlayer)
            .font(.system(size: isSESmallScreen ? 11 : 13, weight: .black, design: .rounded))
            .foregroundStyle(c)
            .frame(width: isSESmallScreen ? 24 : 28, height: isSESmallScreen ? 24 : 28)
            .background(c.opacity(0.15), in: Circle())
            .overlay(Circle().strokeBorder(c.opacity(0.5), lineWidth: 1.5))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPlayer)
    }

    // MARK: - Board (landscape/iPad uchun GeometryReader versiyasi)
    var board: some View {
        GeometryReader { proxy in
            let winning = detectWinningIndices()
            let side = min(proxy.size.width, proxy.size.height)
            boardGridContent(side: side, winning: winning)
                .frame(width: side, height: side)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .scaleEffect(animateBoardEntrance ? 1.0 : 0.92)
                .opacity(animateBoardEntrance ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.82), value: animateBoardEntrance)
        }
    }

    // Portrait uchun: aniq side tashqaridan beriladi → kvadrat kafolatlangan
    func boardGrid(side: CGFloat) -> some View {
        let winning = detectWinningIndices()
        return boardGridContent(side: side, winning: winning)
            .scaleEffect(animateBoardEntrance ? 1.0 : 0.92)
            .opacity(animateBoardEntrance ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.82), value: animateBoardEntrance)
    }

    @ViewBuilder
    private func boardGridContent(side: CGFloat, winning: [Int]) -> some View {
        let n = CGFloat(ticTacToe.boardSize)
        let isLarge = ticTacToe.boardSize >= 8
        let baseSpacing: CGFloat = isSESmallScreen ? 5 : isCompactHeight ? 6 : 8
        let spacing = isLarge ? max(3, baseSpacing * 0.55) : baseSpacing
        let minCell: CGFloat = isLarge ? 28 : 40
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
                                isSELikeSmallScreen: isSESmallScreen,
                                action: {
                                    if let handler = onCellTap { handler(idx) }
                                    else { makeMove(at: idx); recentlyPlacedIndex = idx }
                                }
                            )
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

    // MARK: - Footer buttons (landscape/iPad)
    var footerButtonsOnly: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: resetForNextRound) {
                Label("Restart", systemImage: "arrow.counterclockwise.circle.fill")
                    .font(.headline)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)

            Button(role: .destructive, action: exitToMenu) {
                Label("Exit", systemImage: "xmark.circle.fill")
                    .font(.headline)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding(.top, 6)
    }

    // MARK: - Turn banner
    var turnBanner: some View {
        let isAITurn = ticTacToe.playerToMove == ticTacToe.aiPlays && !gameTypeIsPVP
        let text: String = isAITurn ? "AI is thinking..." : "\(currentPlayer)'s Turn"
        let icon: String = isAITurn ? "brain.head.profile" : (ticTacToe.playerToMove == .x ? "xmark" : "circle")
        let colors: [Color] = isAITurn ? [.purple, .blue] : [.pink, .purple]

        return Label(text, systemImage: icon)
            .font(.system(isSESmallScreen ? .caption2 : .subheadline, design: .rounded).weight(.semibold))
            .padding(.vertical, isSESmallScreen ? 6 : 9)
            .padding(.horizontal, isSESmallScreen ? 10 : 16)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                lineWidth: 1
            ))
            .accessibilityLabel(text)
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
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(
                LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom),
                lineWidth: 1
            ))
            .foregroundStyle(.primary)
    }
}
