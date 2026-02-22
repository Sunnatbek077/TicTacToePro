//
//  BackgroundView.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//  Original by Sunnatbek on 12/01/26.
//
//  Changes from iOS version:
//  - SettingsCard      → WatchCard       (defined in SettingsView.swift)
//  - SettingsToggleRow → WatchToggleRow  (defined in SettingsView.swift)
//  - ColorSelectionView resized: 70×70 → 36×36 pt (4 per row on Watch)
//  - LazyVGrid 4-col kept; item size reduced
//  - iOS-only Slider → watchOS Digital Crown friendly stepper UI
//  - hSizeClass / vSizeClass / UIScreen removed
//  - NavigationStack removed (parent already provides one)
//  - .largeTitle / .system(size:48) → .headline / .title3
//

import SwiftUI

// MARK: - Animation Mood
enum AnimationMood: String, CaseIterable {
    case none             = "None"
    case randomFlicker    = "Random Flicker"
    case joyfulPulse      = "Joyful Pulse"
    case sadFade          = "Sad Fade"
    case angryFlash       = "Angry Flash"
    case calmWave         = "Calm Wave"
    case romanticHeartbeat = "Romantic Heartbeat"
    case energeticRainbow = "Energetic Rainbow"
    case mysticGlow       = "Mystic Glow"
}

// MARK: - Selectable Color
struct SelectableColor: Identifiable, Hashable {
    let id   = UUID()
    let color: Color
    var isSelected: Bool = false
}

// MARK: - Color Chip (watch-sized)
struct ColorSelectionView: View {
    @Binding var selectableColor: SelectableColor

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(selectableColor.color)
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(
                            selectableColor.isSelected ? Color.white.opacity(0.85) : Color.clear,
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: selectableColor.isSelected
                        ? selectableColor.color.opacity(0.55)
                        : Color.black.opacity(0.2),
                    radius: selectableColor.isSelected ? 6 : 2
                )

            if selectableColor.isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1)
            }
        }
        .scaleEffect(selectableColor.isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectableColor.isSelected)
        .onTapGesture { selectableColor.isSelected.toggle() }
    }
}

// MARK: - Main Background View
struct BackgroundView: View {

    // MARK: Stored preferences
    @AppStorage("isStartViewBackgroundEnabled")    private var startBgEnabled:  Bool   = true
    @AppStorage("isMultiplayerBackgroundEnabled")  private var multiplayerBgEnabled: Bool = true
    @AppStorage("isSettingsBackgroundEnabled")     private var settingsBgEnabled: Bool = true
    @AppStorage("enableBackgroundBlur")            private var blurEnabled:     Bool   = false
    @AppStorage("enableBackgroundAnimation")       private var animEnabled:     Bool   = true
    @AppStorage("animationSpeed")                  private var animSpeed:       Double = 0.5
    @AppStorage("selectedAnimationMood")           private var moodRaw:         String = AnimationMood.none.rawValue

    private var selectedMood: AnimationMood {
        get { AnimationMood(rawValue: moodRaw) ?? .none }
        nonmutating set { moodRaw = newValue.rawValue }
    }

    @State private var colors: [SelectableColor] = [
        SelectableColor(color: .pink),
        SelectableColor(color: .blue),
        SelectableColor(color: .purple),
        SelectableColor(color: .cyan),
        SelectableColor(color: .indigo),
        SelectableColor(color: .red),
        SelectableColor(color: .green),
        SelectableColor(color: .orange)
    ]

    @Environment(\.colorScheme) private var colorScheme

    // MARK: Body
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                // ── Header ────────────────────────────────────────────
                WatchHeader(icon: "paintpalette.fill", title: "Background")

