//
//  StartMenuView.swift - Updated with Board Size Selector
//  TicTacToePro
//

import SwiftUI
#if os(iOS)
import CoreHaptics
#endif

// MARK: - Board Size Options
enum BoardSize: Int, CaseIterable, Identifiable {
    case small = 3
    case medium = 4
    case large = 5
    case xlarge = 6
    case xxlarge = 7
    case huge = 8
    case massive = 9
    
    var id: Int { rawValue }
    
    var title: String {
        "\(rawValue)×\(rawValue)"
    }
    
    var description: String {
        switch self {
        case .small: return "Classic"
        case .medium: return "Challenging"
        case .large: return "Strategic"
        case .xlarge: return "Expert"
        case .xxlarge: return "Master"
        case .huge: return "Extreme"
        case .massive: return "Legendary"
        }
    }
    
    var emoji: String {
        switch self {
        case .small: return "🎯"
        case .medium: return "🎮"
        case .large: return "🧩"
        case .xlarge: return "🎲"
        case .xxlarge: return "🏆"
        case .huge: return "⭐️"
        case .massive: return "👑"
        }
    }
    
    var difficulty: String {
        switch self {
        case .small: return "Easy"
        case .medium: return "Medium"
        case .large: return "Hard"
        case .xlarge, .xxlarge: return "Very Hard"
        case .huge, .massive: return "Extreme"
        }
    }
    
    var color: Color {
        switch self {
        case .small: return .green
        case .medium: return .blue
        case .large: return .purple
        case .xlarge: return .orange
        case .xxlarge: return .red
        case .huge: return .pink
        case .massive: return .indigo
        }
    }
}

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
    
    // NEW: Board size selection
    @State private var showBoardSizeSelector = false
    @State private var selectedBoardSize: BoardSize = .small
    @State private var selectedTimeLimit: TimeLimitOption = .tenMinutes
    @State private var showTimeLimitSelector = false
    
    @StateObject private var viewModel = ViewModel()
    @StateObject private var ticTacToeModel = GameViewModel()
#if os(iOS)
    @State private var hapticsEngine: CHHapticEngine?
