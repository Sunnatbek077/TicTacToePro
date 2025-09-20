//
//  ContentView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedPlayer: PlayerOption = .x
    @State private var selectedDifficulty: DifficultyOption = .easy
    @State private var selectedGameMode: GameMode = .ai
    @State private var showGame: Bool = false
    @State private var showAboutDevs: Bool = false
    
    @StateObject private var viewModel = ViewModel()
    @StateObject private var ticTacToeModel = GameViewModel()
    
    private var startingPlayerIsO: Bool { selectedPlayer == .o }
    
    private var configurationSummary: String {
        selectedGameMode.isPVP
        ? "PvP • \(selectedPlayer.rawValue) starts"
        : "AI: \(startingPlayerIsO ? "X" : "O") • \(selectedDifficulty.rawValue)"
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
        hSizeClass == .regular ? 700 : (isCompactHeightPhone ? 380 : 500)
        #endif
    }
    
    private var cardBackground: AnyShapeStyle {
        #if os(macOS)
        AnyShapeStyle(.regularMaterial)
        #elseif os(visionOS)
        AnyShapeStyle(.thinMaterial)
        #else
        AnyShapeStyle(.thinMaterial)
        #endif
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .black : .gray
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                background
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isCompactHeightPhone ? 16 : 24) {
                        HeroHeader(isCompactHeightPhone: isCompactHeightPhone,
                                   configurationSummary: configurationSummary)
                        
                        ConfigurationCard(
                            selectedPlayer: $selectedPlayer,
                            selectedGameMode: $selectedGameMode,
                            selectedDifficulty: $selectedDifficulty,
                            isCompactHeightPhone: isCompactHeightPhone,
                            shadowColor: shadowColor,
                            cardBackground: cardBackground
                        )
                        
                        StartButton(isCompactHeightPhone: isCompactHeightPhone) {
                            startGame()
                        }
                        
                        Button {
                            showAboutDevs = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "person.circle.fill").imageScale(.large)
                                Text("About Developer").font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isCompactHeightPhone ? 10 : 14)
                            .padding(.horizontal, 12)
                            
                            .shadow(color: Color.accentColor.opacity(0.35), radius: 10, x: 0, y: 6)
                        }
                        .buttonStyle(.glass)
                    }
                    .padding(.horizontal, isCompactHeightPhone ? 12 : 16)
                    .padding(.vertical, isCompactHeightPhone ? 16 : 24)
                    .frame(maxWidth: contentMaxWidth)
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
                    }
                }
            }
            .navigationTitle("Tic Tac Toe")
            .navigationBarTitleDisplayMode(.inline)
            
        }
    }
    
    private var background: some View {
        Group {
            #if os(macOS)
            Color(nsColor: .windowBackgroundColor)
            #elseif os(visionOS)
            Color.clear
            #else
            Color(UIColor.systemGroupedBackground)
            #endif
        }
        .ignoresSafeArea()
    }
    
    private func startGame() {
        ticTacToeModel.resetGame()
        
        if !selectedGameMode.isPVP {
            ticTacToeModel.aiPlays = startingPlayerIsO ? .x : .o
        }
        ticTacToeModel.playerToMove = startingPlayerIsO ? .o : .x
        showGame = true
    }
}

#Preview {
    ContentView()
}
