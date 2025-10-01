//
//  StartMenuView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import SwiftUI
#if os(iOS)
import CoreHaptics
#endif

struct StartMenuView: View {
    // MARK: - Premium Styling
    private var premiumGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.10),
                    Color(red: 0.11, green: 0.12, blue: 0.18),
                    Color(red: 0.03, green: 0.04, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.98, blue: 1.0), // Softer white-blue tint
                    Color(red: 0.95, green: 0.96, blue: 0.99),
                    Color(red: 0.90, green: 0.92, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private let accentGradient = LinearGradient(
        colors: [.pink.opacity(0.9), .purple.opacity(0.9), .blue.opacity(0.9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    @State private var animateBackground = false
    @State private var showBokeh = true
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    
    @State private var selectedPlayer: PlayerOption = .x
    @State private var selectedDifficulty: DifficultyOption = .easy
    @State private var selectedGameMode: GameMode = .ai
    @State private var showGame = false
    
    @StateObject private var viewModel = ViewModel()
    @StateObject private var ticTacToeModel = GameViewModel()
#if os(iOS)
    @State private var hapticsEngine: CHHapticEngine?
#endif
    
    private var startingPlayerIsO: Bool { selectedPlayer == .o }
    
    private var configurationSummary: String {
        selectedGameMode.isPVP
        ? "PvP • \(selectedPlayer.rawValue) starts"
        : "AI: \(startingPlayerIsO ? "X" : "O") • \(selectedDifficulty.rawValue)"
    }
    
    // MARK: - Layout Helpers
    private var aspectRatio: CGFloat {
#if os(iOS)
        let size = UIScreen.main.bounds.size
        return size.height / size.width
#else
        return 2.0
#endif
    }
    
    private var layoutCategory: String {
        if aspectRatio >= 2.1 { return "tall" }        // iPhone 14 Pro Max, 19.5:9+
        else if aspectRatio >= 1.8 { return "standard" } // 18:9 yoki 16:9
        else { return "compact" }
    }
    
    private var verticalPadding: CGFloat {
        switch layoutCategory {
        case "tall": return 48
        case "standard": return 32
        default: return 20
        }
    }
    
    private var headerFont: Font {
        switch layoutCategory {
        case "tall": return .largeTitle.bold()
        case "standard": return .title.bold()
        default: return .title2.bold()
        }
    }
    
    private var isCompactHeightPhone: Bool {
#if os(iOS)
        vSizeClass == .compact || UIScreen.main.bounds.height <= 667
#else
        false
#endif
    }
    
    private var contentMaxWidth: CGFloat {
#if os(macOS)
        720
#elseif os(visionOS)
        780
#else
        hSizeClass == .regular ? 700 : (isCompactHeightPhone ? 360 : 500)
#endif
    }
    
    private var cardBackground: AnyShapeStyle {
        AnyShapeStyle(.ultraThinMaterial)
    }
    
    private var premiumShadow: (Color, CGFloat, CGFloat) {
        let color = colorScheme == .dark ? Color.black.opacity(0.6) : Color.blue.opacity(0.15) // Softer blue shadow for light mode
        return (color, 24, 14)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                premiumBackground
                if showBokeh { bokehLayer.allowsHitTesting(false) }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isCompactHeightPhone ? 16 : 24) {
                        
                        HeroHeader(isCompactHeightPhone: isCompactHeightPhone,
                                   configurationSummary: configurationSummary)
                        .font(headerFont)
                        
                        ConfigurationCard(
                            selectedPlayer: $selectedPlayer,
                            selectedGameMode: $selectedGameMode,
                            selectedDifficulty: $selectedDifficulty,
                            isCompactHeightPhone: isCompactHeightPhone,
                            shadowColor: colorScheme == .dark ? .black : .gray,
                            cardBackground: cardBackground
                        )
                        .background(RoundedRectangle(cornerRadius: 28).fill(cardBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .strokeBorder(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.06)
                                    : Color.blue.opacity(0.08), // Subtle blue border for light mode
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: premiumShadow.0, radius: premiumShadow.1, x: 0, y: premiumShadow.2)
                        .padding(.top, isCompactHeightPhone ? 4 : 8)
                        .transition(.scale.combined(with: .opacity))
                        
                        StartButton(isCompactHeightPhone: isCompactHeightPhone) {
                            triggerHaptic()
                            startGame()
                        }
                        .padding(layoutCategory == "tall" ? 20 : 12)
                        .background(RoundedRectangle(cornerRadius: 20).fill(accentGradient.opacity(colorScheme == .dark ? 0.18 : 0.24))) // Slightly higher opacity in light mode
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .strokeBorder(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.06)
                                    : Color.purple.opacity(0.08), // Purple tint for light mode border
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .purple.opacity(colorScheme == .dark ? 0.35 : 0.25), radius: 18, x: 0, y: 10) // Softer shadow in light mode
                        .sensoryFeedback(.success, trigger: showGame)
                    }
                    .padding(.horizontal, isCompactHeightPhone ? 12 : 16)
                    .padding(.vertical, verticalPadding)
                    .padding(.top, layoutCategory == "tall" ? 48 : 32)
                    .frame(maxWidth: contentMaxWidth)
                    .animation(.spring(duration: 0.8, bounce: 0.2), value: selectedGameMode)
                    .navigationDestination(isPresented: $showGame) {
                        GameBoardView(
                            onExit: { showGame = false },
                            viewModel: viewModel,
                            ticTacToe: ticTacToeModel,
                            gameTypeIsPVP: selectedGameMode.isPVP,
                            difficulty: selectedDifficulty.mapped,
                            startingPlayerIsO: startingPlayerIsO
                        )
                        .navigationBarTitleDisplayMode(.inline)
                        .onDisappear { appState.isGameOpen = false }
                    }
                }
            }
            .navigationTitle("Tic Tac Toe")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Backgrounds
    private var premiumBackground: some View {
        ZStack {
            premiumGradient.ignoresSafeArea()
            
            Rectangle()
                .fill(LinearGradient(colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.02 : 0.08), // Increased opacity for light mode depth
                    Color.black.opacity(colorScheme == .dark ? 0.02 : 0.01)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                .blendMode(.overlay)
                .opacity(0.6)
                .ignoresSafeArea()
                .scaleEffect(animateBackground ? 1.02 : 0.98)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animateBackground)
            
            LinearGradient(colors: [
                Color.black.opacity(colorScheme == .dark ? 0.35 : 0.15), // Softer vignette in light mode
                .clear,
                Color.black.opacity(colorScheme == .dark ? 0.35 : 0.15)
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            
            // Added subtle noise texture for premium feel
            NoiseTextureView()
                .opacity(colorScheme == .dark ? 0.05 : 0.03)
                .ignoresSafeArea()
        }
        .task {
            animateBackground = true
#if os(iOS)
            prepareHaptics()
#endif
        }
    }
    
    private var bokehLayer: some View {
        ZStack {
            Circle().fill((colorScheme == .dark ? Color.pink : Color.pink.opacity(0.25))) // Increased opacity for light mode
                .frame(width: 220).blur(radius: 60).offset(x: -140, y: -180)
            Circle().fill((colorScheme == .dark ? Color.blue : Color.blue.opacity(0.22)))
                .frame(width: 260).blur(radius: 70).offset(x: 160, y: -120)
            Circle().fill((colorScheme == .dark ? Color.purple : Color.purple.opacity(0.24)))
                .frame(width: 280).blur(radius: 80).offset(x: 120, y: 220)
            
            // Added extra smaller bokeh for more depth
            Circle().fill((colorScheme == .dark ? Color.cyan.opacity(0.8) : Color.cyan.opacity(0.18)))
                .frame(width: 150).blur(radius: 50).offset(x: -80, y: 180)
            Circle().fill((colorScheme == .dark ? Color.indigo : Color.indigo.opacity(0.20)))
                .frame(width: 180).blur(radius: 55).offset(x: 200, y: 100)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateBackground) // Gentle animation on bokeh
    }
    
    // MARK: - Haptics
#if os(iOS)
    private func prepareHaptics() {
        do {
            hapticsEngine = try CHHapticEngine()
            try hapticsEngine?.start()
        } catch { }
    }
    
    private func triggerHaptic() {
        guard let hapticsEngine else { return }
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [sharpness, intensity], relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticsEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch { }
    }
#else
    private func triggerHaptic() {}
#endif
    
    // MARK: - Game Logic
    private func startGame() {
        ticTacToeModel.resetGame()
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
}
