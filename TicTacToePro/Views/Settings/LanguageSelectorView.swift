//
//  LanguageSelectorView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 12/01/26.
//  Refactored with premium design and full restart integration on 12/01/26
//

import SwiftUI

struct LanguageSelectorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("appLanguage") private var appLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
    
    @State private var showConfirmAlert = false
    @State private var tempSelection: String = ""
    @State private var showRestartScreen = false
    
    // For first launch dialog
    let isFirstLaunch: Bool
    let onLanguageSelected: ((String) -> Void)?
    
    // Initializers
    init(isFirstLaunch: Bool = false, onLanguageSelected: ((String) -> Void)? = nil) {
        self.isFirstLaunch = isFirstLaunch
        self.onLanguageSelected = onLanguageSelected
    }
    
    // Static array for access from other views
    static let availableLanguages: [(code: String, name: String, nativeName: String)] = [
        ("en", "English", "English"),
        ("ar", "Arabic", "العربية"),
        ("fr", "French", "Français"),
        ("de", "German", "Deutsch"),
        ("ru", "Russian", "Русский"),
        ("ja", "Japanese", "日本語"),
        ("ko", "Korean", "한국어"),
        ("es", "Spanish", "Español"),
        ("sv", "Swedish", "Svenska"),
        ("tr", "Turkish", "Türkçe"),
        ("uk", "Ukrainian", "Українська"),
        ("uz", "Uzbek", "O'zbek")
    ]
    
    private var languages: [(code: String, name: String, nativeName: String)] {
        Self.availableLanguages
    }
    
    // Helper to get language name by code
    static func getLanguageName(for code: String) -> String {
        availableLanguages.first(where: { $0.code == code })?.name ?? "English"
    }
    
    // Helper to get native language name by code
    static func getNativeLanguageName(for code: String) -> String {
        availableLanguages.first(where: { $0.code == code })?.nativeName ?? "English"
    }
    
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
        ZStack {
            if showRestartScreen {
                RestartView()
                    .transition(.opacity)
                    .zIndex(200)
            } else {
                mainContent
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showRestartScreen)
    }
    
    private var mainContent: some View {
        ZStack {
            premiumBackground
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: isCompactHeightPhone ? 16 : 24) {
                    // Header
                    headerSection
                    
                    // Languages List
                    languagesSection
                    
                    // Info Card (only show if not first launch)
                    if !isFirstLaunch {
                        infoCard
                    }
                }
                .padding(.horizontal, isCompactHeightPhone ? 12 : 16)
                .padding(.vertical, isCompactHeightPhone ? 16 : 24)
                .frame(maxWidth: contentMaxWidth)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Restart Required", isPresented: $showConfirmAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restart Now", role: .destructive) {
                applyLanguageChange(tempSelection)
            }
        } message: {
            Text("To apply the language change, the app needs to restart. Your progress will be saved.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "globe")
                .font(.system(size: isFirstLaunch ? 64 : 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(isFirstLaunch ? "Welcome!" : "Language")
                .font(.largeTitle.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text(isFirstLaunch ? "Please select your language" : "Choose your preferred language")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isFirstLaunch ? 16 : 8)
    }
    
    // MARK: - Languages Section
    private var languagesSection: some View {
        SettingsCard(title: isFirstLaunch ? "" : "Available Languages", icon: "list.bullet") {
            VStack(spacing: 0) {
                ForEach(Array(languages.enumerated()), id: \.element.code) { index, language in
                    LanguageRow(
                        language: language,
                        isSelected: appLanguage == language.code,
                        isFirstLaunch: isFirstLaunch
                    ) {
                        selectLanguage(language.code)
                    }
                    
                    if index < languages.count - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
        }
    }
    
    // MARK: - Info Card
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Note")
                    .font(.headline.bold())
                    .foregroundColor(.primary)
            }
            
            Text("Changing the language will require the app to restart. Your game progress and settings will be preserved.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.blue.opacity(0.3), Color.purple.opacity(0.2)]
                            : [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .blue.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 6, x: 0, y: 3)
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
    
    // MARK: - Actions
    private func selectLanguage(_ code: String) {
        HapticManager.playImpact(HapticFeedbackStyle.medium)
        
        if isFirstLaunch {
            // First launch: set language and notify parent
            if code != appLanguage {
                updateAppLanguage(code)
            }
            
            // Small delay for haptic feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                dismiss()
                onLanguageSelected?(code)
            }
        } else {
            // Regular change: show confirmation if different
            guard code != appLanguage else {
                print("✅ Same language selected - no change needed")
                return
            }
            
            tempSelection = code
            showConfirmAlert = true
        }
    }
    
    private func applyLanguageChange(_ code: String) {
        print("🔄 Applying language change to: \(code)")
        
        // Update language
        updateAppLanguage(code)
        
        // Show restart screen
        withAnimation(.easeInOut(duration: 0.3)) {
            showRestartScreen = true
        }
        
        // Restart after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            restartApp()
        }
    }
    
    private func updateAppLanguage(_ code: String) {
        // Save to both AppStorage and UserDefaults
        appLanguage = code
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        print("🌍 Language updated to: \(code)")
        print("📱 AppleLanguages: \(UserDefaults.standard.stringArray(forKey: "AppleLanguages") ?? [])")
    }
    
    private func restartApp() {
        print("🔄 Restarting app...")
        #if os(iOS)
        // Note: exit(0) may cause App Store rejection in production
        // Consider showing a message asking user to restart manually
        exit(0)
        #endif
    }
}

// MARK: - Language Row
struct LanguageRow: View {
    let language: (code: String, name: String, nativeName: String)
    let isSelected: Bool
    let isFirstLaunch: Bool
    let action: () -> Void
    
    init(language: (code: String, name: String, nativeName: String), isSelected: Bool, isFirstLaunch: Bool = false, action: @escaping () -> Void) {
        self.language = language
        self.isSelected = isSelected
        self.isFirstLaunch = isFirstLaunch
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Flag/Globe icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: isSelected
                                    ? [.green, .blue]
                                    : [.gray.opacity(0.3), .gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Text(languageFlag(for: language.code))
                        .font(.title3)
                }
                
                // Language names
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.name)
                        .font(.body.weight(isSelected ? .semibold : .regular))
                        .foregroundColor(.primary)
                    
                    Text(language.nativeName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func languageFlag(for code: String) -> String {
        switch code {
        case "en": return "🇬🇧"
        case "ar": return "🇸🇦"
        case "fr": return "🇫🇷"
        case "de": return "🇩🇪"
        case "ru": return "🇷🇺"
        case "ja": return "🇯🇵"
        case "ko": return "🇰🇷"
        case "es": return "🇪🇸"
        case "sv": return "🇸🇪"
        case "tr": return "🇹🇷"
        case "uk": return "🇺🇦"
        case "uz": return "🇺🇿"
        default: return "🌐"
        }
    }
}

// MARK: - Restart View
struct RestartView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Premium Background
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.11, green: 0.12, blue: 0.18), Color(red: 0.03, green: 0.04, blue: 0.06)]
                    : [Color(red: 0.98, green: 0.98, blue: 1.0), Color(red: 0.95, green: 0.96, blue: 0.99), Color(red: 0.90, green: 0.92, blue: 0.98)],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGradient)
            
            // Noise Texture
            NoiseTextureView()
                .opacity(colorScheme == .dark ? 0.05 : 0.03)
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 32) {
                // Animated Globe Icon
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.green, .blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        )
                        .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "globe")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(animateGradient ? 360 : 0))
                        .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: animateGradient)
                }
                
                // Progress and Text
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.purple)
                    
                    VStack(spacing: 8) {
                        Text("Applying Language")
                            .font(.title2.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("App will restart in a moment...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            animateGradient = true
        }
    }
}

#Preview("Language Selector - Normal") {
    NavigationStack {
        LanguageSelectorView()
    }
}

#Preview("Language Selector - First Launch") {
    NavigationStack {
        LanguageSelectorView(isFirstLaunch: true) { language in
            print("Selected: \(language)")
        }
    }
}

#Preview("Restart View") {
    RestartView()
}
