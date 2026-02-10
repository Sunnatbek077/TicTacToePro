//  ConfigurationCard.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//  Updated with enhanced design for both light and dark modes
//  tvOS optimized for remote control navigation
//

import SwiftUI

struct ConfigurationCard: View {
    @Binding var selectedPlayer: PlayerOption
    @Binding var selectedGameMode: GameMode
    @Binding var selectedDifficulty: DifficultyOption
    var isCompactHeightPhone: Bool
    var shadowColor: Color
    var cardBackground: AnyShapeStyle
    
    @GestureState private var dragOffset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero
    @State private var rotation: Double = 0.0
    @State private var isLongPressed = false
    @State private var glowRadius: CGFloat = 0
    @Namespace private var selectionNamespace
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color.pink.opacity(0.9), Color.purple.opacity(0.9), Color.blue.opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        let corner: CGFloat = 24
        
        VStack(spacing: isCompactHeightPhone ? 16 : 24) {
            PlayerSelectionView(selectedPlayer: $selectedPlayer)
            
            GameModeSelectionView(selectedGameMode: $selectedGameMode)
            
            if !selectedGameMode.isPVP {
                DifficultySelectionView(selectedDifficulty: $selectedDifficulty)
            }
        }
        .padding(isCompactHeightPhone ? 16 : 24)
        .background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(
                            LinearGradient(colors: [.white.opacity(colorScheme == .dark ? 0.10 : 0.18), .white.opacity(colorScheme == .dark ? 0.04 : 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Color.purple.opacity(isLongPressed ? 0.35 : 0), lineWidth: 6)
                .opacity(isLongPressed ? 1 : 0)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isLongPressed)
        )
        .offset(x: baseOffset.width + dragOffset.width, y: baseOffset.height + dragOffset.height)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(isLongPressed ? 1.03 : 1.0)
        #if !os(tvOS)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                    rotation = Double(value.translation.width / 50)
                }
                .onEnded { value in
                    let threshold: CGFloat = 100
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                        if abs(value.translation.width) > threshold {
                            selectedGameMode = selectedGameMode == .ai ? .pvp : .ai
                            baseOffset = CGSize(width: value.translation.width > 0 ? 300 : -300, height: 0)
                        } else {
                            baseOffset = .zero
                            rotation = 0.0
                        }
                    }
                    if abs(value.translation.width) > threshold {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring()) {
                                baseOffset = .zero
                                rotation = 0.0
                            }
                        }
                    }
                }
        )
        .onLongPressGesture(
            minimumDuration: 0.5,
            pressing: { pressing in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isLongPressed = pressing
                    glowRadius = pressing ? 12 : 0
                }
            },
            perform: {
            }
        )
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isLongPressed)
        #endif
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

// MARK: - Player Selection View
struct PlayerSelectionView: View {
    @Binding var selectedPlayer: PlayerOption
    @Environment(\.colorScheme) private var colorScheme
    #if os(tvOS)
    @FocusState private var focusedPlayer: PlayerOption?
    #endif
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Starting Player")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                ForEach(PlayerOption.allCases, id: \.self) { player in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPlayer = player
                        }
                    } label: {
                        #if os(tvOS)
                        // tvOS: optimized for remote control
                        Text(player.rawValue)
                            .font(.largeTitle.bold())
                            .frame(width: 120, height: 120)
                            .foregroundStyle(selectedPlayer == player ? .primary : .secondary)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color.primary.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(selectedPlayer == player ? Color.primary : Color.clear, lineWidth: 4)
                            )
                            .scaleEffect(focusedPlayer == player ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedPlayer)
                        #else
                        // iOS/macOS: rangli gradient
                        let selectedBG = LinearGradient(colors: [.pink.opacity(0.9), .purple.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                        let unselectedBG = LinearGradient(colors: [Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2)], startPoint: .top, endPoint: .bottom)
                        Text(player.rawValue)
                            .font(.title2.bold())
                            .frame(width: 60, height: 60)
                            .background(selectedPlayer == player ? selectedBG : unselectedBG)
                            .foregroundStyle(selectedPlayer == player ? .white : .primary)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom), lineWidth: selectedPlayer == player ? 2 : 0)
                            )
                            .shadow(color: .purple.opacity(selectedPlayer == player ? (colorScheme == .dark ? 0.4 : 0.2) : 0), radius: 4)
                            .animation(nil, value: selectedPlayer)
                        #endif
                    }
                    #if os(tvOS)
                    .buttonStyle(.card)
                    .focused($focusedPlayer, equals: player)
                    #endif
                    .accessibilityLabel("Select \(player.rawValue) as starting player")
                }
            }
        }
    }
}

