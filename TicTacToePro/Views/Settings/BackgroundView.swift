//
//  BackgroundView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 12/01/26.
//  Redesigned with premium UI on 12/01/26
//

import SwiftUI

struct SelectableColor: Identifiable, Hashable {
    let id = UUID()
    let color: Color
    var isSelected: Bool = false
}

// MARK: - Color Selection View
struct ColorSelectionView: View {
    @Binding var selectableColor: SelectableColor
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Premium Styling
    private var premiumGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.10),
                    Color(red: 0.11, green: 0.12, blue: 0.18),
                    Color(red: 0.03, green: 0.04, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.98, blue: 1.0),
                    Color(red: 0.95, green: 0.96, blue: 0.99),
                    Color(red: 0.90, green: 0.92, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
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
    
    @State private var isStartViewEnabled: Bool = true
    @State private var isMultiplayerViewEnabled: Bool = true
    @State private var isSettingsViewEnabled: Bool = true
    @State private var animationSpeed: Double = 0.5
    @State private var isEnabledAnimation: Bool = true
    @State private var isEnabledBlur: Bool = true
    
    @State private var colors: [SelectableColor] = [
        // Existing background base colors
        SelectableColor(color: .pink),
        SelectableColor(color: .blue),
        SelectableColor(color: .purple),
        SelectableColor(color: .cyan),
        SelectableColor(color: .indigo),

        // Apple system accent colors
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
                        // Header
                        headerSection
                        
                        // Background Colors Section
                        backgroundColorsSection
                        
                        // Head Text Colors Section
                        headTextColorsSection
                        
                        // Animation Section
                        animationSection
                        
                        // Tabs Section
                        tabsSection
                    }
                    .padding(.horizontal, isCompactHeightPhone ? 12 : 16)
                    .padding(.vertical, isCompactHeightPhone ? 16 : 24)
                    .frame(maxWidth: contentMaxWidth)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
                // Color Grid
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
                
                // Blur Toggle
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
                        
                        VStack(alignment: .leading, spacing: 2) {
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
                
            }
            .padding(.bottom, 8)
        }
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
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.11, green: 0.12, blue: 0.18), Color(red: 0.03, green: 0.04, blue: 0.06)]
                        : [Color(red: 0.98, green: 0.98, blue: 1.0), Color(red: 0.95, green: 0.96, blue: 0.99), Color(red: 0.90, green: 0.92, blue: 0.98)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Neon lights background
                ForEach(colors.filter { $0.isSelected }) { selectedColor in
                    NeonLightView(
                        color: selectedColor.color,
                        geometry: geometry,
                        isAnimated: isEnabledAnimation,
                        animationSpeed: animationSpeed
                    )
                }
                
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
                
                // Optional blur controlled by toggle
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
