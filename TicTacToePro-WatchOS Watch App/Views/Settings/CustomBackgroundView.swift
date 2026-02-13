//
//  CustomBackgroundView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 17/01/26.
//  Fixed: Tab o'zgarganda refresh bo'lmasligi uchun
//

import SwiftUI

/// Har bir view uchun custom background komponent
/// Bu komponent background settings asosida background ko'rsatadi yoki oddiy gradient ko'rsatadi
struct CustomBackgroundView: View {
    let viewType: ViewType
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Background settings
    @AppStorage("isStartViewBackgroundEnabled") private var isStartViewBackgroundEnabled: Bool = true
    @AppStorage("isMultiplayerBackgroundEnabled") private var isMultiplayerBackgroundEnabled: Bool = true
    @AppStorage("isSettingsBackgroundEnabled") private var isSettingsBackgroundEnabled: Bool = true
    
    @AppStorage("enableBackgroundBlur") private var isEnabledBlur: Bool = false
    @AppStorage("enableBackgroundAnimation") private var isEnabledAnimation: Bool = true
    @AppStorage("animationSpeed") private var animationSpeed: Double = 0.5
    @AppStorage("selectedAnimationMood") private var selectedMoodRawValue: String = AnimationMood.none.rawValue
    
    // Har bir rang uchun AppStorage - bu refresh muammosini hal qiladi
    @AppStorage("selectedColor_pink") private var isPinkSelected: Bool = false
    @AppStorage("selectedColor_blue") private var isBlueSelected: Bool = false
    @AppStorage("selectedColor_purple") private var isPurpleSelected: Bool = false
    @AppStorage("selectedColor_cyan") private var isCyanSelected: Bool = false
    @AppStorage("selectedColor_indigo") private var isIndigoSelected: Bool = false
    @AppStorage("selectedColor_red") private var isRedSelected: Bool = false
    @AppStorage("selectedColor_green") private var isGreenSelected: Bool = false
    @AppStorage("selectedColor_orange") private var isOrangeSelected: Bool = false
    
    private var selectedMood: AnimationMood {
        AnimationMood(rawValue: selectedMoodRawValue) ?? .none
    }
    
    // Tanlangan ranglarni dinamik hisoblash - har safar yuklash o'rniga
    private var selectedColors: [Color] {
        var colors: [Color] = []
        if isPinkSelected { colors.append(.pink) }
        if isBlueSelected { colors.append(.blue) }
        if isPurpleSelected { colors.append(.purple) }
        if isCyanSelected { colors.append(.cyan) }
        if isIndigoSelected { colors.append(.indigo) }
        if isRedSelected { colors.append(.red) }
        if isGreenSelected { colors.append(.green) }
        if isOrangeSelected { colors.append(.orange) }
        return colors.isEmpty ? [.blue, .purple] : colors
    }
    
    // Har bir view type uchun background yoqilganmi tekshirish
    private var isBackgroundEnabled: Bool {
        switch viewType {
        case .startView:
            return isStartViewBackgroundEnabled
        case .multiplayerView:
            return isMultiplayerBackgroundEnabled
        case .settingsView:
            return isSettingsBackgroundEnabled
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isBackgroundEnabled {
                    // Custom background
                    customBackground(geometry: geometry)
                } else {
                    // Default simple gradient
                    defaultBackground
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Custom Background
    @ViewBuilder
    private func customBackground(geometry: GeometryProxy) -> some View {
        ZStack {
            // Asosiy gradient
            LinearGradient(
                colors: colorScheme == .dark
                ? [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.11, green: 0.12, blue: 0.18), Color(red: 0.03, green: 0.04, blue: 0.06)]
                : [Color(red: 0.98, green: 0.98, blue: 1.0), Color(red: 0.95, green: 0.96, blue: 0.99), Color(red: 0.90, green: 0.92, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Tanlangan ranglar bilan animatsiyalar
            ForEach(selectedColors.indices, id: \.self) { index in
                NeonLightView(
                    color: selectedColors[index],
                    geometry: geometry,
                    isAnimated: isEnabledAnimation,
                    animationSpeed: animationSpeed,
                    mood: selectedMood
                )
            }
            
            // Blur effekt
            if isEnabledBlur {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .blur(radius: max(0, 20 * animationSpeed))
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: isEnabledBlur)
            }
        }
    }
    
    // MARK: - Default Background
    private var defaultBackground: some View {
        LinearGradient(
            colors: colorScheme == .dark
            ? [Color(red: 0.05, green: 0.05, blue: 0.08), Color(red: 0.08, green: 0.08, blue: 0.12)]
            : [Color(red: 0.95, green: 0.95, blue: 0.98), Color(red: 0.90, green: 0.92, blue: 0.96)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - ViewType Enum
enum ViewType {
    case startView
    case multiplayerView
    case settingsView
}

#Preview {
    ZStack {
        CustomBackgroundView(viewType: .startView)
        
        VStack {
            Text("Start View")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
        }
    }
}
