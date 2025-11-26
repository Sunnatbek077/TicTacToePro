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
                MultiplayerMenuView()
            }
            .tabItem {
                Label("Multiplayer", systemImage: "person.line.dotted.person")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        /// Force classic bottom tab bar style on iPad and iPhone
        .tabViewStyle(.sidebarAdaptable)
        .toolbar(.visible, for: .tabBar)            // keep tabbar visible
        .toolbarBackground(.visible, for: .tabBar)  // avoid transparent hiding
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}

