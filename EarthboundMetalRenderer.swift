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

struct CRTUniforms {
    var time: Float = 0
    var scanlineIntensity: Float = 0.3
    var pixelSize: Float = 2.0
    var curvature: Float = 0.02
    var vignetteStrength: Float = 0.25
}

class EarthboundMetalRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let library: MTLLibrary
    
    // Screen dimensions for scaling
    private var screenWidth: Int = 1024
    private var screenHeight: Int = 768
    
    // Compute pipelines
    private let patternGenerationPipeline: MTLComputePipelineState
    private let distortionPipeline: MTLComputePipelineState
    private let blendPipeline: MTLComputePipelineState
    private let crtPipeline: MTLComputePipelineState
    
    // Render pipeline for final display
    private let renderPipeline: MTLRenderPipelineState
    
    // Textures
    private var layer1BaseTexture: MTLTexture?
    private var layer1DistortedTexture: MTLTexture?
    private var layer2BaseTexture: MTLTexture?
    private var layer2DistortedTexture: MTLTexture?
    private var finalTexture: MTLTexture?
    private var crtTexture: MTLTexture?
    
    // Samplers
    private let linearSampler: MTLSamplerState
    private let nearestSampler: MTLSamplerState
    
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
              let blendFunction = lib.makeFunction(name: "blendLayers"),
              let crtFunction = lib.makeFunction(name: "applyCRTEffect") else {
            return nil
        }
        
        do {
            patternGenerationPipeline = try device.makeComputePipelineState(function: patternFunction)
            distortionPipeline = try device.makeComputePipelineState(function: distortionFunction)
            blendPipeline = try device.makeComputePipelineState(function: blendFunction)
            crtPipeline = try device.makeComputePipelineState(function: crtFunction)
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
        
        // Create nearest neighbor sampler for chunky pixel scaling
        let nearestSamplerDescriptor = MTLSamplerDescriptor()
        nearestSamplerDescriptor.minFilter = .nearest
        nearestSamplerDescriptor.magFilter = .nearest
        nearestSamplerDescriptor.mipFilter = .nearest
        nearestSamplerDescriptor.sAddressMode = .clampToEdge
        nearestSamplerDescriptor.tAddressMode = .clampToEdge
        
        guard let nearestSampler = device.makeSamplerState(descriptor: nearestSamplerDescriptor) else {
            return nil
        }
        self.nearestSampler = nearestSampler
    }
    
    func updateTextures(width: Int, height: Int) {
        // Store actual screen size for final scaling
        screenWidth = width
        screenHeight = height
        
        // Use authentic SNES resolution for that classic low-res chunky pixel feel
        let snesWidth = 256
        let snesHeight = 224
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: snesWidth,
            height: snesHeight,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        layer1BaseTexture = device.makeTexture(descriptor: textureDescriptor)
        layer1DistortedTexture = device.makeTexture(descriptor: textureDescriptor)
        layer2BaseTexture = device.makeTexture(descriptor: textureDescriptor)
        layer2DistortedTexture = device.makeTexture(descriptor: textureDescriptor)
        finalTexture = device.makeTexture(descriptor: textureDescriptor)
        crtTexture = device.makeTexture(descriptor: textureDescriptor)
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
              let final = finalTexture,
              let crt = crtTexture else {
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
        let dynamicAlpha = 0.55 + 0.45 * sin(time * 0.5)
        blendLayers(commandBuffer: commandBuffer,
                   layer1: layer1Distorted,
                   layer2: layer2Distorted,
                   output: final,
                   alpha: dynamicAlpha)
        
        // Apply CRT effect
        applyCRTEffect(commandBuffer: commandBuffer,
                      inputTexture: final,
                      outputTexture: crt,
                      time: time)
        
        // Final render to drawable
        renderToDrawable(commandBuffer: commandBuffer,
                        texture: crt,
                        drawable: drawable)
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func renderTransition(currentBackground: EarthboundBackground,
                         nextBackground: EarthboundBackground,
                         alpha: Float,
                         time: Float,
                         layer1ScrollOffset: SIMD2<Float>,
                         layer2ScrollOffset: SIMD2<Float>,
                         drawable: CAMetalDrawable) {
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let layer1BaseCurrent = layer1BaseTexture,
              let layer1DistortedCurrent = layer1DistortedTexture,
              let layer2BaseCurrent = layer2BaseTexture,
              let layer2DistortedCurrent = layer2DistortedTexture,
              let finalCurrent = finalTexture,
              let crt = crtTexture else { return }
        
        // We need additional textures for the next background
        // Use same format as main textures to prevent corruption
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: layer1BaseCurrent.width,
            height: layer1BaseCurrent.height,
            mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let layer1BaseNext = device.makeTexture(descriptor: textureDescriptor),
              let layer1DistortedNext = device.makeTexture(descriptor: textureDescriptor),
              let layer2BaseNext = device.makeTexture(descriptor: textureDescriptor),
              let layer2DistortedNext = device.makeTexture(descriptor: textureDescriptor),
              let finalNext = device.makeTexture(descriptor: textureDescriptor) else { return }
        
        // Render current background
        generatePattern(commandBuffer: commandBuffer, layer: currentBackground.layer1, outputTexture: layer1BaseCurrent)
        generatePattern(commandBuffer: commandBuffer, layer: currentBackground.layer2, outputTexture: layer2BaseCurrent)
        
        if let distortion = currentBackground.layer1.distortion {
            applyDistortion(commandBuffer: commandBuffer,
                           inputTexture: layer1BaseCurrent,
                           outputTexture: layer1DistortedCurrent,
                           distortion: distortion,
                           time: time,
                           scrollOffset: layer1ScrollOffset)
        } else {
            copyTexture(commandBuffer: commandBuffer, from: layer1BaseCurrent, to: layer1DistortedCurrent)
        }
        
        if let distortion = currentBackground.layer2.distortion {
            applyDistortion(commandBuffer: commandBuffer,
                           inputTexture: layer2BaseCurrent,
                           outputTexture: layer2DistortedCurrent,
                           distortion: distortion,
                           time: time,
                           scrollOffset: layer2ScrollOffset)
        } else {
            copyTexture(commandBuffer: commandBuffer, from: layer2BaseCurrent, to: layer2DistortedCurrent)
        }
        
        let dynamicAlphaCurrent = 0.55 + 0.45 * sin(time * 0.5)
        blendLayers(commandBuffer: commandBuffer,
                   layer1: layer1DistortedCurrent,
                   layer2: layer2DistortedCurrent,
                   output: finalCurrent,
                   alpha: dynamicAlphaCurrent)
        
        // Render next background
        generatePattern(commandBuffer: commandBuffer, layer: nextBackground.layer1, outputTexture: layer1BaseNext)
        generatePattern(commandBuffer: commandBuffer, layer: nextBackground.layer2, outputTexture: layer2BaseNext)
        
        if let distortion = nextBackground.layer1.distortion {
            applyDistortion(commandBuffer: commandBuffer,
                           inputTexture: layer1BaseNext,
                           outputTexture: layer1DistortedNext,
                           distortion: distortion,
                           time: time,
                           scrollOffset: layer1ScrollOffset)
        } else {
            copyTexture(commandBuffer: commandBuffer, from: layer1BaseNext, to: layer1DistortedNext)
        }
        
        if let distortion = nextBackground.layer2.distortion {
            applyDistortion(commandBuffer: commandBuffer,
                           inputTexture: layer2BaseNext,
                           outputTexture: layer2DistortedNext,
                           distortion: distortion,
                           time: time,
                           scrollOffset: layer2ScrollOffset)
        } else {
            copyTexture(commandBuffer: commandBuffer, from: layer2BaseNext, to: layer2DistortedNext)
        }
        
        let dynamicAlphaNext = 0.55 + 0.45 * sin(time * 0.5)
        blendLayers(commandBuffer: commandBuffer,
                   layer1: layer1DistortedNext,
                   layer2: layer2DistortedNext,
                   output: finalNext,
                   alpha: dynamicAlphaNext)
        
        // Crossfade between current and next backgrounds
        blendLayers(commandBuffer: commandBuffer,
                   layer1: finalCurrent,
                   layer2: finalNext,
                   output: crt, // Use CRT texture as intermediate
                   alpha: alpha)
        
        // Apply CRT effect to the crossfaded result
        applyCRTEffect(commandBuffer: commandBuffer,
                      inputTexture: crt,
                      outputTexture: finalCurrent, // Reuse as final output
                      time: time)
        
        // Final render to drawable
        renderToDrawable(commandBuffer: commandBuffer,
                        texture: finalCurrent,
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
        
        // Read distortion intensity from user defaults
        let defaults = UserDefaults.standard
        var distortionIntensity = Float(defaults.double(forKey: "EarthboundDistortionIntensity"))
        if distortionIntensity == 0 {
            distortionIntensity = 1.0
        }
        
        let t2 = time * time
        var uniforms = DistortionUniforms()
        uniforms.time = time
        uniforms.amplitude = (distortion.amplitude + distortion.amplitudeAcceleration * t2) * distortionIntensity
        uniforms.amplitudeAccel = distortion.amplitudeAcceleration * distortionIntensity
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
    
    private func applyCRTEffect(commandBuffer: MTLCommandBuffer,
                               inputTexture: MTLTexture,
                               outputTexture: MTLTexture,
                               time: Float) {
        
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        computeEncoder.setComputePipelineState(crtPipeline)
        computeEncoder.setTexture(inputTexture, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)
        
        // Read CRT settings from user defaults
        let defaults = UserDefaults.standard
        let crtEnabled = defaults.object(forKey: "EarthboundCRTEnabled") as? Bool ?? true
        
        var uniforms = CRTUniforms()
        uniforms.time = time
        
        if crtEnabled {
            uniforms.scanlineIntensity = Float(defaults.double(forKey: "EarthboundScanlineIntensity"))
            if uniforms.scanlineIntensity == 0 && defaults.object(forKey: "EarthboundScanlineIntensity") == nil {
                uniforms.scanlineIntensity = 0.25
            }
            
            uniforms.pixelSize = Float(defaults.double(forKey: "EarthboundPixelSize"))
            if uniforms.pixelSize == 0 {
                uniforms.pixelSize = 3.0
            }
            
            uniforms.curvature = Float(defaults.double(forKey: "EarthboundCurvature"))
            if uniforms.curvature == 0 && defaults.object(forKey: "EarthboundCurvature") == nil {
                uniforms.curvature = 0.015
            }
            
            uniforms.vignetteStrength = Float(defaults.double(forKey: "EarthboundVignette"))
            if uniforms.vignetteStrength == 0 && defaults.object(forKey: "EarthboundVignette") == nil {
                uniforms.vignetteStrength = 0.2
            }
        } else {
            // CRT disabled - set all effects to minimal/off
            uniforms.scanlineIntensity = 0.0
            uniforms.pixelSize = 1.0
            uniforms.curvature = 0.0
            uniforms.vignetteStrength = 0.0
        }
        
        computeEncoder.setBytes(&uniforms, length: MemoryLayout<CRTUniforms>.size, index: 0)
        
        let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroups = MTLSize(
            width: (outputTexture.width + threadgroupSize.width - 1) / threadgroupSize.width,
            height: (outputTexture.height + threadgroupSize.height - 1) / threadgroupSize.height,
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
        renderEncoder.setFragmentSamplerState(nearestSampler, index: 0)
        
        // Draw fullscreen quad using vertex_id generation in shader
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
}