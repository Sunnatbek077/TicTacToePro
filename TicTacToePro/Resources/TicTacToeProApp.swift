//
//  TicTacToeProApp.swift
//  TicTacToePro
//
//  Updated with Firebase initialization and language selection
//

import SwiftUI
import FirebaseCore

@main
struct TicTacToeProApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var multiplayerVM = MultiplayerViewModel()
    
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @AppStorage("appLanguage") private var appLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
    
    @State private var showLanguageSelector = false
    @State private var needsRestart = false
    
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
        
        // Apply saved language immediately
        if let savedLanguages = UserDefaults.standard.stringArray(forKey: "AppleLanguages"),
           let firstLang = savedLanguages.first {
            print("🌍 Applying saved language: \(firstLang)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if needsRestart {
                    // Restart screen
                    RestartView()
                        .transition(.opacity)
                } else {
                    ContentView()
                        .environmentObject(appState)
                        .environmentObject(multiplayerVM)
                        .onAppear {
                            testFirebaseConnection()
                            checkFirstLaunch()
                        }
                    
                    // Language Selector Overlay
                    if showLanguageSelector {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .transition(.opacity)
                        
                        NavigationStack {
                            LanguageSelectorView(
                                isFirstLaunch: true,
                                onLanguageSelected: { selectedLanguage in
                                    print("🌍 Language selected: \(selectedLanguage)")
                                    handleLanguageSelection(selectedLanguage)
                                }
                            )
                            .interactiveDismissDisabled()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(100)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showLanguageSelector)
            .animation(.easeInOut(duration: 0.3), value: needsRestart)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleLanguageSelection(_ language: String) {
        withAnimation(.easeOut(duration: 0.3)) {
            hasLaunchedBefore = true
            showLanguageSelector = false
        }
        
        // Check if language actually changed
        let currentLang = Locale.current.language.languageCode?.identifier ?? "en"
        if language != currentLang {
            print("🔄 Language changed - restart needed")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    needsRestart = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    restartApp()
                }
            }
        } else {
            print("✅ Language unchanged - no restart needed")
        }
    }
    
    private func checkFirstLaunch() {
        if !hasLaunchedBefore {
            print("👋 First launch detected - showing language selector")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    showLanguageSelector = true
                }
            }
        } else {
            print("✅ Returning user - skipping language selector")
        }
    }
    
    private func restartApp() {
        print("🔄 Restarting app...")
        #if os(iOS)
        exit(0)
        #endif
    }
    
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