#endif
    
    private var startingPlayerIsO: Bool { selectedPlayer == .o }
    
    private var configurationSummary: String {
        selectedGameMode.isPVP
        ? "PvP • \(selectedPlayer.rawValue) starts • \(selectedBoardSize.title)"
        : "AI: \(startingPlayerIsO ? "X" : "O") • \(selectedDifficulty.rawValue) • \(selectedBoardSize.title)"
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
                                    : Color.blue.opacity(0.08),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: premiumShadow.0, radius: premiumShadow.1, x: 0, y: premiumShadow.2)
                        .padding(.top, isCompactHeightPhone ? 4 : 8)
                        .transition(.scale.combined(with: .opacity))
                        
                        StartButton(isCompactHeightPhone: isCompactHeightPhone) {
                            triggerHaptic()
                            showBoardSizeSelector = true
                        }
                        .padding(layoutCategory == "tall" ? 20 : 12)
                        .background(RoundedRectangle(cornerRadius: 20).fill(accentGradient.opacity(colorScheme == .dark ? 0.18 : 0.24)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
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
                    .animation(.spring(duration: 0.8, bounce: 0.2), value: selectedGameMode)
                    .navigationDestination(isPresented: $showGame) {
                        GameBoardView(
                            onExit: { showGame = false },
                            viewModel: viewModel,
                            ticTacToe: ticTacToeModel,
                            gameTypeIsPVP: selectedGameMode.isPVP,
                            difficulty: selectedDifficulty.mapped,
                            startingPlayerIsO: startingPlayerIsO,
                            timeLimit: selectedTimeLimit
                        )
#if !os(tvOS)
                        .navigationBarTitleDisplayMode(.inline)
#endif
                        .onDisappear { appState.isGameOpen = false }
                    }
                }
            }
            
            .sheet(isPresented: $showBoardSizeSelector) {
                BoardSizeSelectorView(
                    selectedSize: $selectedBoardSize,
                    onConfirm: {
                        showBoardSizeSelector = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showTimeLimitSelector = true
                        }
                    },
                    onCancel: {
                        showBoardSizeSelector = false
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showTimeLimitSelector) {
                TimeLimitSelectorView(
                    selectedTimeLimit: $selectedTimeLimit,
                    onConfirm: {
                        showTimeLimitSelector = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            startGame()
                        }
                    },
                    onCancel: {
                        showTimeLimitSelector = false
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Backgrounds
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
    
    private var bokehLayer: some View {
        ZStack {
            Circle().fill((colorScheme == .dark ? Color.pink : Color.pink.opacity(0.25)))
                .frame(width: 220).blur(radius: 60).offset(x: -140, y: -180)
            Circle().fill((colorScheme == .dark ? Color.blue : Color.blue.opacity(0.22)))
                .frame(width: 260).blur(radius: 70).offset(x: 160, y: -120)
            Circle().fill((colorScheme == .dark ? Color.purple : Color.purple.opacity(0.24)))
                .frame(width: 280).blur(radius: 80).offset(x: 120, y: 220)
            Circle().fill((colorScheme == .dark ? Color.cyan.opacity(0.8) : Color.cyan.opacity(0.18)))
                .frame(width: 150).blur(radius: 50).offset(x: -80, y: 180)
            Circle().fill((colorScheme == .dark ? Color.indigo : Color.indigo.opacity(0.20)))
                .frame(width: 180).blur(radius: 55).offset(x: 200, y: 100)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateBackground)
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
        if !selectedGameMode.isPVP {
            ticTacToeModel.aiPlays = startingPlayerIsO ? .x : .o
        }
        ticTacToeModel.playerToMove = startingPlayerIsO ? .o : .x
        // Optional: ticTacToeModel.timeLimitMinutes = selectedTimeLimit.rawValue
        appState.isGameOpen = true
        showGame = true
    }
}

// MARK: - Board Size Selector View
struct BoardSizeSelectorView: View {
    @Binding var selectedSize: BoardSize
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            // Premium background
            LinearGradient(
                colors: colorScheme == .dark
                ? [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.11, green: 0.12, blue: 0.18)]
                : [Color(red: 0.95, green: 0.96, blue: 0.99), Color(red: 0.90, green: 0.92, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose Board Size")
                        .font(.title2.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Select the grid size for your game")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Board size options
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(BoardSize.allCases) { size in
                            BoardSizeCard(
                                size: size,
                                isSelected: selectedSize == size,
                                colorScheme: colorScheme
                            ) {
                                withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                                    selectedSize = size
                                }
#if os(iOS)
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
#endif
                            }
                            .scaleEffect(animateIn ? 1 : 0.8)
                            .opacity(animateIn ? 1 : 0)
                            .animation(
                                .spring(duration: 0.5, bounce: 0.4)
                                .delay(Double(size.rawValue - 3) * 0.05),
                                value: animateIn
                            )
                        }
                    }
                    .padding()
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }
                    
                    Button(action: onConfirm) {
                        HStack {
                            Text("Start Game")
                                .font(.headline.bold())
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.pink, .purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .purple.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            animateIn = true
        }
    }
}

// MARK: - Board Size Card
struct BoardSizeCard: View {
    let size: BoardSize
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected
                                ? [size.color.opacity(0.8), size.color]
                                : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: isSelected ? size.color.opacity(0.5) : .clear, radius: 10)
                    
                    Text(size.emoji)
                        .font(.system(size: 32))
                }
                
                // Title
                Text(size.title)
                    .font(.title3.bold())
                    .foregroundColor(isSelected ? size.color : .primary)
                
                // Description
                Text(size.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Difficulty badge
                Text(size.difficulty)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(size.color.opacity(0.2))
                    )
                    .foregroundColor(size.color)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : .white)
                    .shadow(color: isSelected ? size.color.opacity(0.3) : .black.opacity(0.1), radius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isSelected
                        ? LinearGradient(colors: [size.color, size.color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: isSelected ? 3 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StartMenuView()
        .environmentObject(AppState())
}
