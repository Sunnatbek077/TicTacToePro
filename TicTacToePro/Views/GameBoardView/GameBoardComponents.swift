//
//  GameBoardComponents.swift
//  TicTacToePro
//

import SwiftUI

// MARK: - Layout constants
private enum Layout {
    static func hPad(_ se: Bool, _ compact: Bool) -> CGFloat { se ? 6 : (compact ? 10 : 16) }
    static func vPad(_ se: Bool, _ compact: Bool) -> CGFloat { se ? 4 : (compact ? 6 : 10) }
    static func gap(_ se: Bool, _ compact: Bool) -> CGFloat  { se ? 6 : (compact ? 7 : 10) }

    static func headerH(_ se: Bool) -> CGFloat       { se ? 44 : 52 }
    static func unifiedHeaderH(_ se: Bool) -> CGFloat { se ? 64 : 76 }
    static func stripH(_ se: Bool) -> CGFloat        { se ? 40 : 48 }
    static func bannerH(_ se: Bool) -> CGFloat       { se ? 36 : 46 }

    // Portrait iPad multiplayer uchun pastki player bar balandligi
    static let portraitPlayerBarH: CGFloat = 88
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
        let scale: CGFloat = isTVOS ? 2.5 : 1.0
        return ZStack {
            Circle().fill(colorScheme == .dark ? Color.pink.opacity(0.6) : Color.pink.opacity(0.25))
                .frame(width: 200 * scale).blur(radius: 55 * scale).offset(x: -120 * scale, y: -160 * scale)
            Circle().fill(colorScheme == .dark ? Color.blue.opacity(0.5) : Color.blue.opacity(0.22))
                .frame(width: 240 * scale).blur(radius: 65 * scale).offset(x: 140 * scale, y: -100 * scale)
            Circle().fill(colorScheme == .dark ? Color.purple.opacity(0.5) : Color.purple.opacity(0.24))
                .frame(width: 260 * scale).blur(radius: 75 * scale).offset(x: 100 * scale, y: 200 * scale)
            Circle().fill(colorScheme == .dark ? Color.cyan.opacity(0.4) : Color.cyan.opacity(0.18))
                .frame(width: 140 * scale).blur(radius: 45 * scale).offset(x: -70 * scale, y: 160 * scale)
        }
    }

    // MARK: - Content
    var content: some View {
        Group {
#if os(tvOS)
            tvLayout
#else
            if isWide {
                if topOverlay != nil {
                    multiplayerIPadLayout
                } else {
                    HStack(spacing: 24) {
                        board
                        rightPanel.frame(minWidth: 220, maxWidth: 320)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            } else {
                portraitLayout
            }
#endif
        }
    }

    // MARK: - tvOS Layout
    private var tvLayout: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height
            let safeH = H - 80 // yuqori overlay uchun joy
            let panelW: CGFloat = min(440, W * 0.30)
            let boardSide: CGFloat = min(safeH * 0.88, W - panelW - 160)

            HStack(alignment: .center, spacing: 60) {
                // Board — chap tomonda
                tvBoardGrid(side: boardSide)
                    .frame(width: boardSide, height: boardSide)

                // O'ng panel
                tvRightPanel
                    .frame(width: panelW)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 60)
            .padding(.top, 40)
        }
    }

    // MARK: - tvOS Board Grid (focus boshqaruvi bilan)
    private func tvBoardGrid(side: CGFloat) -> some View {
        let winning = detectWinningIndices()
        let n = CGFloat(ticTacToe.boardSize)
        let spacing: CGFloat = 16
        let cellSize = max(80, (side - spacing * (n - 1)) / n)

        return VStack(spacing: spacing) {
            ForEach(0..<ticTacToe.boardSize, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<ticTacToe.boardSize, id: \.self) { col in
                        let idx = row * ticTacToe.boardSize + col
                        if ticTacToe.squares.indices.contains(idx) {
                            Button {
                                if let handler = onCellTap { handler(idx) }
                                else { makeMove(at: idx); recentlyPlacedIndex = idx }
                            } label: {
                                SquareButtonView(
                                    dataSource: ticTacToe.squares[idx],
                                    size: cellSize,
                                    winningIndices: winning,
                                    isRecentlyPlaced: recentlyPlacedIndex == idx,
                                    isSELikeSmallScreen: false,
                                    action: { }
                                )
                                .frame(width: cellSize, height: cellSize)
                            }
#if os(tvOS)
                            .buttonStyle(TVGameCellButtonStyle(cellSize: cellSize))
#endif
                        } else {
                            Color.clear.frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
        .id(boardResetID)
        .scaleEffect(animateBoardEntrance ? 1.0 : 0.92)
        .opacity(animateBoardEntrance ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: animateBoardEntrance)
    }

    // MARK: - Multiplayer iPad Layout (landscape va portrait ni o'zi aniqlaydi)
    private var multiplayerIPadLayout: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let H = geo.size.height
            if W >= H {
                // Haqiqiy landscape: yon panellar bilan
                self.iPadLandscapeBody(W: W, H: H)
            } else {
                // Haqiqiy portrait: pastki player bar bilan
                self.portraitBody(W: W, H: H)
            }
        }
    }

    private func iPadLandscapeBody(W: CGFloat, H: CGFloat) -> some View {
        let hPad:    CGFloat = 20
        let vPad:    CGFloat = 20
        let spacing: CGFloat = 16
        let panelW:  CGFloat = min(160, W * 0.17)
        // Multiplayer rejimida yon panellar yo'q — board kengroq bo'ladi
        let sidePanelTotal: CGFloat = isMultiplayer ? 0 : (panelW * 2 + spacing * 2)
        let midW:    CGFloat = W - hPad * 2 - sidePanelTotal
        let innerH:  CGFloat = H - vPad * 2
        let boardSide: CGFloat = min(midW, innerH - 34 - 46 - 38 - 30)

        return HStack(spacing: spacing) {
            if !isMultiplayer {
                iPadPlayerPanel(isLeft: true)
                    .frame(width: panelW, height: innerH)
            }

            iPadCenterColumn(midW: midW, innerH: innerH, boardSide: boardSide)

            if !isMultiplayer {
                iPadPlayerPanel(isLeft: false)
                    .frame(width: panelW, height: innerH)
            }
        }
        .frame(width: W - hPad * 2, height: innerH)
        .frame(width: W, height: H)
    }

    private func iPadCenterColumn(midW: CGFloat, innerH: CGFloat, boardSide: CGFloat) -> some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)
            iPadTitle
            // Multiplayer rejimida: scoreStrip o'rniga topOverlay (VS bar)
            // Solo rejimda: oddiy scoreStrip
            if isMultiplayer, let topOverlay {
                topOverlay
            } else {
                scoreStrip
            }
            boardGrid(side: boardSide)
                .frame(width: boardSide, height: boardSide)
            turnBanner
            Spacer(minLength: 0)
        }
        .frame(width: midW, height: innerH)
    }

    private var iPadTitle: some View {
        Text(headerTitle)
            .font(.system(.title2, design: .rounded).weight(.black))
            .foregroundStyle(
                LinearGradient(
                    colors: [.pink, .purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .lineLimit(1)
            .frame(maxWidth: .infinity)
    }

    // MARK: - iPad Player Side Panel (landscape uchun)
    private func iPadPlayerPanel(isLeft: Bool) -> some View {
        let symbolColor: Color = isLeft ? .pink : .blue
        let symbol      = isLeft ? "X" : "O"
        let score       = isLeft ? xWins : oWins
        let isActive    = currentPlayer == symbol
        let icon        = isLeft ? "xmark" : "circle"

        return iPadPanelContent(
            symbolColor: symbolColor,
            symbol: symbol,
            score: score,
            isActive: isActive,
            icon: icon
        )
    }

    private func iPadPanelContent(
        symbolColor: Color,
        symbol: String,
        score: Int,
        isActive: Bool,
        icon: String
    ) -> some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(symbolColor.opacity(isActive ? 0.18 : 0.06))
                    .frame(width: 68, height: 68)
                    .overlay(
                        Circle().strokeBorder(
                            symbolColor.opacity(isActive ? 0.85 : 0.15),
                            lineWidth: isActive ? 2.5 : 1
                        )
                    )
                    .shadow(
                        color: isActive ? symbolColor.opacity(0.5) : .clear,
                        radius: 16, x: 0, y: 0
                    )
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(symbolColor.opacity(isActive ? 1 : 0.3))
            }
            .animation(.easeInOut(duration: 0.3), value: isActive)

            VStack(spacing: 4) {
                Text(symbol)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(symbolColor.opacity(0.6))
                    .tracking(2)
                Text(isActive ? "Your Turn" : "Waiting...")
                    .font(.system(size: 13,
                                  weight: isActive ? .semibold : .regular,
                                  design: .rounded))
                    .foregroundStyle(isActive ? Color.primary : Color.secondary)
            }
            .animation(.easeInOut(duration: 0.25), value: isActive)

            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(
                        isActive
                            ? AnyShapeStyle(symbolColor)
                            : AnyShapeStyle(Color.secondary.opacity(0.4))
                    )
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: score)
                Text("wins")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            RoundedRectangle(cornerRadius: 2)
                .fill(symbolColor.opacity(isActive ? 0.8 : 0.1))
                .frame(height: 3)
                .animation(.easeInOut(duration: 0.3), value: isActive)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: isActive
                            ? [symbolColor.opacity(0.7), symbolColor.opacity(0.15)]
                            : [Color.white.opacity(0.1), Color.white.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: isActive ? 1.5 : 1
                )
        )
        .shadow(
            color: isActive ? symbolColor.opacity(0.2) : .clear,
            radius: 20, x: 0, y: 4
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
    }

    // MARK: - Portrait layout (iPhone + iPad portrait, multiplayer + solo)
    private var portraitLayout: some View {
        GeometryReader { geo in
            self.portraitBody(W: geo.size.width, H: geo.size.height)
        }
    }

    private func portraitBody(W: CGFloat, H: CGFloat) -> some View {
        let hPad = Layout.hPad(isSESmallScreen, isCompactHeight)
        let vPad = Layout.vPad(isSESmallScreen, isCompactHeight)
        let gap  = Layout.gap(isSESmallScreen, isCompactHeight)

        // iPad portrait multiplayer: katta ekran, pastda alohida player bar
        // iPhone portrait multiplayer: kichik ekran, yuqorida unifiedHeader
        let isIPad = W > 700
        let isMultiplayerPortraitIPad = topOverlay != nil && isIPad

        let headerH: CGFloat
        let bannerExtra: CGFloat
        let playerBarExtra: CGFloat

        if isMultiplayerPortraitIPad {
            // iPad portrait multiplayer: kichik title + pastda player bar
            headerH        = 44
            bannerExtra    = Layout.bannerH(isSESmallScreen) + gap
            playerBarExtra = Layout.portraitPlayerBarH + gap
        } else if topOverlay != nil {
            // iPhone portrait multiplayer: title + player bar birlashgan (unifiedHeader)
            headerH        = Layout.unifiedHeaderH(isSESmallScreen)
            bannerExtra    = 0
            playerBarExtra = 0
        } else {
            // Solo rejim
            headerH        = Layout.headerH(isSESmallScreen)
            bannerExtra    = Layout.bannerH(isSESmallScreen) + gap
            playerBarExtra = 0
        }

        let fixedV = headerH
                   + Layout.stripH(isSESmallScreen)
                   + bannerExtra
                   + playerBarExtra
                   + gap * 2
                   + vPad * 2

        let side = min(
            max(0, W - hPad * 2),
            max(0, H - fixedV)
        )

        return portraitContent(
            hPad: hPad,
            vPad: vPad,
            gap: gap,
            side: side,
            isMultiplayerPortraitIPad: isMultiplayerPortraitIPad
        )
    }

    @ViewBuilder
    private func portraitContent(
        hPad: CGFloat,
        vPad: CGFloat,
        gap: CGFloat,
        side: CGFloat,
        isMultiplayerPortraitIPad: Bool
    ) -> some View {
        VStack(spacing: 0) {
            if isMultiplayerPortraitIPad {
                // Tepa: title
                Text(headerTitle)
                    .font(.system(.title2, design: .rounded).weight(.black))
                    .foregroundStyle(
                        LinearGradient(colors: [.pink, .purple, .blue],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, hPad)
                    .padding(.bottom, gap)

                // Tepa: player bar (scoreStrip o'rnida)
                portraitIPadPlayerBar
                    .padding(.horizontal, hPad)
                    .padding(.bottom, gap)
            } else if let topOverlay {
                unifiedHeader(playersBar: topOverlay)
                    .padding(.horizontal, hPad)
                    .padding(.bottom, gap)
            } else {
                header
                    .padding(.horizontal, hPad)
                    .padding(.bottom, gap)

                scoreStrip
                    .padding(.horizontal, hPad)
                    .padding(.bottom, gap)
            }

            boardGrid(side: side)
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity)
                .padding(.bottom, gap)

            // turnBanner faqat solo rejimda
            if topOverlay == nil {
                turnBanner
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(.vertical, vPad)
    }

    // MARK: - Portrait iPad Multiplayer: pastki player bar
    // Ikki o'yinchi horizontal joylashgan, to'liq kenglikda
    private var portraitIPadPlayerBar: some View {
        HStack(spacing: 12) {
            portraitIPadPlayerCard(isLeft: true)
            portraitIPadVsDivider
            portraitIPadPlayerCard(isLeft: false)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .frame(height: Layout.portraitPlayerBarH)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.pink.opacity(0.30),
                            Color.purple.opacity(0.20),
                            Color.blue.opacity(0.30)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
    }

    // "VS" ajratuvchi — markazda, ingichka vertikal chiziq bilan
    private var portraitIPadVsDivider: some View {
        VStack(spacing: 4) {
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: 14)
            Text("VS")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.tertiary)
                .tracking(1)
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 1, height: 14)
        }
        .padding(.horizontal, 4)
    }

    // Har bir o'yinchi kartasi: symbol doirasi + status + score
    // isLeft=true  → doira chap, matn o'ng (leading alignment)
    // isLeft=false → matn chap, doira o'ng (trailing alignment, mirror yo'q)
    private func portraitIPadPlayerCard(isLeft: Bool) -> some View {
        let symbolColor: Color = isLeft ? .pink : .blue
        let score       = isLeft ? xWins : oWins
        let isActive    = currentPlayer == (isLeft ? "X" : "O")
        let icon        = isLeft ? "xmark" : "circle"

        let symbolCircle = ZStack {
            Circle()
                .fill(symbolColor.opacity(isActive ? 0.20 : 0.06))
                .frame(width: 52, height: 52)
                .overlay(
                    Circle().strokeBorder(
                        symbolColor.opacity(isActive ? 0.90 : 0.15),
                        lineWidth: isActive ? 2 : 1
                    )
                )
                .shadow(
                    color: isActive ? symbolColor.opacity(0.55) : .clear,
                    radius: 14, x: 0, y: 0
                )
            Image(systemName: icon)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(symbolColor.opacity(isActive ? 1 : 0.30))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isActive)

        let info = VStack(alignment: isLeft ? .leading : .trailing, spacing: 3) {
            HStack(spacing: 5) {
                if !isLeft { Spacer(minLength: 0) }
                Circle()
                    .fill(isActive ? symbolColor : Color.gray.opacity(0.30))
                    .frame(width: 6, height: 6)
                    .shadow(color: isActive ? symbolColor.opacity(0.8) : .clear,
                            radius: 4, x: 0, y: 0)
                    .animation(.easeInOut(duration: 0.3), value: isActive)
                Text(isActive ? "Your Turn" : "Waiting...")
                    .font(.system(size: 13,
                                  weight: isActive ? .semibold : .regular,
                                  design: .rounded))
                    .foregroundStyle(isActive ? Color.primary : Color.secondary)
                if isLeft { Spacer(minLength: 0) }
            }
            .animation(.easeInOut(duration: 0.25), value: isActive)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                if !isLeft { Spacer(minLength: 0) }
                Text("\(score)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(
                        isActive
                            ? AnyShapeStyle(symbolColor)
                            : AnyShapeStyle(Color.secondary.opacity(0.40))
                    )
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4), value: score)
                Text("wins")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 2)
                if isLeft { Spacer(minLength: 0) }
            }
        }

        return Group {
            if isLeft {
                HStack(spacing: 14) {
                    symbolCircle
                    info
                }
            } else {
                HStack(spacing: 14) {
                    info
                    symbolCircle
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: isLeft ? .leading : .trailing)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isActive)
    }

    // MARK: - Score strip
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

    // MARK: - Board (landscape/iPad)
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
        let baseSpacing: CGFloat = isTVOS ? 12 : (isSESmallScreen ? 5 : isCompactHeight ? 6 : 8)
        let spacing = isLarge ? max(3, baseSpacing * 0.55) : baseSpacing
        let minCell: CGFloat = isTVOS ? 60 : (isLarge ? 28 : 40)
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
        .id(boardResetID)
        .drawingGroup(opaque: false, colorMode: .extendedLinear)
        .transaction { txn in if isLarge { txn.disablesAnimations = true } }
    }

    // MARK: - Footer
    var footer: some View {
        turnBanner
    }

    // MARK: - Footer buttons (solo landscape/iPad)
    var footerButtonsOnly: some View {
        VStack(alignment: .leading, spacing: isSESmallScreen ? 8 : 10) {
            premiumButton(
                title: "Restart",
                icon: "arrow.counterclockwise",
                gradientColors: [.purple, .pink],
                isPrimary: true,
                action: resetForNextRound
            )

            premiumButton(
                title: "Exit",
                icon: "rectangle.portrait.and.arrow.right",
                gradientColors: [.red.opacity(0.7), .orange.opacity(0.6)],
                isPrimary: false,
                action: exitToMenu
            )
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private func premiumButton(
        title: String,
        icon: String,
        gradientColors: [Color],
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: isSESmallScreen ? 6 : 8) {
                Image(systemName: icon)
                    .font(.system(size: isSESmallScreen ? 13 : 15, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: gradientColors,
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: isSESmallScreen ? 28 : 32, height: isSESmallScreen ? 28 : 32)
                    .background(gradientColors[0].opacity(0.12), in: Circle())
                    .overlay(Circle().strokeBorder(gradientColors[0].opacity(0.25), lineWidth: 1))

                Text(title)
                    .font(.system(isSESmallScreen ? .subheadline : .headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(isPrimary ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, isSESmallScreen ? 10 : 12)
            .padding(.horizontal, 16)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isPrimary
                                ? [gradientColors[0].opacity(0.5), gradientColors[1].opacity(0.25)]
                                : [Color.white.opacity(0.1), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Turn banner
    var turnBanner: some View {
        let isAITurn = ticTacToe.playerToMove == ticTacToe.aiPlays && !gameTypeIsPVP
        let text: String = isAITurn ? "AI is thinking..." : "\(currentPlayer)'s Turn"
        let icon: String = isAITurn ? "brain.head.profile" : (ticTacToe.playerToMove == .x ? "xmark" : "circle")
        let colors: [Color] = isAITurn ? [.purple, .blue] : [.pink, .purple]

        return Label(text, systemImage: icon)
            .font(.system(isTVOS ? .title3 : (isSESmallScreen ? .caption2 : .subheadline), design: .rounded).weight(.semibold))
            .padding(.vertical, isTVOS ? 14 : (isSESmallScreen ? 6 : 9))
            .padding(.horizontal, isTVOS ? 24 : (isSESmallScreen ? 10 : 16))
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing),
                lineWidth: isTVOS ? 2 : 1
            ))
            .accessibilityLabel(text)
    }

    // MARK: - Right panel (solo landscape / iPad)
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

    // MARK: - tvOS Right Panel (kattalashtrilgan)
    private var tvRightPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Sarlavha
            tvHeader

            // Score strip (tvOS uchun kattaroq)
            tvScoreStrip

            // Status + Mode karta
            tvStatusCard

            // Tugmalar
            tvFooterButtons

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var tvHeader: some View {
        HStack(spacing: 14) {
            Text(headerTitle)
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .purple, .blue],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var tvScoreStrip: some View {
        HStack(spacing: 0) {
            tvScoreStripItem(label: "X", value: xWins, labelColor: .pink,
                             isActive: currentPlayer == "X" && !ticTacToe.gameOver)
            tvStripDivider
            tvScoreStripItem(label: "TIE", value: ties, labelColor: Color(.secondaryLabel),
                             isActive: false)
            tvStripDivider
            tvScoreStripItem(label: "O", value: oWins, labelColor: .blue,
                             isActive: currentPlayer == "O" && !ticTacToe.gameOver)
        }
        .padding(.vertical, 20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func tvScoreStripItem(label: String, value: Int,
                                   labelColor: Color, isActive: Bool) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(isActive ? labelColor : labelColor.opacity(0.4))
            Text("\(value)")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(isActive ? Color.primary : Color.secondary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)
            // Aktiv indikator chiziq
            RoundedRectangle(cornerRadius: 2)
                .fill(isActive ? labelColor : .clear)
                .frame(width: 40, height: 4)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    private var tvStripDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 50)
    }

    private var tvStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Turn indicator
            HStack(spacing: 12) {
                let isX = currentPlayer == "X"
                let turnColor: Color = isX ? .pink : .blue
                let turnIcon = isX ? "xmark" : "circle"
                Image(systemName: turnIcon)
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(turnColor)
                    .frame(width: 48, height: 48)
                    .background(turnColor.opacity(0.15), in: Circle())
                    .overlay(Circle().strokeBorder(turnColor.opacity(0.5), lineWidth: 2))
                VStack(alignment: .leading, spacing: 2) {
                    Text(headerSubtitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(modeBadgeText)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPlayer)
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        )
    }

    private var tvFooterButtons: some View {
        VStack(spacing: 20) {
            tvPremiumButton(
                title: "Restart",
                icon: "arrow.counterclockwise",
                gradientColors: [.purple, .pink],
                isPrimary: true,
                action: resetForNextRound
            )

            tvPremiumButton(
                title: "Exit",
                icon: "rectangle.portrait.and.arrow.right",
                gradientColors: [.red.opacity(0.7), .orange.opacity(0.6)],
                isPrimary: false,
                action: exitToMenu
            )
        }
    }

    private func tvPremiumButton(
        title: String,
        icon: String,
        gradientColors: [Color],
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: gradientColors,
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)
                    .background(gradientColors[0].opacity(0.12), in: Circle())
                    .overlay(Circle().strokeBorder(gradientColors[0].opacity(0.25), lineWidth: 1.5))

                Text(title)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(isPrimary ? .primary : .secondary)

                Spacer()
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isPrimary
                                ? [gradientColors[0].opacity(0.5), gradientColors[1].opacity(0.25)]
                                : [Color.white.opacity(0.1), Color.white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        #if os(tvOS)
        .buttonStyle(TVPremiumButtonStyle(gradientColors: gradientColors))
        #else
        .buttonStyle(.plain)
        #endif
    }

    // MARK: - Status card
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

    // MARK: - Header (solo)
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

    // MARK: - Unified Header (iPhone portrait multiplayer)
    func unifiedHeader(playersBar: AnyView) -> some View {
        VStack(alignment: .leading, spacing: isSESmallScreen ? 5 : 7) {
            Text(headerTitle)
                .font(headerTitleFont)
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .purple, .blue],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            playersBar
        }
        .padding(.horizontal, isSESmallScreen ? 10 : 14)
        .padding(.vertical, isSESmallScreen ? 8 : 11)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.pink.opacity(0.25), Color.purple.opacity(0.2), Color.blue.opacity(0.25)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
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

// MARK: - tvOS Game Cell Button Style
#if os(tvOS)
/// tvOS'da standart oq "lift card" effektini to'liq o'chiradi
/// va o'rniga gradient border + scale + glow effekt beradi.
struct TVGameCellButtonStyle: ButtonStyle {
    let cellSize: CGFloat
    @Environment(\.isFocused) var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: cellSize, height: cellSize)
            .clipShape(RoundedRectangle(cornerRadius: cellSize * 0.16, style: .continuous))
            .scaleEffect(isFocused ? 1.05 : (configuration.isPressed ? 0.96 : 1.0))
            .overlay(
                RoundedRectangle(cornerRadius: cellSize * 0.16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isFocused
                                ? [.pink, .purple, .blue]
                                : [.clear, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? 4 : 0
                    )
            )
            .shadow(
                color: isFocused ? Color.purple.opacity(0.7) : .clear,
                radius: isFocused ? 16 : 0
            )
            .brightness(isFocused ? 0.08 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isFocused)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// tvOS premium button style — glassmorphic focus effekt
struct TVPremiumButtonStyle: ButtonStyle {
    let gradientColors: [Color]
    @Environment(\.isFocused) var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(isFocused ? 1.04 : (configuration.isPressed ? 0.97 : 1.0))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: isFocused
                                ? gradientColors.map { $0.opacity(0.8) }
                                : [.clear, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? 3 : 0
                    )
            )
            .shadow(
                color: isFocused ? gradientColors[0].opacity(0.5) : .clear,
                radius: isFocused ? 20 : 0
            )
            .brightness(isFocused ? 0.06 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isFocused)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
#endif
