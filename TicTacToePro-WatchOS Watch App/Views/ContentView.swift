//
//  ContentView.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 22/09/25.
//
//  watchOS navigation pattern:
//  - .tabViewStyle(.page) → horizontal swipe between tabs
//  - Tab indicators shown as dots at the bottom (system default)
//  - NavigationStack inside each page keeps push-navigation working
//  - No tabItem labels (watchOS page-style doesn't support them)
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: Tab = .start

    enum Tab { case start, settings }

    var body: some View {
        TabView(selection: $selectedTab) {

            // ── Page 1: Start / Game ───────────────────────────────────
            NavigationStack {
                StartMenuView()
            }
            .tag(Tab.start)

            // ── Page 2: Settings ───────────────────────────────────────
            NavigationStack {
                SettingsView()
            }
            .tag(Tab.settings)
        }
        .tabViewStyle(.page)                   // horizontal swipe navigation
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
