//
//  LanguageSelectorView.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 12/01/26.
//
//  Changes from iOS version:
//  - SettingsCard     → WatchCard        (defined in SettingsView.swift)
//  - LanguageRow      → compact 38 pt rows (32×32 icon → 24×24)
//  - RestartView      → simplified Watch-sized version
//  - exit(0) restart  → manual restart prompt (watchOS has no exit())
//  - hSizeClass / vSizeClass / UIScreen → removed
//  - premiumBackground → removed (transparent, parent provides bg)
//  - .largeTitle / system(size:64) → .headline / .title3
//  - Duplicate .alert modifiers → single alert
//

import SwiftUI

// MARK: - Language Selector View
struct LanguageSelectorView: View {
    @AppStorage("appLanguage") private var appLanguage: String =
        Locale.current.language.languageCode?.identifier ?? "en"

    @Environment(\.dismiss) private var dismiss

    @State private var showConfirmAlert = false
    @State private var tempSelection   = ""
    @State private var showRestartInfo = false

    let isFirstLaunch: Bool
    let onLanguageSelected: ((String) -> Void)?

    init(isFirstLaunch: Bool = false, onLanguageSelected: ((String) -> Void)? = nil) {
        self.isFirstLaunch      = isFirstLaunch
        self.onLanguageSelected = onLanguageSelected
    }

    // MARK: Language list
    static let availableLanguages: [(code: String, name: String, nativeName: String)] = [
        ("en", "English",   "English"),
        ("ar", "Arabic",    "العربية"),
        ("fr", "French",    "Français"),
        ("de", "German",    "Deutsch"),
        ("ru", "Russian",   "Русский"),
        ("ja", "Japanese",  "日本語"),
        ("ko", "Korean",    "한국어"),
        ("es", "Spanish",   "Español"),
        ("sv", "Swedish",   "Svenska"),
        ("tr", "Turkish",   "Türkçe"),
        ("uk", "Ukrainian", "Українська"),
        ("uz", "Uzbek",     "O'zbek"),
    ]

    static func getLanguageName(for code: String) -> String {
        availableLanguages.first { $0.code == code }?.name ?? "English"
    }

    static func getNativeLanguageName(for code: String) -> String {
        availableLanguages.first { $0.code == code }?.nativeName ?? "English"
    }

    // MARK: Body
    var body: some View {
        if showRestartInfo {
            WatchRestartView()
                .transition(.opacity)
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 10) {

                // ── Header ───────────────────────────────────────────
                WatchHeader(
                    icon: "globe",
                    title: isFirstLaunch ? "Welcome!" : "Language"
                )

                // ── Language list ────────────────────────────────────
                WatchCard(title: isFirstLaunch ? "" : "Languages") {
                    VStack(spacing: 0) {
                        ForEach(Array(Self.availableLanguages.enumerated()), id: \.element.code) { idx, lang in
                            WatchLanguageRow(
                                flag:       flagEmoji(lang.code),
                                name:       lang.name,
                                nativeName: lang.nativeName,
                                isSelected: appLanguage == lang.code
                            ) {
                                selectLanguage(lang.code)
                            }
                            if idx < Self.availableLanguages.count - 1 {
                                WatchDivider()
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }

                // ── Restart info (non-first launch) ──────────────────
                if !isFirstLaunch {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                        Text("Language change requires app restart.")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 6)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .focusable()
        .alert("Change Language?", isPresented: $showConfirmAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Apply") { applyLanguageChange(tempSelection) }
        } message: {
            Text("App needs to restart to apply this change.")
        }
    }

    // MARK: - Actions
    private func selectLanguage(_ code: String) {
        if isFirstLaunch {
            if code != appLanguage { updateLanguage(code) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                dismiss()
                onLanguageSelected?(code)
            }
        } else {
            guard code != appLanguage else { return }
            tempSelection    = code
            showConfirmAlert = true
        }
    }

    private func applyLanguageChange(_ code: String) {
        updateLanguage(code)
        withAnimation(.easeInOut(duration: 0.3)) {
            showRestartInfo = true
        }
    }

    private func updateLanguage(_ code: String) {
        appLanguage = code
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }

    // MARK: - Flag helper
    private func flagEmoji(_ code: String) -> String {
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
        default:   return "🌐"
        }
    }
}

// MARK: - Watch Language Row
private struct WatchLanguageRow: View {
    let flag:       String
    let name:       String
    let nativeName: String
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Flag chip
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            isSelected
                                ? LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color(white: 0.25)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 24, height: 24)
                    Text(flag)
                        .font(.system(size: 13))
                }

                // Names
                VStack(alignment: .leading, spacing: 1) {
                    Text(name)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(.primary)
                    Text(nativeName)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Checkmark / chevron
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .blue],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Watch Restart View
struct WatchRestartView: View {
    @State private var rotating = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(colors: [.green, .blue, .purple],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .rotationEffect(.degrees(rotating ? 360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: rotating)

            ProgressView()
                .tint(.purple)

            Text("Language updated!")
                .font(.footnote.bold())
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .purple],
                                   startPoint: .leading, endPoint: .trailing)
                )

            Text("Please restart the app to apply changes.")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding()
        .onAppear { rotating = true }
    }
}

// MARK: - Previews
#Preview("Normal") {
    NavigationStack { LanguageSelectorView() }
}

#Preview("First Launch") {
    NavigationStack {
        LanguageSelectorView(isFirstLaunch: true) { print("Selected: \($0)") }
    }
}

#Preview("Restart") {
    WatchRestartView()
}
