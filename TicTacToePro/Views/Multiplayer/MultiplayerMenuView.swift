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
    
    @StateObject private var multiplayerVM = MultiplayerViewModel()
    @StateObject private var viewModel = ViewModel()
    @StateObject private var ticTacToeModel = GameViewModel()
    
    @State private var selectedBoardSize: BoardSize = .small
    @State private var selectedTimeLimit: TimeLimitOption = .tenMinutes
    @State private var gameName: String = ""
    @State private var isPrivateGame: Bool = false
    @State private var roomCodeInput: String = ""
    
    // Sheet states
    @State private var showCreateGameSheet = false
    @State private var showGameNameSheet = false
    @State private var showBoardSizeSelector = false
    @State private var showTimeLimitSelector = false
    @State private var showJoinByCodeSheet = false
    @State private var showGame = false
    @State private var animateBackground = false
    
#if os(iOS)
    @State private var hapticsEngine: CHHapticEngine?
#endif
    
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
                        // Header
                        headerSection
                        
                        // Connection Status
                        connectionStatusView
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Available Games List
                        gamesListSection
                    }
                    .padding(.horizontal, isCompactHeightPhone ? 12 : 16)
                    .padding(.vertical, verticalPadding)
                    .padding(.top, layoutCategory == "tall" ? 48 : 32)
                    .frame(maxWidth: contentMaxWidth)
                }
                .refreshable {
                    await multiplayerVM.refreshGames()
                }
                
                // Loading overlay
                if multiplayerVM.isLoading {
                    LoadingOverlay()
                }
            }
            .navigationTitle("Multiplayer")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $multiplayerVM.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(multiplayerVM.errorMessage ?? "Unknown error")
            }
            .sheet(isPresented: $showGameNameSheet) {
                GameNameInputSheet(
                    gameName: $gameName,
                    isPrivate: $isPrivateGame,
                    onNext: {
                        showGameNameSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showBoardSizeSelector = true
                        }
                    },
                    onCancel: {
                        showGameNameSheet = false
                    }
                )
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
            }
            .sheet(isPresented: $showTimeLimitSelector) {
                TimeLimitSelectorView(
                    selectedTimeLimit: $selectedTimeLimit,
                    onConfirm: {
                        showTimeLimitSelector = false
                        Task {
                            await createGame()
                        }
                    },
                    onCancel: {
                        showTimeLimitSelector = false
                    }
                )
            }
            .sheet(isPresented: $showJoinByCodeSheet) {
                JoinByCodeSheet(
                    roomCode: $roomCodeInput,
                    onJoin: {
                        showJoinByCodeSheet = false
                        Task {
                            await multiplayerVM.joinGameByCode(roomCodeInput)
                            if multiplayerVM.currentGame != nil {
                                showGame = true
                            }
                        }
                    },
                    onCancel: {
                        showJoinByCodeSheet = false
                    }
                )
            }
            .fullScreenCover(isPresented: $showGame) {
                MultiplayerGameView(
                    game: multiplayerVM.currentGame!,
                    multiplayerVM: multiplayerVM,
                    onExit: {
                        multiplayerVM.leaveGame()
                        showGame = false
                    }
                )
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("🎮 Online Multiplayer")
                .font(headerFont)
                .foregroundStyle(accentGradient)
            
            Text("Play with friends worldwide")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Connection Status
    private var connectionStatusView: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(multiplayerVM.connectionStatus.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
        )
    }
    
    private var statusColor: Color {
        switch multiplayerVM.connectionStatus {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            // Create Game Button
            Button {
                triggerHaptic()
                showGameNameSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Create New Game")
                        .font(.headline.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .purple.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            
            // Join by Code Button
            Button {
                triggerHaptic()
                showJoinByCodeSheet = true
            } label: {
                HStack {
                    Image(systemName: "keyboard")
                        .font(.title2)
                    Text("Join by Code")
                        .font(.headline)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Games List Section
    private var gamesListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Available Games")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(publicGames.count) games")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if publicGames.isEmpty {
                EmptyGamesView()
            } else {
                ForEach(publicGames) { game in
                    GameLobbyCard(
                        game: game,
                        colorScheme: colorScheme,
                        onJoin: {
                            triggerHaptic()
                            Task {
                                await multiplayerVM.joinGame(gameId: game.id)
                                if multiplayerVM.currentGame != nil {
                                    showGame = true
                                }
                            }
                        }
                    )
                }
            }
        }
    }
    
    // Filter only public games
    private var publicGames: [GameListItem] {
        multiplayerVM.availableGames.filter { !$0.isPrivate }
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
    
    // MARK: - Game Logic
    private func createGame() async {
        await multiplayerVM.createGame(
            gameName: gameName,
            boardSize: selectedBoardSize.rawValue,
            timeLimit: selectedTimeLimit.rawValue > 0 ? TimeInterval(selectedTimeLimit.rawValue * 60) : nil,
            turnTimeLimit: 30,
            isPrivate: isPrivateGame
        )
        
        if multiplayerVM.currentGame != nil {
            showGame = true
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
}

// MARK: - Supporting Views

struct GameLobbyCard: View {
    let game: GameListItem
    let colorScheme: ColorScheme
    let onJoin: () -> Void
    
    var body: some View {
        Button(action: onJoin) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Status indicator
                    Circle()
                        .fill(game.status == .waiting ? Color.green : Color.yellow)
                        .frame(width: 10, height: 10)
                    
                    Text(game.player1Username)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Room code for public games only
                    if !game.isPrivate, let code = game.roomCode {
                        Text(code)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }
                    
                    // Private indicator
                    if game.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 16) {
                    // Board size
                    Label("\(game.boardSize)x\(game.boardSize)", systemImage: "square.grid.3x3")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Players
                    Label("\(game.player2Username != nil ? "2" : "1")/2", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Spectators
                    if game.spectatorCount > 0 {
                        Label("\(game.spectatorCount)", systemImage: "eye")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Join button
                    Text(game.status == .waiting ? "Join" : "Watch")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct EmptyGamesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No active games")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Be the first to create a game!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Loading...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

struct GameNameInputSheet: View {
    @Binding var gameName: String
    @Binding var isPrivate: Bool
    let onNext: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
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
                        Text("Create New Game")
                            .font(.title2.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Give your game a unique name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Game Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Game Name")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("e.g., Epic Battle", text: $gameName)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isFocused ? Color.purple : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                            .focused($isFocused)
                    }
                    .padding(.horizontal)
                    
                    // Privacy Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $isPrivate) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Private Game")
                                    .font(.headline)
                                
                                Text("Only players with room code can join")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tint(.purple)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action Buttons
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
                        
                        Button(action: onNext) {
                            HStack {
                                Text("Next")
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
                        .disabled(gameName.isEmpty)
                        .opacity(gameName.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

struct JoinByCodeSheet: View {
    @Binding var roomCode: String
    let onJoin: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
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
                        Image(systemName: "keyboard")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Enter Room Code")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Text("6-digit code from your friend")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Room Code Input
                    TextField("ABC123", text: $roomCode)
                        .textFieldStyle(.plain)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .textCase(.uppercase)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isFocused ? Color.purple : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                        .padding(.horizontal)
                        .focused($isFocused)
                        .onChange(of: roomCode) { _, newValue in
                            roomCode = String(newValue.prefix(6).uppercased())
                        }
                    
                    Spacer()
                    
                    // Action Buttons
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
                        
                        Button(action: onJoin) {
                            HStack {
                                Text("Join Game")
                                    .font(.headline.bold())
                                Image(systemName: "arrow.right.circle.fill")
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
                        .disabled(roomCode.count != 6)
                        .opacity(roomCode.count != 6 ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - Time Limit Selector View
struct TimeLimitSelectorView: View {
    @Binding var selectedTimeLimit: TimeLimitOption
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
                    Text("Choose Time Limit")
                        .font(.title2.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Select the duration for your game")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Time Limit Options
                TimeLimitView(selectedTimeLimit: $selectedTimeLimit)
                
                // Action Buttons
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
                            Text("Confirm")
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

#Preview {
    MultiplayerMenuView()
        .environmentObject(AppState())
}
