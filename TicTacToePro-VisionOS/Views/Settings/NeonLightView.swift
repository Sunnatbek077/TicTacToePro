//
//  NeonLightView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 14/01/26.
//  Updated with Mood Support on 15/01/26
//  Complete Implementation on 17/01/26
//

import SwiftUI

struct NeonLightView: View {
    let color: Color
    let geometry: GeometryProxy
    let isAnimated: Bool
    let animationSpeed: Double
    let mood: AnimationMood
    
    // Asosiy animatsiya state'lari
    @State private var randomX: CGFloat = 0
    @State private var randomY: CGFloat = 0
    @State private var randomSize: CGFloat = 0
    @State private var animationOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    // Random Flicker uchun state'lar
    @State private var flickerOpacity: Double = 1.0
    @State private var flickerBrightness: Double = 1.0
    
    // Joyful Pulse uchun state'lar
    @State private var joyfulScale: CGFloat = 1.0
    @State private var joyfulBrightness: Double = 1.0
    
    // Sad Fade uchun state'lar
    @State private var fadeOpacity: Double = 1.0
    @State private var fadeDarkness: Double = 0.0
    
    // Angry Flash uchun state'lar
    @State private var flashOn: Bool = true
    @State private var flashIntensity: Double = 1.0
    
    // Calm Wave uchun state'lar
    @State private var waveOffset: CGFloat = 0
    @State private var wavePhase: Double = 0
    
    // Romantic Heartbeat uchun state'lar
    @State private var heartbeatScale: CGFloat = 1.0
    @State private var heartbeatGlow: Double = 1.0
    
    // Energetic Rainbow uchun state'lar
    @State private var rainbowHue: Double = 0.0
    @State private var rainbowPosition: CGFloat = 0
    
    // Mystic Glow uchun state'lar
    @State private var mysticHue: Double = 0.0
    @State private var mysticGlow: Double = 1.0
    @State private var mysticPulse: CGFloat = 1.0
    
    @StateObject private var motion = MotionManager()
    
    // Timer management
    @State private var animationTimer: Timer?
    
    var body: some View {
        ZStack {
            // 1. Eng chetki juda yumshoq nur (Extreme Outer Glow)
            Circle()
                .fill(currentColor.opacity(0.10 * currentOpacity))
                .frame(width: randomSize * 5, height: randomSize * 5)
                .blur(radius: 45)
            
            // 2. Asosiy rangli nur (Main Color Glow)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            currentColor.opacity(0.65 * currentOpacity),
                            currentColor.opacity(0.25 * currentOpacity),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: randomSize * 1.3
                    )
                )
                .frame(width: randomSize * 2.6, height: randomSize * 2.6)
                .blur(radius: 20)
            
