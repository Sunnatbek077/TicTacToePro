//
//  BackgroundView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 12/01/26.
//  Redesigned with premium UI on 12/01/26
//

import SwiftUI

// MARK: - Animation Mood Enum
enum AnimationMood: String, CaseIterable {
    case none = "None"
    case randomFlicker = "Random Flicker"
    case joyfulPulse = "Joyful Pulse"
    case sadFade = "Sad Fade"
    case angryFlash = "Angry Flash"
    case calmWave = "Calm Wave"
    case romanticHeartbeat = "Romantic Heartbeat"
    case energeticRainbow = "Energetic Rainbow"
    case mysticGlow = "Mystic Glow"
}

struct SelectableColor: Identifiable, Hashable {
    let id = UUID()
    let color: Color
    var isSelected: Bool = false
}

// MARK: - Color Selection View
struct ColorSelectionView: View {
    @Binding var selectableColor: SelectableColor
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(selectableColor.color)
                .frame(width: 70, height: 70)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            selectableColor.isSelected
                            ? Color.white.opacity(0.8)
                            : Color.clear,
                            lineWidth: 3
                        )
                )
                .shadow(
                    color: selectableColor.isSelected
                    ? selectableColor.color.opacity(0.6)
                    : Color.black.opacity(0.2),
                    radius: selectableColor.isSelected ? 12 : 4,
                    x: 0,
                    y: selectableColor.isSelected ? 6 : 2
                )
            
            if selectableColor.isSelected {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .font(.system(size: 28))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
        }
        .scaleEffect(selectableColor.isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectableColor.isSelected)
        .onTapGesture {
            selectableColor.isSelected.toggle()
        }
    }
}

