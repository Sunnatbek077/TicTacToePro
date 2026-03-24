//
//  ConfettiView.swift
//  TicTacToePro
//

import SwiftUI

struct ConfettiView: View {
    let isSELikeSmallScreen: Bool
    @State private var particles: [ConfettiParticle]
    @State private var t: Double = 0.0
    
    init(isSELikeSmallScreen: Bool) {
        self.isSELikeSmallScreen = isSELikeSmallScreen
        #if os(tvOS)
        self._particles = State(initialValue: (0..<80).map { _ in ConfettiParticle.random() })
        #else
        self._particles = State(initialValue: (0..<(isSELikeSmallScreen ? 20 : 40)).map { _ in ConfettiParticle.random() })
        #endif
    }
    
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                ctx.addFilter(.blur(radius: 2))
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
                withAnimation(.easeOut(duration: 2.2)) {
                    t = 2.2
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
        #if os(tvOS)
        let sizeRange: ClosedRange<CGFloat> = 14...36
        let dxMultiplier: Double = 600
        let dyMultiplier: Double = 600
        let gravityRange: ClosedRange<Double> = 200...700
        #else
        let sizeRange: ClosedRange<CGFloat> = 8...20
        let dxMultiplier: Double = 400
        let dyMultiplier: Double = 400
        let gravityRange: ClosedRange<Double> = 150...500
        #endif
        return ConfettiParticle(
            startX: Double.random(in: 0.1...0.9),
            startY: Double.random(in: -0.1...0.2),
            dx: Double.random(in: -0.8...0.8) * dxMultiplier,
            dy: Double.random(in: 0.3...1.2) * dyMultiplier,
            gravity: Double.random(in: gravityRange),
            size: CGFloat.random(in: sizeRange),
            color: [Color.red, Color.green, Color.blue, Color.yellow, Color.purple, Color.orange, Color.pink, Color.cyan].randomElement() ?? Color.red
        )
    }
}
