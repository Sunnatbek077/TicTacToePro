//
//  ConfettiView.swift
//  TicTacToePro watchOS
//
//  Refactored for watchOS by Claude
//

import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle]
    @State private var t: Double = 0.0
    
    init() {
        // Fewer particles for watchOS performance (15 instead of 40)
        self._particles = State(initialValue: (0..<15).map { _ in ConfettiParticle.random() })
    }
    
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                // Lighter blur for better performance
                ctx.addFilter(.blur(radius: 1))
                for i in particles.indices {
                    let p = particles[i]
                    let x = p.startX * size.width + p.dx * t
                    let y = p.startY * size.height + p.dy * t + 0.5 * p.gravity * t * t
                    let rect = CGRect(x: x, y: y, width: p.size, height: p.size)
                    ctx.fill(Path(ellipseIn: rect), with: .color(p.color.opacity(1.0 - t * 0.3)))
                }
            }
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeOut(duration: 2.0)) {
                    t = 2.0
                }
            }
        }
    }
}

struct ConfettiParticle {
    var startX: Double
    var startY: Double
    var dx: Double
    var dy: Double
    var gravity: Double
    var size: CGFloat
    var color: Color
    
    static func random() -> ConfettiParticle {
        ConfettiParticle(
            startX: Double.random(in: 0.1...0.9),
            startY: Double.random(in: -0.1...0.2),
            dx: Double.random(in: -0.6...0.6) * 300, // Reduced motion
            dy: Double.random(in: 0.3...1.0) * 300,  // Reduced motion
            gravity: Double.random(in: 120...400),    // Reduced gravity
            size: CGFloat.random(in: 6...14),         // Smaller particles
            color: [
                Color.red, Color.green, Color.blue,
                Color.yellow, Color.purple, Color.orange,
                Color.pink, Color.cyan
            ].randomElement() ?? Color.red
        )
    }
}
