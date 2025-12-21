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
    @AppStorage("colorSchemePreference") private var colorSchemePreference = "system"
    @AppStorage("profileName") private var profileName: String = ""  // Added
    
    @State private var showResetAlert = false
    @State private var showAbout = false
    @State private var showProfile = false
    
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
                        
                        // Profile Section (First)
                        profileSection
                        
                        // Gameplay Settings
                        // gameplaySection
                        
                        // Appearance Settings
                        appearanceSection
                        
                        // Audio & Haptics
                        // audioHapticsSection
                        
                        // About & Support
                        aboutSection
                        
                        // Reset Settings
                        resetSection
                        
                    }
                    .padding(.horizontal, isCompactHeightPhone ? 12 : 16)
                    .padding(.vertical, isCompactHeightPhone ? 16 : 24)
                    .frame(maxWidth: contentMaxWidth)
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
            .onAppear {
                // Sync with multiplayer VM if local name is empty
                if profileName.isEmpty,
                   let vmName = multiplayerVM.currentPlayer?.username,
                   !vmName.isEmpty {
                    profileName = vmName
                }
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
    
    // MARK: - Profile Section
    private var profileSection: some View {
        SettingsCard(title: "Profile", icon: "person.crop.circle.fill") {
            VStack(spacing: 0) {
                SettingsNavigationRow(
                    icon: "person.crop.circle.fill",
                    title: "Profile",
                    title2: displayName,
                    iconColor: .blue
                ) {
                    showProfile = true
                }
            }
        }
    }
    
    // MARK: - Gameplay Section
    private var gameplaySection: some View {
        SettingsCard(title: "Gameplay", icon: "gamecontroller.fill") {
            VStack(spacing: 0) {
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
                    if hSizeClass == .compact {
                        Picker("Theme", selection: $colorSchemePreference) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
                    } else {
                        Picker("Theme", selection: $colorSchemePreference) {
                            Label("System", systemImage: "circle.lefthalf.filled").tag("system")
                            Label("Light", systemImage: "sun.max.fill").tag("light")
                            Label("Dark", systemImage: "moon.fill").tag("dark")
                        }
                        .pickerStyle(.menu)
                    }
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
                        HapticManager.playImpact(HapticFeedbackStyle.medium, force: true)
                    }
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
    
    // Display name with fallback
    private var displayName: String {
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        } else if let vmName = multiplayerVM.currentPlayer?.username,
                  !vmName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return vmName
        } else {
            return "Guest"
        }
    }
    
    // MARK: - Actions
    private func resetAllSettings() {
        hapticsEnabled = false
        soundEffectsEnabled = true
        showAnimations = true
        colorSchemePreference = "system"
        profileName = ""  // Reset name
        
        HapticManager.playNotification(HapticNotificationType.success, force: true)
    }
    
    private func rateApp() {
        #if os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
        #endif
    }
    
    private func shareApp() {
        #if os(iOS)
        let appURLString = "https://apps.apple.com/uz/app/tictactoepro/id6755810923" // Replace with actual App Store URL
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
        #if os(iOS)
        let email = "sunnatbekabdunabiyev@icloud.com"
        let subject = "Tic Tac Toe Pro Support"
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)") {
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

// MARK: - Settings Navigation Row (Updated with subtitle)
struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let title2: String?
    let subtitle: String?
    let iconColor: Color
    let action: () -> Void
    
    init(icon: String, title: String, title2: String? = nil, subtitle: String? = nil, iconColor: Color, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.title2 = title2
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.action = action
    }
    
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
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(title2 ?? "")
                    .font(.body)
                    .foregroundColor(.secondary)
                
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