            // 3. Markaziy yorqin nuqta (Bright Core)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            currentColor.opacity(1.0 * currentOpacity),
                            currentColor.opacity(0.85 * currentOpacity),
                            currentColor.opacity(0.4 * currentOpacity)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: randomSize * 0.5
                    )
                )
                .frame(width: randomSize, height: randomSize)
                .blur(radius: 2.5)
        }
        .scaleEffect(currentScale)
        .brightness(currentBrightness)
        .position(x: randomX + currentXOffset, y: randomY + currentYOffset)
        .blendMode(.plusLighter)
        .drawingGroup()
        .onAppear {
            generateRandomPosition()
            if isAnimated {
                startMoodAnimation()
            }
        }
        .onChange(of: mood) { _, _ in
            if isAnimated {
                stopAllAnimations()
                resetAnimationStates()
                startMoodAnimation()
            }
        }
        .onChange(of: isAnimated) { _, newValue in
            if newValue {
                startMoodAnimation()
            } else {
                stopAllAnimations()
                resetAnimationStates()
            }
        }
        .onDisappear {
            stopAllAnimations()
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentColor: Color {
        if mood == .energeticRainbow {
            return Color(hue: rainbowHue, saturation: 0.8, brightness: 0.9)
        } else if mood == .mysticGlow {
            return Color(hue: mysticHue, saturation: 0.7, brightness: 0.85)
        }
        return color
    }
    
    private var currentOpacity: Double {
        switch mood {
        case .randomFlicker:
            return flickerOpacity
        case .sadFade:
            return fadeOpacity
        case .angryFlash:
            return flashOn ? 1.0 : 0.3
        default:
            return 1.0
        }
    }
    
    private var currentScale: CGFloat {
        switch mood {
        case .joyfulPulse:
            return joyfulScale
        case .romanticHeartbeat:
            return heartbeatScale
        case .mysticGlow:
            return mysticPulse
        default:
            return pulseScale
        }
    }
    
    private var currentBrightness: Double {
        switch mood {
        case .randomFlicker:
            return flickerBrightness - 0.5
        case .joyfulPulse:
            return joyfulBrightness - 0.5
        case .sadFade:
            return -fadeDarkness
        case .angryFlash:
            return flashIntensity - 0.5
        case .romanticHeartbeat:
            return heartbeatGlow - 0.5
        case .mysticGlow:
            return mysticGlow - 0.5
        default:
            return 0
        }
    }
    
    private var currentXOffset: CGFloat {
        let gyroShift = CGFloat(motion.x) * 50
        
        switch mood {
        case .calmWave:
            return waveOffset + gyroShift
        case .energeticRainbow:
            return rainbowPosition + gyroShift
        default:
            return animationOffset + gyroShift
        }
    }
    
    private var currentYOffset: CGFloat {
        let gyroShift = CGFloat(motion.y) * 50
        
        switch mood {
        case .calmWave:
            return (sin(wavePhase) * 30) + gyroShift
        default:
            return gyroShift
        }
    }
    
    // MARK: - Helper Functions
    
    private func generateRandomPosition() {
        randomSize = CGFloat.random(in: 80...150)
        let padding: CGFloat = 0
        randomX = CGFloat.random(in: padding...(geometry.size.width - padding))
        randomY = CGFloat.random(in: padding...(geometry.size.height - padding))
    }
    
    private func resetAnimationStates() {
        flickerOpacity = 1.0
        flickerBrightness = 1.0
        joyfulScale = 1.0
        joyfulBrightness = 1.0
        fadeOpacity = 1.0
        fadeDarkness = 0.0
        flashOn = true
        flashIntensity = 1.0
        waveOffset = 0
        wavePhase = 0
        heartbeatScale = 1.0
        heartbeatGlow = 1.0
        rainbowHue = 0.0
        rainbowPosition = 0
        mysticHue = 0.0
        mysticGlow = 1.0
        mysticPulse = 1.0
        animationOffset = 0
        pulseScale = 1.0
    }
    
    private func stopAllAnimations() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    // MARK: - Main Animation Starter
    
    private func startMoodAnimation() {
        switch mood {
        case .none:
            startDefaultAnimation()
        case .randomFlicker:
            startRandomFlickerAnimation()
        case .joyfulPulse:
            startJoyfulPulseAnimation()
        case .sadFade:
            startSadFadeAnimation()
        case .angryFlash:
            startAngryFlashAnimation()
        case .calmWave:
            startCalmWaveAnimation()
        case .romanticHeartbeat:
            startRomanticHeartbeatAnimation()
        case .energeticRainbow:
            startEnergeticRainbowAnimation()
        case .mysticGlow:
            startMysticGlowAnimation()
        }
    }
    
    // MARK: - Animation Functions
    
    // 1. Default Animation - Oddiy pulse
    private func startDefaultAnimation() {
        let interval = max(0.1, 1.0 / animationSpeed)
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2.0)) {
                pulseScale = CGFloat.random(in: 0.95...1.05)
            }
        }
    }
    
    // 2. Random Flicker - Chaotic va energetic miltillash
    private func startRandomFlickerAnimation() {
        // Tez-tez o'zgaradigan random miltillash
        let baseInterval = max(0.05, 0.1 / animationSpeed)
        animationTimer = Timer.scheduledTimer(withTimeInterval: baseInterval, repeats: true) { _ in
            // Tasodifiy tezlikda o'zgarish
            let duration = Double.random(in: 0.05...0.2)
            withAnimation(.linear(duration: duration)) {
                flickerOpacity = Double.random(in: 0.3...1.0)
                flickerBrightness = Double.random(in: 0.5...1.5)
                pulseScale = CGFloat.random(in: 0.8...1.2)
            }
        }
    }
    
    // 3. Joyful Pulse - Quvnoq party atmosferasi
    private func startJoyfulPulseAnimation() {
        // Tez va ritmik pulse
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            joyfulScale = 1.15
        }
        
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            joyfulBrightness = 1.3
        }
        
        // Qo'shimcha harakat
        let interval = max(0.1, 0.3 / animationSpeed)
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            withAnimation(.spring(duration: 0.4, bounce: 0.6)) {
                animationOffset = CGFloat.random(in: -10...10)
            }
        }
    }
    
    // 4. Sad Fade - Melancholik va reflective
    private func startSadFadeAnimation() {
        // Sekin fade in/out
        withAnimation(.easeInOut(duration: 3.0 / animationSpeed).repeatForever(autoreverses: true)) {
            fadeOpacity = 0.3
        }
        
        withAnimation(.easeInOut(duration: 4.0 / animationSpeed).repeatForever(autoreverses: true)) {
            fadeDarkness = 0.4
        }
        
        // Sekin pastga tushish harakati
        withAnimation(.easeInOut(duration: 5.0 / animationSpeed).repeatForever(autoreverses: true)) {
            animationOffset = 20
        }
    }
    
    // 5. Angry Flash - Kuchli va aggressive
    private func startAngryFlashAnimation() {
        // Tez va keskin flash
        let interval = max(0.05, 0.15 / animationSpeed)
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                flashOn.toggle()
                flashIntensity = flashOn ? 1.5 : 0.5
                pulseScale = flashOn ? 1.2 : 0.9
            }
        }
    }
    
    // 6. Calm Wave - Tinch va osoyishta to'lqin
    private func startCalmWaveAnimation() {
        // Smooth horizontal wave
        withAnimation(.linear(duration: 4.0 / animationSpeed).repeatForever(autoreverses: false)) {
            wavePhase = .pi * 2
        }
        
        withAnimation(.easeInOut(duration: 3.0 / animationSpeed).repeatForever(autoreverses: true)) {
            waveOffset = 30
        }
        
        // Yumshoq pulse
        withAnimation(.easeInOut(duration: 2.5 / animationSpeed).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
    }
    
    // 7. Romantic Heartbeat - Issiq va mehribon yurak urishi
    private func startRomanticHeartbeatAnimation() {
        // Yurak urishi kabi ikki marta tez-tez pulse
        func performHeartbeat() {
            // Birinchi urish
            withAnimation(.easeOut(duration: 0.15)) {
                heartbeatScale = 1.15
                heartbeatGlow = 1.3
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeIn(duration: 0.15)) {
                    heartbeatScale = 1.0
                    heartbeatGlow = 1.0
                }
            }
            
            // Ikkinchi urish
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.15)) {
                    heartbeatScale = 1.12
                    heartbeatGlow = 1.2
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.15)) {
                    heartbeatScale = 1.0
                    heartbeatGlow = 1.0
                }
            }
        }
        
        // Har 1 sekundda yurak urishi
        let interval = max(0.5, 1.0 / animationSpeed)
        performHeartbeat()
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            performHeartbeat()
        }
    }
    
    // 8. Energetic Rainbow - High-energy disco vibe
    private func startEnergeticRainbowAnimation() {
        // Tez rang o'zgarishi
        withAnimation(.linear(duration: 2.0 / animationSpeed).repeatForever(autoreverses: false)) {
            rainbowHue = 1.0
        }
        
        // Tez harakat
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            rainbowPosition = 25
        }
        
        // Energetic pulse
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }
    }
    
    // 9. Mystic Glow - Dreamy va mysterious
    private func startMysticGlowAnimation() {
        // Sekin rang o'zgarishi (faqat purple-blue-indigo oralig'ida)
        withAnimation(.easeInOut(duration: 5.0 / animationSpeed).repeatForever(autoreverses: true)) {
            mysticHue = 0.8 // Purple dan blue gacha
        }
        
        // Mystic pulsation
        withAnimation(.easeInOut(duration: 2.5 / animationSpeed).repeatForever(autoreverses: true)) {
            mysticPulse = 1.15
            mysticGlow = 1.4
        }
        
        // Sekin aylanish harakati
        let interval = max(0.1, 0.5 / animationSpeed)
        var angle: Double = 0
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            angle += 0.1
            withAnimation(.easeInOut(duration: 1.0)) {
                animationOffset = sin(angle) * 15
            }
        }
        
        // Initial hue
        mysticHue = 0.7 // Indigo
    }
}
