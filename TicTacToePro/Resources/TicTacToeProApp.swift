//
//  TicTacToeProApp.swift
//  TicTacToePro
//
//  Updated with Firebase initialization and debugging
//

import SwiftUI
import FirebaseCore

@main
struct TicTacToeProApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var multiplayerVM = MultiplayerViewModel()
    
    init() {
        // Configure Firebase on app launch
        print("🚀 Starting Firebase configuration...")

        // Check if Firebase is already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("✅ Firebase configured successfully")
        } else {
            print("✅ Firebase already configured")
        }

        // Verify configuration
        if let app = FirebaseApp.app() {
            print("📱 Firebase App Name: \(app.name)")
            print("📱 Firebase Options: \(app.options)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(multiplayerVM)
                .onAppear {
                    testFirebaseConnection()
                }
        }
    }
    
    // MARK: - Helper Methods
    
    private func testFirebaseConnection() {
        #if DEBUG
        print("🔍 Starting Firebase connection test...")
        
        Task {
            do {
                let firebaseManager = FirebaseManager.shared
                print("🔐 FirebaseManager initialized")
                print("🔐 Current auth state: \(firebaseManager.isAuthenticated)")
                
                if !firebaseManager.isAuthenticated {
                    print("🔐 Attempting anonymous sign-in...")
                    let user = try await firebaseManager.signInAnonymously()
                    print("✅ Authentication successful!")
                    print("   User ID: \(user.id)")
                    print("   Username: \(user.username)")
                    print("   Is Anonymous: \(user.isAnonymous)")
                }
            } catch let error as NSError {
                print("❌ Firebase authentication failed!")
                print("   Domain: \(error.domain)")
                print("   Code: \(error.code)")
                print("   Description: \(error.localizedDescription)")
                print("   UserInfo: \(error.userInfo)")
                
                // Check for specific error codes
                switch error.code {
                case 17999:
                    print("💡 This is an internal error - likely a configuration issue")
                    print("💡 Check: GoogleService-Info.plist and Firebase Console settings")
                case 17020:
                    print("💡 Network error - check internet connection")
                case 17011:
                    print("💡 User not found")
                default:
                    print("💡 Unknown error code: \(error.code)")
                }
            }
        }
        #endif
    }
}

