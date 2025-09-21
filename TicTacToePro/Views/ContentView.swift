//
//  ContentView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 22/09/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView {
            NavigationStack {
                StartMenuView()
            }
            .tabItem {
                if appState.isGameOpen {
                    Label("Board", systemImage: "square.grid.3x3.fill")
                } else {
                    Label("Start", systemImage: "gamecontroller")
                }
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        
    }
}

#Preview {
    ContentView()
}

