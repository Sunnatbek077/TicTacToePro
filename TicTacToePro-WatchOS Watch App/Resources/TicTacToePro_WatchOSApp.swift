//
//  TicTacToePro_WatchOSApp.swift
//  TicTacToePro-WatchOS
//
//  Created by Sunnatbek on 13/02/26.
//

import SwiftUI

@main
struct TicTacToePro_WatchOSApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
