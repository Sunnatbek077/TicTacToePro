//
//  SettingsView.swift
//  TicTacToePro
//
//  Created by Sunnatbek
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var multiplayerVM: MultiplayerViewModel
    
    // Settings states
    @AppStorage(HapticManager.hapticsEnabledKey) private var hapticsEnabled = false
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("showAnimations") private var showAnimations = true
    @AppStorage("defaultBoardSize") private var defaultBoardSize = 3
    @AppStorage("colorSchemePreference") private var colorSchemePreference = "system"
    
    @State private var showResetAlert = false
    @State private var showAbout = false
    @State private var showProfile = false
    // Removed: unused background animation state
    
    // Layout helpers
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
        hSizeClass == .regular ? 700 : (isCompactHeightPhone ? 360 : 500)
#endif
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                premiumBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isCompactHeightPhone ? 16 : 24) {
                        // Header
                        headerSection
                        
                        // Gameplay Settings
                        gameplaySection
                        
                        // Appearance Settings
                        appearanceSection
                        
                        // Audio & Haptics
                        audioHapticsSection
                        
                        // Advanced Settings
                        advancedSection
                        
                        // About & Support
                        aboutSection
                        
                        // Reset Settings
                        resetSection
                        
                        // Version Info
                        versionSection
                    }
                    .padding(.horizontal, isCompactHeightPhone ? 12 : 16)
                    .padding(.vertical, isCompactHeightPhone ? 16 : 24)
                    .frame(maxWidth: contentMaxWidth)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset All Settings?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllSettings()
                }
            } message: {
                Text("This will reset all settings to their default values. This action cannot be undone.")
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
        // Apply preferred color scheme according to user preference
        .preferredColorScheme(resolvedColorScheme)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Customize your experience")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // MARK: - Gameplay Section
    private var gameplaySection: some View {
        SettingsCard(title: "Gameplay", icon: "gamecontroller.fill") {
            VStack(spacing: 0) {
                // Default Board Size
                SettingsRow(
                    icon: "square.grid.3x3",
                    title: "Default Board Size",
                    iconColor: .blue
                ) {
                    Picker("Board Size", selection: $defaultBoardSize) {
                        Text("3×3").tag(3)
                        Text("4×4").tag(4)
                        Text("5×5").tag(5)
                        Text("6×6").tag(6)
                    }
                    .pickerStyle(.menu)
                    .tint(.blue)
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Show Animations
                SettingsToggleRow(
                    icon: "sparkles",
                    title: "Animations",
                    description: "Enable visual animations",
                    iconColor: .purple,
                    isOn: $showAnimations
                )
            }
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        SettingsCard(title: "Appearance", icon: "paintbrush.fill") {
            VStack(spacing: 0) {
                // Color Scheme
                SettingsRow(
                    icon: colorSchemeIcon,
                    title: "Theme",
                    iconColor: .orange
                ) {
                    Picker("Theme", selection: $colorSchemePreference) {
                        Label("System", systemImage: "circle.lefthalf.filled")
                            .tag("system")
                        Label("Light", systemImage: "sun.max.fill")
                            .tag("light")
                        Label("Dark", systemImage: "moon.fill")
                            .tag("dark")
                    }
                    .pickerStyle(.menu)
                    .tint(.orange)
                }
            }
        }
    }
    
    // MARK: - Audio & Haptics Section
    private var audioHapticsSection: some View {
        SettingsCard(title: "Audio & Haptics", icon: "speaker.wave.3.fill") {
            VStack(spacing: 0) {
                // Sound Effects
                SettingsToggleRow(
                    icon: "speaker.wave.2.fill",
                    title: "Sound Effects",
                    description: "Play sound effects during gameplay",
                    iconColor: .green,
                    isOn: $soundEffectsEnabled
                )
                
                Divider()
                    .padding(.leading, 52)
                
                // Haptic Feedback
                SettingsToggleRow(
                    icon: "hand.tap.fill",
                    title: "Haptic Feedback",
                    description: "Feel vibrations during gameplay",
                    iconColor: .pink,
                    isOn: $hapticsEnabled
                )
                .onChange(of: hapticsEnabled) { _, newValue in
                    if newValue {
                        HapticManager.playImpact(.medium, force: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Advanced Section
    private var advancedSection: some View {
        SettingsCard(title: "Advanced", icon: "gearshape.2.fill") {
            VStack(spacing: 0) {
                // Profile
                SettingsNavigationRow(
                    icon: "person.crop.circle.fill",
                    title: "Profile",
                    iconColor: .blue
                ) {
                    showProfile = true
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Privacy
                SettingsNavigationRow(
                    icon: "hand.raised.fill",
                    title: "Privacy",
                    iconColor: .indigo
                ) {
                    // Navigate to privacy settings
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Data & Storage
                SettingsNavigationRow(
                    icon: "externaldrive.fill",
                    title: "Data & Storage",
                    iconColor: .cyan
                ) {
                    // Navigate to data settings
                }
            }
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        SettingsCard(title: "About & Support", icon: "info.circle.fill") {
            VStack(spacing: 0) {
                // About
                SettingsNavigationRow(
                    icon: "info.circle.fill",
                    title: "About Tic Tac Toe Pro",
                    iconColor: .blue
                ) {
                    showAbout = true
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Rate App
                SettingsNavigationRow(
                    icon: "star.fill",
                    title: "Rate on App Store",
                    iconColor: .yellow
                ) {
                    // Open App Store rating
                    rateApp()
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Share App
                SettingsNavigationRow(
                    icon: "square.and.arrow.up.fill",
                    title: "Share App",
                    iconColor: .green
                ) {
                    shareApp()
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Contact Support
                SettingsNavigationRow(
                    icon: "envelope.fill",
                    title: "Contact Support",
                    iconColor: .red
                ) {
                    contactSupport()
                }
            }
        }
    }
    
    // MARK: - Reset Section
    private var resetSection: some View {
        Button {
            showResetAlert = true
        } label: {
            HStack {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Reset All Settings")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Text("Restore default values")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.red.opacity(0.9), .orange.opacity(0.9)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Version Section
    private var versionSection: some View {
        VStack(spacing: 8) {
            Text("Tic Tac Toe Pro")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Made with ❤️ by Sunnatbek")
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
    
    // MARK: - Premium Background
    private var premiumBackground: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.11, green: 0.12, blue: 0.18), Color(red: 0.03, green: 0.04, blue: 0.06)]
                    : [Color(red: 0.98, green: 0.98, blue: 1.0), Color(red: 0.95, green: 0.96, blue: 0.99), Color(red: 0.90, green: 0.92, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            Rectangle()
                .fill(LinearGradient(colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.02 : 0.08),
                    Color.black.opacity(colorScheme == .dark ? 0.02 : 0.01)
                ], startPoint: .topLeading, endPoint: .bottomTrailing))
                .blendMode(.overlay)
                .opacity(0.6)
                .ignoresSafeArea()
            
            LinearGradient(
                colors: [Color.black.opacity(colorScheme == .dark ? 0.35 : 0.15), .clear, Color.black.opacity(colorScheme == .dark ? 0.35 : 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            NoiseTextureView()
                .opacity(colorScheme == .dark ? 0.05 : 0.03)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Helper Properties
    private var colorSchemeIcon: String {
        switch colorSchemePreference {
        case "light": return "sun.max.fill"
        case "dark": return "moon.fill"
        default: return "circle.lefthalf.filled"
        }
    }
    
    // Resolve the preferred color scheme based on stored preference
    private var resolvedColorScheme: ColorScheme? {
        switch colorSchemePreference {
        case "light": return .light
        case "dark": return .dark
        default: return nil // system
        }
    }
    
    // MARK: - Actions
    private func resetAllSettings() {
        hapticsEnabled = false
        soundEffectsEnabled = true
        showAnimations = true
        defaultBoardSize = 3
        colorSchemePreference = "system"
        
        HapticManager.playNotification(.success, force: true)
    }
    
    private func rateApp() {
        // Implement App Store rating
        #if os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
        #endif
    }
    
    private func shareApp() {
        // Implement share functionality
        #if os(iOS)
        let appURLString = "https://apps.apple.com/app/id123456789" // Replace with actual App Store URL
        let items: [Any] = ["Check out Tic Tac Toe Pro!", URL(string: appURLString) as Any]
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
    
    private func contactSupport() {
        // Open email client
        #if os(iOS)
        if let url = URL(string: "mailto:support@tictactoepro.com") {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

// MARK: - Settings Card
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(title)
                    .font(.headline.bold())
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Content
            content
                .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.12), Color.white.opacity(0.04)]
                            : [Color.black.opacity(0.08), Color.black.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Settings Row
struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    @ViewBuilder let trailing: Content
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor)
                )
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let description: String?
    let iconColor: Color
    @Binding var isOn: Bool
    
    init(icon: String, title: String, description: String? = nil, iconColor: Color, isOn: Binding<Bool>) {
        self.icon = icon
        self.title = title
        self.description = description
        self.iconColor = iconColor
        self._isOn = isOn
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.purple)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Settings Navigation Row
struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(iconColor)
                    )
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.11, green: 0.12, blue: 0.18)]
                        : [Color(red: 0.95, green: 0.96, blue: 0.99), Color(red: 0.90, green: 0.92, blue: 0.98)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // App Icon
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 40)
                        
                        // App Name
                        Text("Tic Tac Toe Pro")
                            .font(.title.bold())
                            .foregroundColor(.primary)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Description
                        Text("A modern take on the classic game with stunning visuals, multiplayer support, and AI opponents.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        // Features
                        VStack(alignment: .leading, spacing: 16) {
                            FeatureRow(icon: "brain.head.profile", title: "Smart AI", description: "Three difficulty levels")
                            FeatureRow(icon: "person.2.fill", title: "Multiplayer", description: "Play with friends online")
                            FeatureRow(icon: "square.grid.3x3", title: "Custom Boards", description: "3×3 to 12×12 grids")
                            FeatureRow(icon: "paintbrush.fill", title: "Beautiful Design", description: "Premium UI/UX")
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal)
                        
                        // Credits
                        VStack(spacing: 8) {
                            Text("Created by")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Sunnatbek")
                                .font(.headline.bold())
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 16)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#if os(iOS)
import StoreKit
import UIKit
#endif

#Preview {
    SettingsView().environmentObject(MultiplayerViewModel.preview)
}