                // ── Colors ────────────────────────────────────────────
                WatchCard(title: "Colors") {
                    VStack(spacing: 8) {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4),
                            spacing: 6
                        ) {
                            ForEach($colors) { $c in
                                ColorSelectionView(selectableColor: $c)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 6)

                        WatchDivider()

                        WatchToggleRow(
                            icon: "camera.filters",
                            color: .cyan,
                            title: "Blur",
                            isOn: $blurEnabled
                        )
                        .padding(.bottom, 4)
                    }
                }

                // ── Animation ─────────────────────────────────────────
                WatchCard(title: "Animation") {
                    VStack(spacing: 0) {
                        WatchToggleRow(
                            icon: "wand.and.stars",
                            color: .purple,
                            title: "Animate",
                            isOn: $animEnabled
                        )

                        if animEnabled {
                            WatchDivider()

                            // Speed stepper (Digital Crown friendly)
                            HStack(spacing: 8) {
                                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange))

                                Text("Speed")
                                    .font(.footnote)

                                Spacer()

                                // − / + buttons as stepper on Watch
                                HStack(spacing: 4) {
                                    Button {
                                        animSpeed = max(0, animSpeed - 0.25)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(Int(animSpeed * 100))%")
                                        .font(.caption2).monospacedDigit()
                                        .frame(width: 34)

                                    Button {
                                        animSpeed = min(1, animSpeed + 0.25)
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(.orange)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 10)
                            .frame(height: 38)

                            WatchDivider()

                            // Mood picker
                            NavigationLink {
                                MoodPickerView(selectedMood: Binding(
                                    get: { selectedMood },
                                    set: { moodRaw = $0.rawValue }
                                ))
                            } label: {
                                WatchRow(
                                    icon: "theatermasks.fill",
                                    color: .indigo,
                                    title: "Mood",
                                    value: selectedMood == .none ? "None" : selectedMood.shortName
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.bottom, 4)
                        }
                    }
                }

                // ── Enable per view ───────────────────────────────────
                WatchCard(title: "Enable For") {
                    VStack(spacing: 0) {
                        WatchToggleRow(icon: "gamecontroller.fill",  color: .green, title: "Start",       isOn: $startBgEnabled)
                        WatchDivider()
                        WatchToggleRow(icon: "gear",                  color: .gray,  title: "Settings",    isOn: $settingsBgEnabled)
                            .padding(.bottom, 4)
                    }
                }

            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .focusable()
        .onAppear { loadColors() }
        .onChange(of: colors) { _, _ in saveColors() }
    }

    // MARK: - Persistence
    private let colorKeys = ["pink", "blue", "purple", "cyan", "indigo", "red", "green", "orange"]

    private func saveColors() {
        for (i, key) in colorKeys.enumerated() where i < colors.count {
            UserDefaults.standard.set(colors[i].isSelected, forKey: "selectedColor_\(key)")
        }
    }

    private func loadColors() {
        for (i, key) in colorKeys.enumerated() where i < colors.count {
            colors[i].isSelected = UserDefaults.standard.bool(forKey: "selectedColor_\(key)")
        }
    }
}

// MARK: - Mood Picker (push view)
private struct MoodPickerView: View {
    @Binding var selectedMood: AnimationMood

    private let moods: [(AnimationMood, String, Color)] = [
        (.none,             "None",              .secondary),
        (.randomFlicker,    "Flicker",           .yellow),
        (.joyfulPulse,      "Joyful",            .pink),
        (.sadFade,          "Sad Fade",          .gray),
        (.angryFlash,       "Angry",             .red),
        (.calmWave,         "Calm",              .cyan),
        (.romanticHeartbeat,"Romantic",          Color(red: 1, green: 0.4, blue: 0.6)),
        (.energeticRainbow, "Rainbow",           .purple),
        (.mysticGlow,       "Mystic",            .indigo),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                WatchHeader(icon: "theatermasks.fill", title: "Mood")
                ForEach(moods, id: \.0.rawValue) { mood, label, color in
                    Button {
                        selectedMood = mood
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(color.opacity(0.8))
                                .frame(width: 12, height: 12)
                            Text(label)
                                .font(.footnote)
                            Spacer()
                            if selectedMood == mood {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(selectedMood == mood
                                      ? AnyShapeStyle(.thinMaterial)
                                      : AnyShapeStyle(.ultraThinMaterial))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
        }
        .focusable()
    }
}

// MARK: - AnimationMood short display name
private extension AnimationMood {
    var shortName: String {
        switch self {
        case .none:              return "None"
        case .randomFlicker:     return "Flicker"
        case .joyfulPulse:       return "Joyful"
        case .sadFade:           return "Sad"
        case .angryFlash:        return "Angry"
        case .calmWave:          return "Calm"
        case .romanticHeartbeat: return "Romantic"
        case .energeticRainbow:  return "Rainbow"
        case .mysticGlow:        return "Mystic"
        }
    }
}

#Preview {
    NavigationStack {
        BackgroundView()
    }
}
