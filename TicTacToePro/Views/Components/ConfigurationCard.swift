//
//  ConfigurationCard.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import SwiftUI

struct ConfigurationCard: View {
    @Binding var selectedPlayer: PlayerOption
    @Binding var selectedGameMode: GameMode
    @Binding var selectedDifficulty: DifficultyOption
    
    let isCompactHeightPhone: Bool
    let shadowColor: Color
    let cardBackground: AnyShapeStyle
    
    var body: some View {
        VStack(spacing: isCompactHeightPhone ? 16 : 20) {
            playerPicker
            gameModePicker
            difficultyPicker
        }
        .padding(isCompactHeightPhone ? 14 : 18)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1))
        .shadow(color: shadowColor.opacity(0.06), radius: 10, x: 0, y: 6)
        .animation(.easeInOut(duration: 0.2), value: selectedGameMode)
        .animation(.easeInOut(duration: 0.2), value: selectedDifficulty)
        .animation(.easeInOut(duration: 0.2), value: selectedPlayer)
    }
    
    private var playerPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HeaderRow(title: "Player", value: selectedPlayer.rawValue)
            
            Picker("Player", selection: $selectedPlayer) {
                ForEach(PlayerOption.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)
            
            Text("Choose whether you play as X or O. X moves first.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    private var gameModePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HeaderRow(title: "Game Mode", value: selectedGameMode.rawValue)
            
            Picker("Mode", selection: $selectedGameMode) {
                ForEach(GameMode.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedGameMode) { _, newValue in
                if newValue == .pvp, selectedPlayer != .x {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedPlayer = .x
                    }
                }
            }
            
            Text("Play against AI or with a friend on the same device.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    private var difficultyPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HeaderRow(title: "AI Difficulty", value: selectedDifficulty.rawValue)
                .opacity(selectedGameMode.isPVP ? 0.5 : 1.0)
            
            Picker("Difficulty", selection: $selectedDifficulty) {
                ForEach(DifficultyOption.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)
            .disabled(selectedGameMode.isPVP)
            .opacity(selectedGameMode.isPVP ? 0.5 : 1.0)
            
            Text("Hard plays optimally using minimax.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .opacity(selectedGameMode.isPVP ? 0.5 : 1.0)
        }
    }
}
