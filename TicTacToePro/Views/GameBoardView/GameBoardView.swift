//
//  GameBoardView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//  Updated with enhanced premium design on 01/10/25
//  Optimized for small 16:9 iPhones (e.g., iPhone SE 2nd/3rd gen) on 02/10/25
//  Fixed scope and range errors on 02/10/25
//  Enlarged board size for SE on 02/10/25
//

import SwiftUI
import Combine
import Foundation

struct GameBoardView: View {
    var onExit: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var hSizeClass
    @Environment(\.verticalSizeClass) var vSizeClass
    
    @ObservedObject var viewModel: ViewModel
    @ObservedObject var ticTacToe: GameViewModel
    
    let gameTypeIsPVP: Bool
    let difficulty: AIDifficulty
    let startingPlayerIsO: Bool
    
    // Local (session-only) scoreboard
    @State var xWins: Int = 0
    @State var oWins: Int = 0
    @State var ties: Int = 0
    
    // Local transient states
    @State var vibro: Bool = false
    @State var showTurnBanner: Bool = false
    @State var showConfetti: Bool = false
    @State var aiThinking: Bool = false
    @State var animateWinningGlow: Bool = false
    @State var recentlyPlacedIndex: Int? = nil
    @State var animateBoardEntrance: Bool = false
    
    var body: some View {
        ZStack {
            premiumBackground
                .ignoresSafeArea()
            
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        animateBoardEntrance = true
                    }
                    setupGame()
                }
                .onChange(of: ticTacToe.gameOver) { handleGameOverChanged($1) }
                .onChange(of: ticTacToe.playerToMove) { _ in handlePlayerToMoveChanged() }
                .alert(Text(gameOverAlertTitle), isPresented: $ticTacToe.gameOver) {
                    Button("Play Again", action: resetForNextRound)
                    Button("Leave", action: exitToMenu)
                }
            
            if showConfetti {
                ConfettiView(isSELikeSmallScreen: isSELikeSmallScreen)
                    .transition(.opacity)
                    .zIndex(3)
            }
            
            if showTurnBanner {
                turnBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: exitToMenu) {
                Label("Leave", systemImage: "xmark")
            }
            .accessibilityLabel("Leave")
        }
    }
}
