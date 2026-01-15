//
//  NeonLightView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 14/01/26.
//  Updated with Mood Support on 15/01/26
//

import SwiftUI

struct NeonLightView: View {
    let color: Color
    let geometry: GeometryProxy
    let isAnimated: Bool
    let animationSpeed: Double
    let mood: AnimationMood // YANGI: Mood parametri qo'shildi
    
    // Asosiy animatsiya state'lari
    @State private var randomX: CGFloat = 0
    @State private var randomY: CGFloat = 0
    @State private var randomSize: CGFloat = 0
    @State private var animationOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    // YANGI: Random Flicker uchun state'lar
    @State private var flickerOpacity: Double = 1.0
    @State private var flickerBrightness: Double = 1.0
    
    // YANGI: Joyful Pulse uchun state'lar
    @State private var joyfulScale: CGFloat = 1.0
    @State private var joyfulBrightness: Double = 1.0
    
    // YANGI: Sad Fade uchun state'lar
    @State private var fadeOpacity: Double = 1.0
    @State private var fadeDarkness: Double = 0.0
    
    // YANGI: Angry Flash uchun state'lar
    @State private var flashOn: Bool = true
    @State private var flashIntensity: Double = 1.0
    
    // YANGI: Calm Wave uchun state'lar
    @State private var waveOffset: CGFloat = 0
    @State private var wavePhase: Double = 0
    
    // YANGI: Romantic Heartbeat uchun state'lar
    @State private var heartbeatScale: CGFloat = 1.0
    @State private var heartbeatGlow: Double = 1.0
    
    // YANGI: Energetic Rainbow uchun state'lar
    @State private var rainbowHue: Double = 0.0
    @State private var rainbowPosition: CGFloat = 0
    
    // YANGI: Mystic Glow uchun state'lar
    @State private var mysticHue: Double = 0.0
    @State private var mysticGlow: Double = 1.0
    @State private var mysticPulse: CGFloat = 1.0
    
    @StateObject private var motion = MotionManager()
    
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
            // Mood o'zgarganda animatsiyani yangilash
            if isAnimated {
                resetAnimationStates()
                startMoodAnimation()
            }
        }
        .onChange(of: isAnimated) { _, newValue in
            if newValue {
                startMoodAnimation()
            } else {
                resetAnimationStates()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    // Joriy rang (Rainbow mood uchun o'zgaradi)
    private var currentColor: Color {
        if mood == .energeticRainbow {
            return Color(hue: rainbowHue, saturation: 0.8, brightness: 0.9)
        } else if mood == .mysticGlow {
            return Color(hue: mysticHue, saturation: 0.7, brightness: 0.85)
        }
        return color
    }
    
    // Joriy opacity (har xil mood'lar uchun)
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
    
    // Joriy scale
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
    
    // Joriy brightness
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
            // Giroskopdan kelayotgan -1 va 1 oralig'idagi qiymatni 50 piksel oralig'iga ko'paytiramiz
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
            // Telefonni tepaga/pastga qiyshaytirganda harakatlanish
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
    
    // MARK: - Animation Functions (Placeholder'lar)
    
    private func startDefaultAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.0 / animationSpeed, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2.0)) {
                pulseScale = CGFloat.random(in: 0.95...1.05) // Kichikroq diapazon
            }
        }
    }
    
    private func startRandomFlickerAnimation() {
        // Keyingi bosqichda to'ldiramiz
        print("Random Flicker animation - coming soon!")
    }
    
    private func startJoyfulPulseAnimation() {
        // Keyingi bosqichda to'ldiramiz
        print("Joyful Pulse animation - coming soon!")
    }
    
    private func startSadFadeAnimation() {
        // Keyingi bosqichda to'ldiramiz
        print("Sad Fade animation - coming soon!")
    }
    
    private func startAngryFlashAnimation() {
        // Keyingi bosqichda to'ldiramiz
        print("Angry Flash animation - coming soon!")
    }
    
    private func startCalmWaveAnimation() {
        // Keyingi bosqichda to'ldiramiz
        print("Calm Wave animation - coming soon!")
    }
    
    private func startRomanticHeartbeatAnimation() {
        // Keyingi bosqichda to'ldiramiz
        print("Romantic Heartbeat animation - coming soon!")
    }
    
    private func startEnergeticRainbowAnimation() {
        // Keyingi bosqichda to'ldiramiz
        print("Energetic Rainbow animation - coming soon!")
    }
    
    private func startMysticGlowAnimation() {
        // Keyingi bosqichda to'ldiramiz
        print("Mystic Glow animation - coming soon!")
    }
}
