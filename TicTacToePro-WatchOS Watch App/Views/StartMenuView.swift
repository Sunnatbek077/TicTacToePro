//
//  StartMenuView.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 20/09/25.
//
//  watchOS layout notes:
//  - NavigationStack + single ScrollView keeps the hierarchy flat
//  - HeroHeader stripped of iOS-only size-class logic
//  - No CoreHaptics import on watchOS (use WKInterfaceDevice.current().play())
//  - CustomBackgroundView kept; bokeh circles scaled down for small display
//

import SwiftUI

struct StartMenuView: View {

    // MARK: - State
    @State private var selectedPlayer:    PlayerOption    = .x
    @State private var selectedDifficulty: DifficultyOption = .easy
    @State private var selectedGameMode:  GameMode        = .ai
    @State private var selectedBoardSize: BoardSize       = .small
    @State private var showGame          = false
    @State private var animateBackground = false

    @AppStorage("isStartViewBackgroundEnabled")
    private var isStartViewBackgroundEnabled: Bool = true

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState

    @StateObject private var viewModel     = ViewModel()
    @StateObject private var ticTacToeModel = GameViewModel()

    // MARK: - Derived
    private var startingPlayerIsO: Bool { selectedPlayer == .o }

    private var summaryText: String {
        if selectedGameMode.isPVP {
            return "PvP · \(selectedPlayer.rawValue) starts · \(selectedBoardSize.title)"
        } else {
            return "AI · \(selectedDifficulty.rawValue) · \(selectedBoardSize.title)"
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                ScrollView {
                    VStack(spacing: 8) {
                        // ── Compact header ──────────────────────────────
                        VStack(spacing: 2) {
                            Text("TicTacToe")
                                .font(.headline)
                                .fontWeight(.heavy)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.pink, .purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text(summaryText)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.top, 4)

                        // ── Config card ─────────────────────────────────
                        ConfigurationCard(
                            selectedPlayer:    $selectedPlayer,
                            selectedGameMode:  $selectedGameMode,
                            selectedDifficulty: $selectedDifficulty,
                            selectedBoardSize: $selectedBoardSize,
                        )

                        // ── Start button ────────────────────────────────
                        Button(action: startGame) {
                            Text("Start")
                                .font(.footnote).fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    LinearGradient(
                                        colors: [.pink.opacity(0.9), .purple.opacity(0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 8)
                        .sensoryFeedback(.success, trigger: showGame)
                        .navigationDestination(isPresented: $showGame) {
                            GameBoardView(
                                onExit:           { showGame = false },
                                viewModel:        viewModel,
                                ticTacToe:        ticTacToeModel,
                                gameTypeIsPVP:    selectedGameMode.isPVP,
                                difficulty:       selectedDifficulty.mapped,
                                startingPlayerIsO: startingPlayerIsO,
                            )
                            .onDisappear { appState.isGameOpen = false }
                        }
                    }
                    .padding(.horizontal, 8)
                    .animation(.spring(duration: 0.6, bounce: 0.2), value: selectedGameMode)
                }
            }
        }
        .task { animateBackground = true }
    }

    // MARK: - Background
    @ViewBuilder
    private var backgroundLayer: some View {
        if isStartViewBackgroundEnabled {
            CustomBackgroundView(viewType: .startView)
        } else {
            ZStack {
                // Base gradient
                (colorScheme == .dark
                    ? LinearGradient(
                        colors: [Color(white: 0.08), Color(white: 0.11), Color(white: 0.04)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(
                        colors: [Color(white: 0.98), Color(white: 0.95), Color(white: 0.92)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .ignoresSafeArea()

                // Bokeh – smaller radii for Watch screen
                bokehLayer
            }
        }
    }

    private var bokehLayer: some View {
        ZStack {
            bokehCircle(.pink,   size: 90,  blur: 30, offset: (-60, -70))
            bokehCircle(.blue,   size: 110, blur: 35, offset: (65, -50))
            bokehCircle(.purple, size: 100, blur: 38, offset: (50, 80))
            bokehCircle(.cyan,   size: 70,  blur: 25, offset: (-40, 70))
        }
        .allowsHitTesting(false)
        .opacity(colorScheme == .dark ? 1.0 : 0.35)
    }

    private func bokehCircle(_ color: Color, size: CGFloat, blur: CGFloat, offset: (CGFloat, CGFloat)) -> some View {
        Circle()
            .fill(color)
            .frame(width: size)
            .blur(radius: blur)
            .offset(x: offset.0, y: offset.1)
            .scaleEffect(animateBackground ? 1.06 : 0.94)
            .animation(
                .easeInOut(duration: Double.random(in: 4...6))
                    .repeatForever(autoreverses: true),
                value: animateBackground
            )
    }

    // MARK: - Game start
    private func startGame() {
        ticTacToeModel.setBoardSize(selectedBoardSize.rawValue)
        if !selectedGameMode.isPVP {
            ticTacToeModel.aiPlays = startingPlayerIsO ? .x : .o
        }
        ticTacToeModel.playerToMove = startingPlayerIsO ? .o : .x
        appState.isGameOpen = true
        showGame = true
    }
}

#Preview {
    StartMenuView()
        .environmentObject(AppState())
}
