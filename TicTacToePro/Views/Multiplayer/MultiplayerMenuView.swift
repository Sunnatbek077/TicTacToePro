//
//  MultiplayerMenuView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 12/10/25.
//

import SwiftUI
#if os(iOS)
import CoreHaptics
#endif

struct MultiplayerMenuView: View {
    // MARK: - Properties
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    
    @State private var selectedBoardSize: BoardSize = .small
    @State private var showGame = false
    @State private var showBoardSizeSelector = false
    @State private var animateBackground = false
    @State private var selectedLobby: String? = nil
    
    @StateObject private var viewModel = ViewModel()
    @StateObject private var ticTacToeModel = GameViewModel()
    
#if os(iOS)
    @State private var hapticsEngine: CHHapticEngine?
#endif
    
    // Sample lobby data
    private let lobbies = [
        ("Battle 1", BoardSize.small, "10 minutes"),
        ("Battle 2", BoardSize.medium, "15 minutes"),
        ("Battle 3", BoardSize.large, "20 minutes")
    ]
    
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
        if aspectRatio >= 2.1 { return "tall" }
        else if aspectRatio >= 1.8 { return "standard" }
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
        let color = colorScheme == .dark ? Color.black.opacity(0.6) : Color.blue.opacity(0.15)
        return (color, 24, 14)
    }
    
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
                    Color(red: 0.98, green: 0.98, blue: 1.0),
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
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                premiumBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isCompactHeightPhone ? 16 : 24) {
                        HeroHeader(isCompactHeightPhone: isCompactHeightPhone, configurationSummary: "")
                            .font(headerFont)
                        
                        // Lobby List
                        VStack(spacing: 12) {
                            ForEach(lobbies, id: \.0) { lobby in
                                LobbyCard(
                                    name: lobby.0,
                                    boardSize: lobby.1,
                                    timeLimit: lobby.2,
                                    isSelected: selectedLobby == lobby.0,
                                    colorScheme: colorScheme
                                ) {
                                    withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                                        selectedLobby = lobby.0
                                        selectedBoardSize = lobby.1
                                    }
                                    triggerHaptic()
                                    showBoardSizeSelector = true
                                }
                                .background(RoundedRectangle(cornerRadius: 20).fill(cardBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(
                                            colorScheme == .dark
                                            ? Color.white.opacity(0.06)
                                            : Color.blue.opacity(0.08),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: premiumShadow.0, radius: premiumShadow.1, x: 0, y: premiumShadow.2)
                            }
                        }
                        .padding(.horizontal, isCompactHeightPhone ? 12 : 16)
                        
                        // Create Lobby Button
                        StartButton(isCompactHeightPhone: isCompactHeightPhone, buttonname: "Create Lobby") {
                            triggerHaptic()
                            showBoardSizeSelector = true
                        }
                        .padding(layoutCategory == "tall" ? 20 : 12)
                        .background(RoundedRectangle(cornerRadius: 20).fill(accentGradient.opacity(colorScheme == .dark ? 0.18 : 0.24)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.06)
                                    : Color.purple.opacity(0.08),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .purple.opacity(colorScheme == .dark ? 0.35 : 0.25), radius: 18, x: 0, y: 10)
                        .sensoryFeedback(.success, trigger: showGame)
                    }
                    .padding(.horizontal, isCompactHeightPhone ? 12 : 16)
                    .padding(.vertical, verticalPadding)
                    .padding(.top, layoutCategory == "tall" ? 48 : 32)
                    .frame(maxWidth: contentMaxWidth)
                    .animation(.spring(duration: 0.8, bounce: 0.2), value: selectedLobby)
                    .navigationDestination(isPresented: $showGame) {
                        GameBoardView(
                            onExit: { showGame = false },
                            viewModel: viewModel,
                            ticTacToe: ticTacToeModel,
                            gameTypeIsPVP: true,
                            difficulty: .easy, // Not used in PvP
                            startingPlayerIsO: false
                        )
                        .navigationBarTitleDisplayMode(.inline)
                        .onDisappear { appState.isGameOpen = false }
                    }
                }
            }
            .navigationTitle("Multiplayer Lobby")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showBoardSizeSelector) {
                BoardSizeSelectorView(
                    selectedSize: $selectedBoardSize,
                    onConfirm: {
                        showBoardSizeSelector = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            startGame()
                        }
                    },
                    onCancel: {
                        showBoardSizeSelector = false
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Background
    private var premiumBackground: some View {
        ZStack {
            premiumGradient.ignoresSafeArea()
            
            Rectangle()
                .fill(LinearGradient(colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.02 : 0.08),
                    Color.black.opacity(colorScheme == .dark ? 0.02 : 0.01)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                .blendMode(.overlay)
                .opacity(0.6)
                .ignoresSafeArea()
                .scaleEffect(animateBackground ? 1.02 : 0.98)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animateBackground)
            
            LinearGradient(colors: [
                Color.black.opacity(colorScheme == .dark ? 0.35 : 0.15),
                .clear,
                Color.black.opacity(colorScheme == .dark ? 0.35 : 0.15)
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
            
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
        ticTacToeModel.setBoardSize(selectedBoardSize.rawValue)
        ticTacToeModel.playerToMove = .x
        appState.isGameOpen = true
        showGame = true
    }
}

// MARK: - Lobby Card
struct LobbyCard: View {
    let name: String
    let boardSize: BoardSize
    let timeLimit: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(name)
                        .font(.title2.bold())
                        .foregroundColor(isSelected ? boardSize.color : .primary)
                    
                    Text("Board Size: \(boardSize.title)")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                    
                    Text("Time Limit: \(timeLimit)")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("Join")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            colors: isSelected ? [boardSize.color, boardSize.color.opacity(0.8)] : [.gray.opacity(0.3), .gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? boardSize.color : .clear, lineWidth: 2)
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : .white)
                    .shadow(color: isSelected ? boardSize.color.opacity(0.3) : .black.opacity(0.1), radius: 12)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}



#Preview {
    MultiplayerMenuView()
        .environmentObject(AppState())
}
