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
    private let premiumGradient = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.08, blue: 0.10),
            Color(red: 0.11, green: 0.12, blue: 0.18),
            Color(red: 0.03, green: 0.04, blue: 0.06)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
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
        let color = colorScheme == .dark ? Color.black.opacity(0.6) : Color.black.opacity(0.25)
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
                        .overlay(RoundedRectangle(cornerRadius: 28)
                            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.12), lineWidth: 1))
                        .shadow(color: premiumShadow.0, radius: premiumShadow.1, x: 0, y: premiumShadow.2)
                        .padding(.top, isCompactHeightPhone ? 4 : 8)
                        .transition(.scale.combined(with: .opacity))
                        
                        StartButton(isCompactHeightPhone: isCompactHeightPhone) {
                            triggerHaptic()
                            startGame()
                        }
                        .padding(layoutCategory == "tall" ? 20 : 12)
                        .background(RoundedRectangle(cornerRadius: 20).fill(accentGradient.opacity(0.18)))
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                        .shadow(color: .purple.opacity(0.35), radius: 18, x: 0, y: 10)
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
                    Color.white.opacity(colorScheme == .dark ? 0.02 : 0.05),
                    Color.black.opacity(0.02)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                .blendMode(.overlay)
                .opacity(0.6)
                .ignoresSafeArea()
                .scaleEffect(animateBackground ? 1.02 : 0.98)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animateBackground)
            
            LinearGradient(colors: [
                Color.black.opacity(0.35), .clear, Color.black.opacity(0.35)
            ], startPoint: .top, endPoint: .bottom)
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
            Circle().fill(Color.pink.opacity(0.25)).frame(width: 220).blur(radius: 60).offset(x: -140, y: -180)
            Circle().fill(Color.blue.opacity(0.20)).frame(width: 260).blur(radius: 70).offset(x: 160, y: -120)
            Circle().fill(Color.purple.opacity(0.22)).frame(width: 280).blur(radius: 80).offset(x: 120, y: 220)
        }
        .transition(.opacity)
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