// MARK: - Game Mode Selection View
struct GameModeSelectionView: View {
    @Binding var selectedGameMode: GameMode
    @Environment(\.colorScheme) private var colorScheme
    #if os(tvOS)
    @FocusState private var focusedMode: GameMode?
    #endif
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Game Mode")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedGameMode = mode
                        }
                    } label: {
                        #if os(tvOS)
                        // tvOS: optimized for remote control
                        VStack(spacing: 8) {
                            Image(systemName: mode == .ai ? "cpu" : "person.2.fill")
                                .font(.system(size: 40))
                            Text(mode.rawValue)
                                .font(.title3.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .foregroundStyle(selectedGameMode == mode ? .primary : .secondary)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.primary.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(selectedGameMode == mode ? Color.primary : Color.clear, lineWidth: 4)
                        )
                        .scaleEffect(focusedMode == mode ? 1.08 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedMode)
                        #else
                        // iOS/macOS: rangli
                        let selectedBG = LinearGradient(colors: [.purple.opacity(0.9), .blue.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                        let unselectedBG = LinearGradient(colors: [Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2)], startPoint: .top, endPoint: .bottom)
                        Text(mode.rawValue)
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedGameMode == mode ? selectedBG : unselectedBG)
                            .foregroundStyle(selectedGameMode == mode ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom), lineWidth: selectedGameMode == mode ? 2 : 0)
                            )
                            .shadow(color: .blue.opacity(selectedGameMode == mode ? (colorScheme == .dark ? 0.4 : 0.2) : 0), radius: 4)
                            .animation(nil, value: selectedGameMode)
                        #endif
                    }
                    #if os(tvOS)
                    .buttonStyle(.card)
                    .focused($focusedMode, equals: mode)
                    #endif
                    .accessibilityLabel("Select \(mode.rawValue) game mode")
                }
            }
        }
    }
}

// MARK: - Difficulty Selection View
struct DifficultySelectionView: View {
    @Binding var selectedDifficulty: DifficultyOption
    @Environment(\.colorScheme) private var colorScheme
    #if os(tvOS)
    @FocusState private var focusedDifficulty: DifficultyOption?
    #endif
    
    var body: some View {
        VStack(spacing: 8) {
            Text("AI Difficulty")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                ForEach(DifficultyOption.allCases, id: \.self) { difficulty in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDifficulty = difficulty
                        }
                    } label: {
                        #if os(tvOS)
                        // tvOS: optimized for remote control
                        VStack(spacing: 8) {
                            difficultyIcon(for: difficulty)
                                .font(.system(size: 35))
                            Text(difficulty.rawValue)
                                .font(.title3.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 130)
                        .foregroundStyle(selectedDifficulty == difficulty ? .primary : .secondary)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.primary.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(selectedDifficulty == difficulty ? Color.primary : Color.clear, lineWidth: 4)
                        )
                        .scaleEffect(focusedDifficulty == difficulty ? 1.08 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: focusedDifficulty)
                        #else
                        // iOS/macOS: rangli
                        let selectedBG = LinearGradient(colors: [.blue.opacity(0.9), .cyan.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                        let unselectedBG = LinearGradient(colors: [Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2)], startPoint: .top, endPoint: .bottom)
                        Text(difficulty.rawValue)
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedDifficulty == difficulty ? selectedBG : unselectedBG)
                            .foregroundStyle(selectedDifficulty == difficulty ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom), lineWidth: selectedDifficulty == difficulty ? 2 : 0)
                            )
                            .shadow(color: .cyan.opacity(selectedDifficulty == difficulty ? (colorScheme == .dark ? 0.4 : 0.2) : 0), radius: 4)
                            .animation(nil, value: selectedDifficulty)
                        #endif
                    }
                    #if os(tvOS)
                    .buttonStyle(.card)
                    .focused($focusedDifficulty, equals: difficulty)
                    #endif
                    .accessibilityLabel("Select \(difficulty.rawValue) difficulty")
                }
            }
        }
    }
    
    @ViewBuilder
    private func difficultyIcon(for difficulty: DifficultyOption) -> some View {
        switch difficulty {
        case .easy:
            Image(systemName: "hare.fill")
        case .medium:
            Image(systemName: "bolt.fill")
        case .hard:
            Image(systemName: "flame.fill")
        }
    }
}

#Preview {
    ConfigurationCard(
        selectedPlayer: .constant(.x),
        selectedGameMode: .constant(.ai),
        selectedDifficulty: .constant(.easy),
        isCompactHeightPhone: false,
        shadowColor: .gray,
        cardBackground: AnyShapeStyle(.ultraThinMaterial)
    )
}


