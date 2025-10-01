//
//  ConfigurationCard.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//  Updated with enhanced design for both light and dark modes
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
        VStack(spacing: isCompactHeightPhone ? 16 : 24) {
            PlayerSelectionView(selectedPlayer: $selectedPlayer)
            
            GameModeSelectionView(selectedGameMode: $selectedGameMode)
            
            if !selectedGameMode.isPVP {
                DifficultySelectionView(selectedDifficulty: $selectedDifficulty)
            }
        }
        .padding(isCompactHeightPhone ? 16 : 24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(accentGradient, lineWidth: 1.5) // Gradient border for vibrancy
                        .opacity(colorScheme == .dark ? 0.2 : 0.3) // Adjusted opacity
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.purple.opacity(isLongPressed ? 0.8 : 0), lineWidth: 2)
                .blur(radius: glowRadius)
                .shadow(color: .purple.opacity(colorScheme == .dark ? 0.4 : 0.25), radius: 20) // Softer shadow in light mode
        )
        .offset(x: baseOffset.width + dragOffset.width, y: baseOffset.height + dragOffset.height)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(isLongPressed ? 1.03 : 1.0) // Slightly increased scale for feedback
        .animation(.easeInOut(duration: 0.3), value: isLongPressed)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: glowRadius)
        .animation(.spring(dampingFraction: 0.7), value: baseOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, transaction in
                    state = value.translation
                    rotation = Double(value.translation.width / 50)
                    transaction.animation = .easeOut(duration: 0.1)
                }
                .onEnded { value in
                    let threshold: CGFloat = 100
                    if abs(value.translation.width) > threshold {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            selectedGameMode = selectedGameMode == .ai ? .pvp : .ai
                            baseOffset = CGSize(width: value.translation.width > 0 ? 300 : -300, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring()) {
                                baseOffset = .zero
                                rotation = 0.0
                            }
                        }
                    } else {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                            baseOffset = .zero
                            rotation = 0.0
                        }
                    }
                }
        )
        .onLongPressGesture(
            minimumDuration: 0.5,
            pressing: { pressing in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isLongPressed = pressing
                    glowRadius = pressing ? 12 : 0 // Slightly larger glow
                }
            },
            perform: {
                print("Long press completed")
            }
        )
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isLongPressed) // Added haptic feedback
    }
}

// MARK: - Player Selection View
struct PlayerSelectionView: View {
    @Binding var selectedPlayer: PlayerOption
    @Environment(\.colorScheme) private var colorScheme
    
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
                        Text(player.rawValue)
                            .font(.title2.bold())
                            .frame(width: 60, height: 60)
                            .background(
                                selectedPlayer == player
                                ? LinearGradient(colors: [.pink.opacity(0.9), .purple.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2)], startPoint: .top, endPoint: .bottom)
                            )
                            .foregroundStyle(selectedPlayer == player ? .white : .primary)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom), lineWidth: selectedPlayer == player ? 2 : 0)
                            )
                            .shadow(color: .purple.opacity(selectedPlayer == player ? (colorScheme == .dark ? 0.4 : 0.2) : 0), radius: 6)
                    }
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
                        Text(mode.rawValue)
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedGameMode == mode
                                ? LinearGradient(colors: [.purple.opacity(0.9), .blue.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2)], startPoint: .top, endPoint: .bottom)
                            )
                            .foregroundStyle(selectedGameMode == mode ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom), lineWidth: selectedGameMode == mode ? 2 : 0)
                            )
                            .shadow(color: .blue.opacity(selectedGameMode == mode ? (colorScheme == .dark ? 0.4 : 0.2) : 0), radius: 6)
                    }
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
                        Text(difficulty.rawValue)
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                selectedDifficulty == difficulty
                                ? LinearGradient(colors: [.blue.opacity(0.9), .cyan.opacity(0.9)], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2)], startPoint: .top, endPoint: .bottom)
                            )
                            .foregroundStyle(selectedDifficulty == difficulty ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom), lineWidth: selectedDifficulty == difficulty ? 2 : 0)
                            )
                            .shadow(color: .cyan.opacity(selectedDifficulty == difficulty ? (colorScheme == .dark ? 0.4 : 0.2) : 0), radius: 6)
                    }
                    .accessibilityLabel("Select \(difficulty.rawValue) difficulty")
                }
            }
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
