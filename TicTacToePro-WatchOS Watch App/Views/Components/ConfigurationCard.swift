//
//  ConfigurationCard.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 20/09/25
//

import SwiftUI

struct ConfigurationCard: View {
    @Binding var selectedPlayer: PlayerOption
    @Binding var selectedGameMode: GameMode
    @Binding var selectedDifficulty: DifficultyOption
    @Binding var selectedBoardSize: BoardSize
    @Binding var selectedTimeLimit: TimeLimitOption
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                PlayerSelectionView(selectedPlayer: $selectedPlayer)
                GameModeSelectionView(selectedGameMode: $selectedGameMode)
                
                if !selectedGameMode.isPVP {
                    DifficultySelectionView(selectedDifficulty: $selectedDifficulty)
                }
                
                BoardSizeSelectionView(selectedSize: $selectedBoardSize)
                TimeLimitSelectionView(selectedTimeLimit: $selectedTimeLimit)
            }
            .padding(.vertical, 8)
        }
        .focusable() // Enable Digital Crown scrolling
    }
}

// MARK: - Player Selection View
struct PlayerSelectionView: View {
    @Binding var selectedPlayer: PlayerOption
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            Text("Starting Player")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(PlayerOption.allCases, id: \.self) { player in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPlayer = player
                        }
                    } label: {
                        let selectedBG = LinearGradient(
                            colors: [.pink.opacity(0.9), .purple.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        let unselectedBG = LinearGradient(
                            colors: [Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        Text(player.rawValue)
                            .font(.headline.bold())
                            .frame(width: 40, height: 40)
                            .background(selectedPlayer == player ? selectedBG : unselectedBG)
                            .foregroundStyle(selectedPlayer == player ? .white : .primary)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.pink, .purple],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: selectedPlayer == player ? 1.5 : 0
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Select \(player.rawValue) as starting player")
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Game Mode Selection View
struct GameModeSelectionView: View {
    @Binding var selectedGameMode: GameMode
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            Text("Game Mode")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedGameMode = mode
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: mode == .ai ? "cpu" : "person.2.fill")
                                .font(.system(size: 16))
                            Text(mode.rawValue)
                                .font(.system(size: 10).weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedGameMode == mode ? .thinMaterial : .ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    selectedGameMode == mode
                                        ? LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                                    lineWidth: selectedGameMode == mode ? 1.5 : 0
                                )
                        )
                        .foregroundStyle(selectedGameMode == mode ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(mode.rawValue) mode")
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Difficulty Selection View
struct DifficultySelectionView: View {
    @Binding var selectedDifficulty: DifficultyOption
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            Text("Difficulty")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 6) {
                ForEach(DifficultyOption.allCases, id: \.self) { difficulty in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDifficulty = difficulty
                        }
                    } label: {
                        Text(difficulty.rawValue)
                            .font(.system(size: 10).weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selectedDifficulty == difficulty ? .thinMaterial : .ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(
                                        selectedDifficulty == difficulty
                                            ? difficultyColor(difficulty)
                                            : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                                        lineWidth: selectedDifficulty == difficulty ? 1.5 : 0
                                    )
                            )
                            .foregroundStyle(
                                selectedDifficulty == difficulty
                                    ? difficultyColor(difficulty)
                                    : LinearGradient(colors: [.secondary], startPoint: .top, endPoint: .bottom)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(difficulty.rawValue) difficulty")
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    private func difficultyColor(_ difficulty: DifficultyOption) -> LinearGradient {
        switch difficulty {
        case .easy:
            return LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
        case .medium:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
        case .hard:
            return LinearGradient(colors: [.red, .pink], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Board Size Selection View
struct BoardSizeSelectionView: View {
    @Binding var selectedSize: BoardSize
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            Text("Board Size")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ], spacing: 6) {
                ForEach(BoardSize.allCases) { size in
                    BoardSizeItem(
                        size: size,
                        isSelected: selectedSize == size,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                            selectedSize = size
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

struct BoardSizeItem: View {
    let size: BoardSize
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(size.title)
                    .font(.system(size: 11).bold())
                    .foregroundColor(isSelected ? size.color : .primary)
                
                Text(size.difficulty)
                    .font(.system(size: 8).bold())
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(size.color.opacity(0.2))
                    )
                    .foregroundColor(size.color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected
                            ? LinearGradient(
                                colors: [size.color, size.color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: isSelected ? 1.5 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: isSelected)
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
}

// MARK: - Time Limit Selection View
struct TimeLimitSelectionView: View {
    @Binding var selectedTimeLimit: TimeLimitOption
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            Text("Time Limit")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ], spacing: 6) {
                ForEach(TimeLimitOption.allCases) { option in
                    TimeLimitItem(
                        timeLimit: option,
                        isSelected: selectedTimeLimit == option,
                        colorScheme: colorScheme
                    ) {
                        withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                            selectedTimeLimit = option
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

struct TimeLimitItem: View {
    let timeLimit: TimeLimitOption
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(timeLimit.title)
                    .font(.system(size: 11).bold())
                    .foregroundColor(isSelected ? timeLimit.color : .primary)
                
                Text(timeLimit.description)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected
                            ? LinearGradient(
                                colors: [timeLimit.color, timeLimit.color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: isSelected ? 1.5 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.spring(duration: 0.3, bounce: 0.4), value: isSelected)
        }
        .buttonStyle(.plain)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
}
