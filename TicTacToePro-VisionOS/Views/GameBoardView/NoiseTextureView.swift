//
//  NoiseTextureView.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 20/09/25.
//  Updated with Metal shader-based noise effect
//

import SwiftUI
import MetalKit

// MARK: - Noise Texture for Premium Background
struct NoiseTextureView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            NoiseShaderView(size: geometry.size)
                .opacity(colorScheme == .dark ? 0.05 : 0.03)
                .blendMode(.overlay)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Noise Shader View
struct NoiseShaderView: UIViewRepresentable {
    let size: CGSize
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.frame = CGRect(origin: .zero, size: size)
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.enableSetNeedsDisplay = true
        mtkView.isOpaque = false
        
        // Set up the Metal shader
        let shader = NoiseShader()
        context.coordinator.shader = shader
        mtkView.delegate = context.coordinator
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        uiView.frame = CGRect(origin: .zero, size: size)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var shader: NoiseShader?
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            guard let shader = shader,
                  let drawable = view.currentDrawable,
                  let device = view.device else { return }
            
            shader.render(to: view, drawable: drawable, device: device)
        }
    }
}

// MARK: - Metal Shader for Noise
class NoiseShader {
    private var pipelineState: MTLRenderPipelineState?
    private var commandQueue: MTLCommandQueue?
    
    init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let library = try? device.makeDefaultLibrary(bundle: .main),
              let vertexFunction = library.makeFunction(name: "noiseVertexShader"),
              let fragmentFunction = library.makeFunction(name: "noiseFragmentShader") else {
            return
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        self.commandQueue = device.makeCommandQueue()
        self.pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func render(to view: MTKView, drawable: CAMetalDrawable, device: MTLDevice) {
        guard let commandQueue = commandQueue,
              let pipelineState = pipelineState,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        encoder.setRenderPipelineState(pipelineState)
        
        // Simple quad vertices for full-screen rendering
        let vertices: [SIMD2<Float>] = [
            [-1, -1], [1, -1], [-1, 1],
            [1, -1], [1, 1], [-1, 1]
        ]
        let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<SIMD2<Float>>.size, options: [])
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Pass time for animated noise
        var time = Float(CACurrentMediaTime())
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
