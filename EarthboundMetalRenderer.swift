import Foundation
import Metal
import MetalKit
import simd

struct DistortionUniforms {
    var time: Float = 0
    var amplitude: Float = 0
    var amplitudeAccel: Float = 0
    var frequency: Float = 0
    var frequencyAccel: Float = 0
    var compression: Float = 0
    var compressionAccel: Float = 0
    var speed: Float = 0
    var type: Int32 = 1
    var scrollOffset: SIMD2<Float> = SIMD2<Float>(0, 0)
}

struct PatternUniforms {
    var patternIndex: Int32 = 0
    var paletteIndex: Int32 = 0
    var textureSize: SIMD2<UInt32> = SIMD2<UInt32>(256, 256)
}

class EarthboundMetalRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary
    
    // Compute pipelines
    private let patternGenerationPipeline: MTLComputePipelineState
    private let distortionPipeline: MTLComputePipelineState
    private let blendPipeline: MTLComputePipelineState
    
    // Render pipeline for final display
    private let renderPipeline: MTLRenderPipelineState
    
    // Textures
    private var layer1BaseTexture: MTLTexture?
    private var layer1DistortedTexture: MTLTexture?
    private var layer2BaseTexture: MTLTexture?
    private var layer2DistortedTexture: MTLTexture?
    private var finalTexture: MTLTexture?
    
    // Samplers
    private let linearSampler: MTLSamplerState
    
    init?(device: MTLDevice) {
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        self.commandQueue = commandQueue
        
        // Load shaders from bundle resources
        let bundle = Bundle(for: EarthboundBattleView.self)
        
        // Try loading from metallib file in Resources
        var library: MTLLibrary? = nil
        if let metallibURL = bundle.url(forResource: "default", withExtension: "metallib") {
            do {
                library = try device.makeLibrary(URL: metallibURL)
            } catch {
                // Silently fall back to default library
            }
        }
        
        // Fallback to default library
        if library == nil {
            library = device.makeDefaultLibrary()
        }
        
        guard let lib = library else {
            return nil
        }
        self.library = lib
        
        // Create compute pipelines
        guard let patternFunction = lib.makeFunction(name: "generatePattern"),
              let distortionFunction = lib.makeFunction(name: "applyDistortion"),
              let blendFunction = lib.makeFunction(name: "blendLayers") else {
            return nil
        }
        
        do {
            patternGenerationPipeline = try device.makeComputePipelineState(function: patternFunction)
            distortionPipeline = try device.makeComputePipelineState(function: distortionFunction)
            blendPipeline = try device.makeComputePipelineState(function: blendFunction)
        } catch {
            print("Failed to create compute pipelines: \(error)")
            return nil
        }
        
        // Create render pipeline
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = lib.makeFunction(name: "vertexShader")
        renderPipelineDescriptor.fragmentFunction = lib.makeFunction(name: "fragmentShader")
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            renderPipeline = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print("Failed to create render pipeline: \(error)")
            return nil
        }
        
        // Create sampler
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .nearest
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        
        guard let sampler = device.makeSamplerState(descriptor: samplerDescriptor) else {
            return nil
        }
        self.linearSampler = sampler
    }
    
    func updateTextures(width: Int, height: Int) {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        layer1BaseTexture = device.makeTexture(descriptor: textureDescriptor)
        layer1DistortedTexture = device.makeTexture(descriptor: textureDescriptor)
        layer2BaseTexture = device.makeTexture(descriptor: textureDescriptor)
        layer2DistortedTexture = device.makeTexture(descriptor: textureDescriptor)
        finalTexture = device.makeTexture(descriptor: textureDescriptor)
    }
    
    func render(background: EarthboundBackground, 
                time: Float,
                layer1ScrollOffset: SIMD2<Float>,
                layer2ScrollOffset: SIMD2<Float>,
                drawable: CAMetalDrawable) {
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let layer1Base = layer1BaseTexture,
              let layer1Distorted = layer1DistortedTexture,
              let layer2Base = layer2BaseTexture,
              let layer2Distorted = layer2DistortedTexture,
              let final = finalTexture else {
            return
        }
        
        // Generate layer 1 pattern
        generatePattern(commandBuffer: commandBuffer,
                       layer: background.layer1,
                       outputTexture: layer1Base)
        
        // Generate layer 2 pattern
        generatePattern(commandBuffer: commandBuffer,
                       layer: background.layer2,
                       outputTexture: layer2Base)
        
        // Apply distortion to layer 1
        if let distortion = background.layer1.distortion {
            applyDistortion(commandBuffer: commandBuffer,
                           inputTexture: layer1Base,
                           outputTexture: layer1Distorted,
                           distortion: distortion,
                           time: time,
                           scrollOffset: layer1ScrollOffset)
        } else {
            // Copy without distortion
            copyTexture(commandBuffer: commandBuffer, from: layer1Base, to: layer1Distorted)
        }
        
        // Apply distortion to layer 2
        if let distortion = background.layer2.distortion {
            applyDistortion(commandBuffer: commandBuffer,
                           inputTexture: layer2Base,
                           outputTexture: layer2Distorted,
                           distortion: distortion,
                           time: time,
                           scrollOffset: layer2ScrollOffset)
        } else {
            // Copy without distortion
            copyTexture(commandBuffer: commandBuffer, from: layer2Base, to: layer2Distorted)
        }
        
        // Blend layers with dynamic alpha based on time
        let dynamicAlpha = 0.5 + 0.3 * sin(time * 0.5)
        blendLayers(commandBuffer: commandBuffer,
                   layer1: layer1Distorted,
                   layer2: layer2Distorted,
                   output: final,
                   alpha: dynamicAlpha)
        
        // Final render to drawable
        renderToDrawable(commandBuffer: commandBuffer,
                        texture: final,
                        drawable: drawable)
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func generatePattern(commandBuffer: MTLCommandBuffer,
                                layer: BackgroundLayer,
                                outputTexture: MTLTexture) {
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        computeEncoder.setComputePipelineState(patternGenerationPipeline)
        computeEncoder.setTexture(outputTexture, index: 0)
        
        var uniforms = PatternUniforms()
        uniforms.patternIndex = Int32(layer.patternIndex)
        uniforms.paletteIndex = Int32(layer.paletteIndex)
        uniforms.textureSize = SIMD2<UInt32>(UInt32(outputTexture.width), UInt32(outputTexture.height))
        
        
        computeEncoder.setBytes(&uniforms, length: MemoryLayout<PatternUniforms>.size, index: 0)
        
        let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroups = MTLSize(
            width: (outputTexture.width + threadgroupSize.width - 1) / threadgroupSize.width,
            height: (outputTexture.height + threadgroupSize.height - 1) / threadgroupSize.height,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        computeEncoder.endEncoding()
    }
    
    private func applyDistortion(commandBuffer: MTLCommandBuffer,
                                inputTexture: MTLTexture,
                                outputTexture: MTLTexture,
                                distortion: DistortionEffect,
                                time: Float,
                                scrollOffset: SIMD2<Float>) {
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(distortionPipeline)
        computeEncoder.setTexture(inputTexture, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)
        
        let t2 = time * time
        var uniforms = DistortionUniforms()
        uniforms.time = time
        uniforms.amplitude = distortion.amplitude + distortion.amplitudeAcceleration * t2
        uniforms.amplitudeAccel = distortion.amplitudeAcceleration
        uniforms.frequency = distortion.frequency + distortion.frequencyAcceleration * t2
        uniforms.frequencyAccel = distortion.frequencyAcceleration
        uniforms.compression = distortion.compression + distortion.compressionAcceleration * t2
        uniforms.compressionAccel = distortion.compressionAcceleration
        uniforms.speed = distortion.speed * time
        uniforms.type = Int32(distortion.type.rawValue)
        uniforms.scrollOffset = scrollOffset
        
        computeEncoder.setBytes(&uniforms, length: MemoryLayout<DistortionUniforms>.size, index: 0)
        
        let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroups = MTLSize(
            width: (outputTexture.width + threadgroupSize.width - 1) / threadgroupSize.width,
            height: (outputTexture.height + threadgroupSize.height - 1) / threadgroupSize.height,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        computeEncoder.endEncoding()
    }
    
    private func blendLayers(commandBuffer: MTLCommandBuffer,
                            layer1: MTLTexture,
                            layer2: MTLTexture,
                            output: MTLTexture,
                            alpha: Float) {
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(blendPipeline)
        computeEncoder.setTexture(layer1, index: 0)
        computeEncoder.setTexture(layer2, index: 1)
        computeEncoder.setTexture(output, index: 2)
        
        var alphaValue = alpha
        computeEncoder.setBytes(&alphaValue, length: MemoryLayout<Float>.size, index: 0)
        
        let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroups = MTLSize(
            width: (output.width + threadgroupSize.width - 1) / threadgroupSize.width,
            height: (output.height + threadgroupSize.height - 1) / threadgroupSize.height,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        computeEncoder.endEncoding()
    }
    
    private func copyTexture(commandBuffer: MTLCommandBuffer, from source: MTLTexture, to destination: MTLTexture) {
        guard let blitEncoder = commandBuffer.makeBlitCommandEncoder() else { return }
        
        blitEncoder.copy(from: source,
                        sourceSlice: 0,
                        sourceLevel: 0,
                        sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                        sourceSize: MTLSize(width: source.width, height: source.height, depth: 1),
                        to: destination,
                        destinationSlice: 0,
                        destinationLevel: 0,
                        destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        
        blitEncoder.endEncoding()
    }
    
    private func renderToDrawable(commandBuffer: MTLCommandBuffer,
                                 texture: MTLTexture,
                                 drawable: CAMetalDrawable) {
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setFragmentSamplerState(linearSampler, index: 0)
        
        // Draw fullscreen quad using vertex_id generation in shader
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
}