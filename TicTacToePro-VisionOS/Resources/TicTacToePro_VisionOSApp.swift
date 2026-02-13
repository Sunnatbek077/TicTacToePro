//
//  TicTacToePro_VisionOSApp.swift
//  TicTacToePro-VisionOS
//
//  Created by Sunnatbek on 13/02/26.
//

import SwiftUI

@main
struct TicTacToePro_VisionOSApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
