//
//  NeonLightView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 14/01/26.
//

import SwiftUI

struct NeonLightView: View {
    let color: Color
    let geometry: GeometryProxy
    let isAnimated: Bool
    let animationSpeed: Double
    
    @State private var randomX: CGFloat = 0
    @State private var randomY: CGFloat = 0
    @State private var randomSize: CGFloat = 0
    @State private var animationOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // 1. Eng chetki juda yumshoq nur (Extreme Outer Glow) – o'zgartirildi: yumshoqlik va kontrast uchun
            Circle()
                .fill(color.opacity(0.10))
                .frame(width: randomSize * 5, height: randomSize * 5)
                .blur(radius: 45)
            
            // 2. Asosiy rangli nur (Main Color Glow) – o'zgartirildi: rang kuchaytirildi, aniqlik oshirildi
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.65), color.opacity(0.25), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: randomSize * 1.3
                    )
                )
                .frame(width: randomSize * 2.6, height: randomSize * 2.6)
                .blur(radius: 20)
            
            // 3. Markaziy yorqin nuqta (Bright Core) – o'zgartirildi: oq rang olib tashlandi, faqat neon rangi, yorqinlik saqlandi
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(1.0), color.opacity(0.85), color.opacity(0.4)],
                        center: .center,
                        startRadius: 0,
                        endRadius: randomSize * 0.5
                    )
                )
                .frame(width: randomSize, height: randomSize)
                .blur(radius: 2.5)
        }
        .scaleEffect(pulseScale)
        .position(x: randomX + animationOffset, y: randomY)
        .blendMode(.plusLighter) // Ranglarni bir-biriga qo'shib, yorqinlikni oshiradi
        .drawingGroup() // Performansni yaxshilash uchun qo'shildi, lekin asosiy struktura buzilmadi
        .onAppear {
            generateRandomPosition()
            if isAnimated { startAnimation() }
        }
    }
    
    private func generateRandomPosition() {
        randomSize = CGFloat.random(in: 80...150) // Biroz kichikroq lekin zichroq
        let padding: CGFloat = 0
        randomX = CGFloat.random(in: padding...(geometry.size.width - padding))
        randomY = CGFloat.random(in: padding...(geometry.size.height - padding))
    }
    
    private func startAnimation() {
        // Animatsiya kuchaytirildi: siljish kengroq, pulse kuchliroq
        withAnimation(.easeInOut(duration: 4.5 / animationSpeed).repeatForever(autoreverses: true)) {
            animationOffset = CGFloat.random(in: -80...80) // Kuchaytirilgan siljish
        }
        
        withAnimation(.easeInOut(duration: 2.5 / animationSpeed).repeatForever(autoreverses: true)) {
            pulseScale = CGFloat.random(in: 0.85...1.25) // Kuchaytirilgan pulsatsiya
        }
    }
}
