//
//  SettingsView.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek
//
//  watchOS principles applied:
//  - All iOS-only APIs removed (UIApplication, StoreKit, UIActivityViewController)
//  - NavigationStack push-navigation replaces sheets where possible
//  - Compact row height: 36–40 pt (vs 56 pt on iOS)
//  - Icon frame: 24×24 pt (vs 32×32 pt on iOS)
//  - Font scale: .footnote / .caption2 (vs .body / .headline on iOS)
//  - No horizontal size class branching
//

import SwiftUI

struct SettingsView: View {

    // MARK: - Stored preferences
    @AppStorage("soundEffectsEnabled")       private var soundEnabled      = true
    @AppStorage("showAnimations")            private var showAnimations    = true
    @AppStorage("colorSchemePreference")     private var schemePref        = "system"
    @AppStorage("profileName")              private var profileName        = ""
    @AppStorage("isSettingsBackgroundEnabled") private var bgEnabled       = true

    @State private var showResetAlert = false

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                // ── Header ──────────────────────────────────────────────
                WatchHeader(icon: "gearshape.fill", title: "Settings")

                // ── General ─────────────────────────────────────────────
                WatchCard(title: "General") {
                    // Profile name (inline text field on Watch via NavigationLink)
                    NavigationLink {
                        ProfileEditView(profileName: $profileName)
                    } label: {
                        WatchRow(icon: "person.crop.circle.fill", color: .blue,
                                 title: "Profile", value: displayName)
                    }
                    .buttonStyle(.plain)

                    WatchDivider()

                    // Sound toggle
                    WatchToggleRow(icon: "speaker.wave.2.fill", color: .indigo,
                                   title: "Sound", isOn: $soundEnabled)

                    WatchDivider()

                    // Animations toggle
                    WatchToggleRow(icon: "sparkles", color: .purple,
                                   title: "Animations", isOn: $showAnimations)
                }

                // ── Appearance ──────────────────────────────────────────
                WatchCard(title: "Appearance") {
                    // Theme picker
                    NavigationLink {
                        ThemePickerView(schemePref: $schemePref)
                    } label: {
                        WatchRow(icon: colorSchemeIcon, color: .orange,
                                 title: "Theme", value: schemeLabel)
                    }
                    .buttonStyle(.plain)

                    WatchDivider()

                    // Background
                    NavigationLink {
                        BackgroundView()
                    } label: {
                        WatchRow(icon: "bubbles.and.sparkles.fill", color: .purple,
                                 title: "Background")
                    }
                    .buttonStyle(.plain)
                }

                // ── About ───────────────────────────────────────────────
                WatchCard(title: "About") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        WatchRow(icon: "info.circle.fill", color: .blue,
                                 title: "About App")
                    }
                    .buttonStyle(.plain)
                }

                // ── Reset ───────────────────────────────────────────────
                Button {
                    showResetAlert = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.footnote)
                        Text("Reset Settings")
                            .font(.footnote).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(colors: [.red.opacity(0.85), .orange.opacity(0.85)],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .focusable()
        .preferredColorScheme(resolvedColorScheme)
        .alert("Reset Settings?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { resetSettings() }
        } message: {
            Text("All settings will return to defaults.")
        }
    }

    // MARK: - Helpers
    private var displayName: String {
        let t = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "Anonymous" : t
    }

    private var colorSchemeIcon: String {
        switch schemePref {
        case "light": return "sun.max.fill"
        case "dark":  return "moon.fill"
        default:      return "circle.lefthalf.filled"
        }
    }

    private var schemeLabel: String {
        switch schemePref {
        case "light": return "Light"
        case "dark":  return "Dark"
        default:      return "System"
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        switch schemePref {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    private func resetSettings() {
        soundEnabled   = true
        showAnimations = true
        schemePref     = "system"
        bgEnabled      = true
    }
}

// MARK: - Profile Edit View (inline watchOS text input)
private struct ProfileEditView: View {
    @Binding var profileName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 10) {
            WatchHeader(icon: "person.crop.circle.fill", title: "Profile")

            TextField("Your name", text: $profileName)
                .font(.footnote)
                .frame(height: 36)
                .padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial))

            Button("Save") { dismiss() }
                .font(.footnote.bold())
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(Color.blue.opacity(0.8))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Theme Picker View
private struct ThemePickerView: View {
    @Binding var schemePref: String

    private let options: [(label: String, icon: String, tag: String)] = [
        ("System", "circle.lefthalf.filled", "system"),
        ("Light",  "sun.max.fill",           "light"),
        ("Dark",   "moon.fill",              "dark"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                WatchHeader(icon: "paintbrush.fill", title: "Theme")
                ForEach(options, id: \.tag) { option in
                    Button {
                        schemePref = option.tag
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: option.icon)
                                .font(.footnote)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.orange.opacity(0.2)))
                                .foregroundStyle(.orange)
                            Text(option.label)
                                .font(.footnote)
                            Spacer()
                            if schemePref == option.tag {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(schemePref == option.tag ? AnyShapeStyle(.thinMaterial) : AnyShapeStyle(.ultraThinMaterial))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - Reusable Watch Components

struct WatchHeader: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .purple, .blue],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text(title)
                .font(.headline).fontWeight(.heavy)
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .purple],
                                   startPoint: .leading, endPoint: .trailing)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }
}

struct WatchCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption2).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 4)
            content()
                .padding(.bottom, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

/// Simple disclosure row with optional trailing value label
struct WatchRow: View {
    let icon: String
    let color: Color
    let title: String
    var value: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(RoundedRectangle(cornerRadius: 6).fill(color))

            Text(title)
                .font(.footnote)
                .foregroundStyle(.primary)

            Spacer()

            if let value {
                Text(value)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .contentShape(Rectangle())
    }
}

/// Toggle row
struct WatchToggleRow: View {
    let icon: String
    let color: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(RoundedRectangle(cornerRadius: 6).fill(color))

            Text(title)
                .font(.footnote)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.purple)
                .scaleEffect(0.8)   // watchOS toggle is already compact; scale down slightly
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
    }
}

struct WatchDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 42)
            .opacity(0.25)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(AppState())
}