// MARK: - Main Background View
struct BackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass) private var vSizeClass
    
    // Saqlanadigan holatlar
    @AppStorage("isStartViewEnabled") private var isStartViewEnabled: Bool = true
    @AppStorage("isMultiplayerEnabled") private var isMultiplayerViewEnabled: Bool = true
    @AppStorage("isSettingsEnabled") private var isSettingsViewEnabled: Bool = true
    
    @AppStorage("enableBackgroundBlur") private var isEnabledBlur: Bool = false
    @AppStorage("enableBackgroundAnimation") private var isEnabledAnimation: Bool = true
    @AppStorage("animationSpeed") private var animationSpeed: Double = 0.5
    
    // Faqat bitta mood saqlaymiz
    @AppStorage("selectedAnimationMood") private var selectedMoodRawValue: String = AnimationMood.none.rawValue
    
    // Computed property - oson qilib mood bilan ishlash uchun
    private var selectedMood: AnimationMood {
        get {
            AnimationMood(rawValue: selectedMoodRawValue) ?? .none
        }
        nonmutating set {
            selectedMoodRawValue = newValue.rawValue
        }
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
                    .ignoresSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: isCompactHeightPhone ? 16 : 24) {
                        headerSection
                        backgroundColorsSection
                        headTextColorsSection
                        animationSection
                        tabsSection
                    }
                    .padding(.horizontal, isCompactHeightPhone ? 12 : 16)
                    .padding(.vertical, isCompactHeightPhone ? 16 : 24)
                    .frame(maxWidth: contentMaxWidth)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Background Settings")
                .font(.largeTitle.bold())
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Customize your app appearance")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
    
    // MARK: - Background Colors Section
    private var backgroundColorsSection: some View {
        SettingsCard(title: "Background Colors", icon: "paintbrush.fill") {
            VStack(spacing: 16) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                    spacing: 12
                ) {
                    ForEach($colors) { $selectableColor in
                        ColorSelectionView(selectableColor: $selectableColor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Divider()
                    .padding(.horizontal, 16)
                
                SettingsToggleRow(
                    icon: "camera.filters",
                    title: "Enable Blur",
                    description: "Add blur effect to background",
                    iconColor: .cyan,
                    isOn: $isEnabledBlur
                )
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Head Text Colors Section
    private var headTextColorsSection: some View {
        SettingsCard(title: "Head Text Colors", icon: "textformat") {
            VStack(spacing: 0) {
                Button {
                    // TODO: Add color functionality
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                        
                        Text("Add Text Color")
                            .font(.body.weight(.semibold))
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
    }
    
    // MARK: - Animation Section
    private var animationSection: some View {
        SettingsCard(title: "Animation", icon: "sparkles") {
            VStack(spacing: 16) {
                // Animation Toggle
                SettingsToggleRow(
                    icon: "wand.and.stars",
                    title: "Enable Animation",
                    description: "Animate background elements",
                    iconColor: .purple,
                    isOn: $isEnabledAnimation
                )
                
                Divider()
                    .padding(.leading, 52)
                
                // Animation Speed Slider
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange)
                            )
                        
                        VStack(alignment: .leading) {
                            Text("Animation Speed")
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text(String(format: "%.0f%%", animationSpeed * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    
                    // Custom Slider
                    VStack(spacing: 8) {
                        Slider(value: $animationSpeed, in: 0.0...1.0)
                            .tint(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        HStack {
                            Image(systemName: "tortoise.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            Spacer()
                            
                            Image(systemName: "hare.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                
                Divider()
                    .padding(.leading, 52)
                
                // Animation Moods Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Animation Moods")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    Text("Select one mood at a time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                }
                
                // Mood toggles
                moodToggleRow(
                    icon: "sparkles",
                    title: "Random Flicker",
                    description: "Chaotic and energetic flickering",
                    iconColor: .yellow,
                    mood: .randomFlicker
                )
                
                Divider()
                    .padding(.leading, 52)
                
                moodToggleRow(
                    icon: "heart.fill",
                    title: "Joyful Pulse",
                    description: "Happy party atmosphere",
                    iconColor: .pink,
                    mood: .joyfulPulse
                )
                
                Divider()
                    .padding(.leading, 52)
                
                moodToggleRow(
                    icon: "cloud.drizzle.fill",
                    title: "Sad Fade",
                    description: "Melancholic and reflective",
                    iconColor: .gray,
                    mood: .sadFade
                )
                
                Divider()
                    .padding(.leading, 52)
                
                moodToggleRow(
                    icon: "flame.fill",
                    title: "Angry Flash",
                    description: "Intense and aggressive",
                    iconColor: .red,
                    mood: .angryFlash
                )
                
                Divider()
                    .padding(.leading, 52)
                
                moodToggleRow(
                    icon: "water.waves",
                    title: "Calm Wave",
                    description: "Relaxing and peaceful",
                    iconColor: .cyan,
                    mood: .calmWave
                )
                
                Divider()
                    .padding(.leading, 52)
                
                moodToggleRow(
                    icon: "heart.circle.fill",
                    title: "Romantic Heartbeat",
                    description: "Warm and loving mood",
                    iconColor: Color(red: 1.0, green: 0.4, blue: 0.6),
                    mood: .romanticHeartbeat
                )
                
                Divider()
                    .padding(.leading, 52)
                
                moodToggleRow(
                    icon: "rainbow",
                    title: "Energetic Rainbow",
                    description: "High-energy disco vibe",
                    iconColor: .purple,
                    mood: .energeticRainbow
                )
                
                Divider()
                    .padding(.leading, 52)
                
                moodToggleRow(
                    icon: "moon.stars.fill",
                    title: "Mystic Glow",
                    description: "Dreamy and mysterious",
                    iconColor: .indigo,
                    mood: .mysticGlow
                )
            }
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Helper Function for Mood Toggle
    @ViewBuilder
    private func moodToggleRow(
        icon: String,
        title: String,
        description: String,
        iconColor: Color,
        mood: AnimationMood
    ) -> some View {
        let isSelected = selectedMood == mood
        
        SettingsToggleRow(
            icon: icon,
            title: title,
            description: description,
            iconColor: iconColor,
            isOn: Binding(
                get: { isSelected },
                set: { newValue in
                    if newValue {
                        // Yangi mood tanlandi
                        selectedMood = mood
                    } else {
                        // O'chirish - none ga qaytarish
                        selectedMood = .none
                    }
                }
            )
        )
    }
    
    // MARK: - Tabs Section
    private var tabsSection: some View {
        SettingsCard(title: "Visible Tabs", icon: "square.grid.2x2.fill") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "gamecontroller.fill",
                    title: "Start Menu",
                    description: "Show main game menu",
                    iconColor: .green,
                    isOn: $isStartViewEnabled
                )
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsToggleRow(
                    icon: "person.line.dotted.person.fill",
                    title: "Multiplayer",
                    description: "Show online multiplayer",
                    iconColor: .blue,
                    isOn: $isMultiplayerViewEnabled
                )
                
                Divider()
                    .padding(.leading, 52)
                
                SettingsToggleRow(
                    icon: "gear",
                    title: "Settings",
                    description: "Show settings tab",
                    iconColor: .gray,
                    isOn: $isSettingsViewEnabled
                )
            }
        }
    }
    
    // MARK: - Premium Background
    private var premiumBackground: some View {
        GeometryReader { geometry in
            ZStack {
                // asosiy gradient
                LinearGradient(
                    colors: colorScheme == .dark
                    ? [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.11, green: 0.12, blue: 0.18), Color(red: 0.03, green: 0.04, blue: 0.06)]
                    : [Color(red: 0.98, green: 0.98, blue: 1.0), Color(red: 0.95, green: 0.96, blue: 0.99), Color(red: 0.90, green: 0.92, blue: 0.98)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ForEach(colors.filter { $0.isSelected }) { selectedColor in
                    NeonLightView(
                        color: selectedColor.color,
                        geometry: geometry,
                        isAnimated: isEnabledAnimation,
                        animationSpeed: animationSpeed,
                        mood: selectedMood // Uzatish
                    )
                }
                
                if isEnabledBlur {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .blur(radius: max(0, 20 * animationSpeed))
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: isEnabledBlur)
                }
            }
        }
    }
}

#Preview {
    BackgroundView()
}
