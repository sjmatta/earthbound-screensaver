import Foundation
import SpriteKit

enum DistortionType: Int {
    case horizontal = 1
    case horizontalInterlaced = 2
    case vertical = 3
}

struct DistortionEffect {
    let type: DistortionType
    let amplitude: Float
    let amplitudeAcceleration: Float
    let frequency: Float
    let frequencyAcceleration: Float
    let compression: Float
    let compressionAcceleration: Float
    let speed: Float
}

struct BackgroundLayer {
    let patternIndex: Int
    let paletteIndex: Int
    let distortion: DistortionEffect?
    let scrollSpeed: CGPoint
    
    func generatePattern(size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let palette = getPalette(paletteIndex)
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * bytesPerPixel
                let color = getPatternColor(x: x, y: y, patternIndex: patternIndex, palette: palette)
                
                pixelData[pixelIndex] = color.red
                pixelData[pixelIndex + 1] = color.green
                pixelData[pixelIndex + 2] = color.blue
                pixelData[pixelIndex + 3] = color.alpha
            }
        }
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        return context.makeImage()
    }
    
    private func getPalette(_ index: Int) -> [(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)] {
        switch index % 15 {
        case 0: // Fire palette
            return [
                (255, 0, 0, 255),
                (255, 128, 0, 255),
                (255, 255, 0, 255),
                (255, 192, 0, 255)
            ]
        case 1: // Ice palette
            return [
                (0, 128, 255, 255),
                (0, 192, 255, 255),
                (128, 224, 255, 255),
                (192, 240, 255, 255)
            ]
        case 2: // Psychedelic palette
            return [
                (255, 0, 255, 255),
                (0, 255, 255, 255),
                (255, 255, 0, 255),
                (128, 0, 255, 255)
            ]
        case 3: // Earth palette
            return [
                (139, 69, 19, 255),
                (160, 82, 45, 255),
                (205, 133, 63, 255),
                (222, 184, 135, 255)
            ]
        case 4: // Neon palette
            return [
                (255, 20, 147, 255),
                (0, 255, 127, 255),
                (255, 105, 180, 255),
                (127, 255, 212, 255)
            ]
        case 5: // Monochrome
            return [
                (64, 64, 64, 255),
                (128, 128, 128, 255),
                (192, 192, 192, 255),
                (255, 255, 255, 255)
            ]
        case 6: // Sunset palette
            return [
                (255, 94, 77, 255),
                (255, 157, 77, 255),
                (255, 206, 84, 255),
                (237, 117, 57, 255)
            ]
        case 7: // Ocean palette
            return [
                (0, 119, 190, 255),
                (0, 153, 219, 255),
                (72, 202, 228, 255),
                (144, 224, 239, 255)
            ]
        case 8: // Forest palette
            return [
                (34, 139, 34, 255),
                (50, 205, 50, 255),
                (124, 252, 0, 255),
                (173, 255, 47, 255)
            ]
        case 9: // Royal palette
            return [
                (75, 0, 130, 255),
                (138, 43, 226, 255),
                (147, 112, 219, 255),
                (186, 85, 211, 255)
            ]
        case 10: // Lava palette
            return [
                (128, 0, 0, 255),
                (255, 69, 0, 255),
                (255, 140, 0, 255),
                (255, 215, 0, 255)
            ]
        case 11: // Cosmic palette
            return [
                (25, 25, 112, 255),
                (65, 105, 225, 255),
                (100, 149, 237, 255),
                (135, 206, 250, 255)
            ]
        case 12: // Toxic palette
            return [
                (0, 255, 0, 255),
                (50, 205, 50, 255),
                (127, 255, 0, 255),
                (173, 255, 47, 255)
            ]
        case 13: // Candy palette
            return [
                (255, 192, 203, 255),
                (255, 182, 193, 255),
                (255, 105, 180, 255),
                (255, 20, 147, 255)
            ]
        default: // Rainbow palette
            return [
                (255, 0, 0, 255),
                (0, 255, 0, 255),
                (0, 0, 255, 255),
                (255, 255, 0, 255)
            ]
        }
    }
    
    private func getPatternColor(x: Int, y: Int, patternIndex: Int, palette: [(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8)]) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        // Guard against empty palette
        guard !palette.isEmpty else {
            return (255, 255, 255, 255) // White fallback
        }
        
        let colorIndex: Int
        
        switch patternIndex % 327 {
        case 0..<20: // Checkerboard patterns
            let size = 8 + (patternIndex % 20) * 4
            colorIndex = ((x / size) + (y / size))
            
        case 20..<40: // Stripe patterns
            let isVertical = (patternIndex % 2) == 0
            let stripeWidth = 4 + (patternIndex % 10) * 2
            colorIndex = (isVertical ? (x / stripeWidth) : (y / stripeWidth))
            
        case 40..<60: // Diagonal patterns
            let size = 8 + (patternIndex % 20) * 2
            colorIndex = ((x + y) / size)
            
        case 60..<80: // Circle patterns
            let centerX = 128
            let centerY = 128
            let dist = sqrt(Double((x - centerX) * (x - centerX) + (y - centerY) * (y - centerY)))
            let ringSize = 20.0 + Double(patternIndex % 20) * 5.0
            colorIndex = Int(dist / ringSize)
            
        case 80..<100: // Wave patterns
            let frequency = 0.05 + Double(patternIndex % 20) * 0.01
            let amplitude = 10.0 + Double(patternIndex % 20) * 2.0
            let wave = sin(Double(x) * frequency) * amplitude
            colorIndex = abs((y + Int(wave)) / 20)
            
        case 100..<120: // Grid patterns
            let gridSize = 16 + (patternIndex % 20) * 4
            let isGridLine = (x % gridSize < 2) || (y % gridSize < 2)
            if palette.count > 1 {
                colorIndex = isGridLine ? 0 : ((x / gridSize + y / gridSize) % (palette.count - 1) + 1)
            } else {
                colorIndex = 0
            }
            
        case 120..<140: // Diamond patterns
            let size = 16 + (patternIndex % 20) * 4
            let diamond = abs(x - 128) + abs(y - 128)
            colorIndex = (diamond / size)
            
        case 140..<160: // Spiral patterns
            let centerX = 128.0
            let centerY = 128.0
            let dx = Double(x) - centerX
            let dy = Double(y) - centerY
            let angle = atan2(dy, dx)
            let radius = sqrt(dx * dx + dy * dy)
            let spiral = (angle + radius * 0.1) * Double(1 + patternIndex % 20)
            colorIndex = abs(Int(spiral))
            
        case 160..<180: // Noise patterns
            let seed = patternIndex
            let hash = (x * 73856093 ^ y * 19349663 ^ seed * 83492791) & 0x7FFFFFFF
            colorIndex = hash
            
        case 180..<200: // Cross patterns
            let size = 8 + (patternIndex % 20) * 2
            let isCross = ((x % size) < 2) || ((y % size) < 2)
            colorIndex = isCross ? ((x + y) / size) : ((x * y) / (size * size))
            
        case 200..<220: // Hexagon patterns
            let size = 20.0 + Double(patternIndex % 20) * 2.0
            let hexY = Double(y) * 0.866
            let hexX = Double(x) + (y % 2 == 0 ? 0 : size / 2)
            colorIndex = (Int(hexX / size) + Int(hexY / size))
            
        case 220..<240: // Star patterns
            let centerX = 128
            let centerY = 128
            let dx = x - centerX
            let dy = y - centerY
            let angle = atan2(Double(dy), Double(dx))
            let points = 5 + (patternIndex % 20) / 4
            let star = sin(angle * Double(points)) * 50.0
            let dist = sqrt(Double(dx * dx + dy * dy))
            if palette.count >= 3 {
                colorIndex = (dist < star ? 0 : 1) + (abs(Int(angle * 10)) % (palette.count - 2))
            } else {
                colorIndex = dist < star ? 0 : 1
            }
            
        case 240..<260: // Gradient patterns
            let isHorizontal = (patternIndex % 2) == 0
            let gradientSteps = palette.count
            let position = isHorizontal ? x : y
            colorIndex = (position * gradientSteps / 256)
            
        case 260..<280: // Mosaic patterns
            let tileSize = 8 + (patternIndex % 20) * 2
            let tileX = x / tileSize
            let tileY = y / tileSize
            let hash = (tileX * 73856093 ^ tileY * 19349663 ^ patternIndex * 83492791) & 0x7FFFFFFF
            colorIndex = hash
            
        case 280..<300: // Fractal patterns
            var zx = Double(x - 128) / 64.0
            var zy = Double(y - 128) / 64.0
            let cx = -0.7 + Double(patternIndex % 20) * 0.05
            let cy = 0.27015
            var iteration = 0
            let maxIterations = 20
            
            while zx * zx + zy * zy < 4.0 && iteration < maxIterations {
                let tmp = zx * zx - zy * zy + cx
                zy = 2.0 * zx * zy + cy
                zx = tmp
                iteration += 1
            }
            colorIndex = iteration
            
        case 300..<320: // Organic patterns
            let scale = 0.05 + Double(patternIndex % 20) * 0.01
            let value1 = sin(Double(x) * scale) * cos(Double(y) * scale)
            let value2 = sin(Double(x + y) * scale * 0.7)
            let combined = (value1 + value2) * 2.0
            colorIndex = abs(Int(combined + 4))
            
        case 320..<327: // Special patterns
            let specialType = patternIndex - 320
            switch specialType {
            case 0: // Solid color
                colorIndex = 0
            case 1: // Two-tone alternating
                colorIndex = ((x + y) % 2)
            case 2: // Four-quadrant
                colorIndex = ((x < 128 ? 0 : 1) + (y < 128 ? 0 : 2))
            case 3: // Radial gradient
                let dist = sqrt(Double((x - 128) * (x - 128) + (y - 128) * (y - 128)))
                colorIndex = Int(dist / 30.0)
            case 4: // Concentric squares
                let dist = max(abs(x - 128), abs(y - 128))
                colorIndex = (dist / 20)
            case 5: // Random dots
                let hash = (x * 73856093 ^ y * 19349663) & 0x7FFFFFFF
                colorIndex = (hash % 100 < 10) ? (hash % 1000) : 0
            default: // Fallback to checkerboard
                colorIndex = ((x / 16) + (y / 16))
            }
            
        default:
            colorIndex = 0
        }
        
        let safeIndex = abs(colorIndex) % palette.count
        return palette[safeIndex]
    }
}

struct EarthboundBackground {
    let name: String
    let layer1: BackgroundLayer
    let layer2: BackgroundLayer
    
    static func getBackground(index: Int) -> EarthboundBackground {
        let backgrounds = getAllBackgrounds()
        return backgrounds[index % backgrounds.count]
    }
    
    static func getAllBackgrounds() -> [EarthboundBackground] {
        return [
            // Iconic Earthbound backgrounds
            EarthboundBackground(
                name: "Giygas Phase 1",
                layer1: BackgroundLayer(
                    patternIndex: 142, // Spiral pattern
                    paletteIndex: 0, // Fire palette
                    distortion: DistortionEffect(
                        type: .horizontal,
                        amplitude: 10,
                        amplitudeAcceleration: 0,
                        frequency: 0.02,
                        frequencyAcceleration: 0,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 0.7
                    ),
                    scrollSpeed: CGPoint(x: 0.15, y: 0)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 82, // Wave pattern
                    paletteIndex: 10, // Lava palette
                    distortion: DistortionEffect(
                        type: .horizontalInterlaced,
                        amplitude: 10,
                        amplitudeAcceleration: 0.01,
                        frequency: 0.03,
                        frequencyAcceleration: 0,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: -0.5
                    ),
                    scrollSpeed: CGPoint(x: -0.1, y: 0.05)
                )
            ),
            
            EarthboundBackground(
                name: "Kraken",
                layer1: BackgroundLayer(
                    patternIndex: 61, // Circle pattern
                    paletteIndex: 7, // Ocean palette
                    distortion: DistortionEffect(
                        type: .vertical,
                        amplitude: 18,
                        amplitudeAcceleration: 0,
                        frequency: 0.015,
                        frequencyAcceleration: 0,
                        compression: 0.1,
                        compressionAcceleration: 0,
                        speed: 0.3
                    ),
                    scrollSpeed: CGPoint(x: 0, y: 0.15)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 85, // Wave pattern
                    paletteIndex: 1, // Ice palette
                    distortion: DistortionEffect(
                        type: .horizontal,
                        amplitude: 8,
                        amplitudeAcceleration: 0,
                        frequency: 0.04,
                        frequencyAcceleration: 0,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 0.8
                    ),
                    scrollSpeed: CGPoint(x: 0.06, y: -0.03)
                )
            ),
            
            EarthboundBackground(
                name: "New Age Retro Hippie",
                layer1: BackgroundLayer(
                    patternIndex: 145, // Spiral pattern
                    paletteIndex: 2, // Psychedelic palette
                    distortion: DistortionEffect(
                        type: .horizontalInterlaced,
                        amplitude: 26,
                        amplitudeAcceleration: 0.02,
                        frequency: 0.025,
                        frequencyAcceleration: 0.001,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 1.0
                    ),
                    scrollSpeed: CGPoint(x: 0.3, y: 0.15)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 305, // Organic pattern
                    paletteIndex: 14, // Rainbow palette
                    distortion: DistortionEffect(
                        type: .horizontal,
                        amplitude: 14,
                        amplitudeAcceleration: -0.01,
                        frequency: 0.035,
                        frequencyAcceleration: 0,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: -0.7
                    ),
                    scrollSpeed: CGPoint(x: -0.2, y: -0.1)
                )
            ),
            
            EarthboundBackground(
                name: "Carbon Dog",
                layer1: BackgroundLayer(
                    patternIndex: 122, // Diamond pattern
                    paletteIndex: 5, // Monochrome palette
                    distortion: DistortionEffect(
                        type: .vertical,
                        amplitude: 10,
                        amplitudeAcceleration: 0,
                        frequency: 0.02,
                        frequencyAcceleration: 0,
                        compression: 0.15,
                        compressionAcceleration: 0.001,
                        speed: 1.5
                    ),
                    scrollSpeed: CGPoint(x: 0.3, y: 0.3)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 182, // Cross pattern
                    paletteIndex: 11, // Cosmic palette
                    distortion: DistortionEffect(
                        type: .horizontal,
                        amplitude: 8,
                        amplitudeAcceleration: 0,
                        frequency: 0.045,
                        frequencyAcceleration: 0,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 0.7
                    ),
                    scrollSpeed: CGPoint(x: -0.06, y: 0.12)
                )
            ),
            
            EarthboundBackground(
                name: "Abstract Art",
                layer1: BackgroundLayer(
                    patternIndex: 285, // Fractal pattern
                    paletteIndex: 4, // Neon palette
                    distortion: DistortionEffect(
                        type: .horizontalInterlaced,
                        amplitude: 8,
                        amplitudeAcceleration: 0.03,
                        frequency: 0.018,
                        frequencyAcceleration: 0.002,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 0.8
                    ),
                    scrollSpeed: CGPoint(x: 0.6, y: -0.2)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 262, // Mosaic pattern
                    paletteIndex: 9, // Royal palette
                    distortion: DistortionEffect(
                        type: .vertical,
                        amplitude: 12,
                        amplitudeAcceleration: -0.02,
                        frequency: 0.03,
                        frequencyAcceleration: 0,
                        compression: 0.2,
                        compressionAcceleration: -0.001,
                        speed: -0.6
                    ),
                    scrollSpeed: CGPoint(x: -0.4, y: 0.6)
                )
            ),
            
            EarthboundBackground(
                name: "Sanctuary Guardian",
                layer1: BackgroundLayer(
                    patternIndex: 225, // Star pattern
                    paletteIndex: 11, // Cosmic palette
                    distortion: DistortionEffect(
                        type: .horizontal,
                        amplitude: 16,
                        amplitudeAcceleration: 0,
                        frequency: 0.022,
                        frequencyAcceleration: 0,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 1.2
                    ),
                    scrollSpeed: CGPoint(x: 0.1, y: 0.1)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 65, // Circle pattern
                    paletteIndex: 6, // Sunset palette
                    distortion: DistortionEffect(
                        type: .horizontalInterlaced,
                        amplitude: 22,
                        amplitudeAcceleration: 0.01,
                        frequency: 0.028,
                        frequencyAcceleration: 0.001,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: -0.7
                    ),
                    scrollSpeed: CGPoint(x: -0.5, y: 0.3)
                )
            ),
            
            EarthboundBackground(
                name: "Belch",
                layer1: BackgroundLayer(
                    patternIndex: 165, // Noise pattern
                    paletteIndex: 12, // Toxic palette
                    distortion: DistortionEffect(
                        type: .vertical,
                        amplitude: 14,
                        amplitudeAcceleration: 0.02,
                        frequency: 0.016,
                        frequencyAcceleration: 0,
                        compression: 0.25,
                        compressionAcceleration: 0.002,
                        speed: 0.8
                    ),
                    scrollSpeed: CGPoint(x: 0.2, y: 0.7)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 102, // Grid pattern
                    paletteIndex: 3, // Earth palette
                    distortion: DistortionEffect(
                        type: .horizontal,
                        amplitude: 10,
                        amplitudeAcceleration: -0.01,
                        frequency: 0.038,
                        frequencyAcceleration: 0,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 0.5
                    ),
                    scrollSpeed: CGPoint(x: -0.1, y: -0.12)
                )
            ),
            
            EarthboundBackground(
                name: "Electro Specter",
                layer1: BackgroundLayer(
                    patternIndex: 42, // Diagonal pattern
                    paletteIndex: 4, // Neon palette
                    distortion: DistortionEffect(
                        type: .horizontalInterlaced,
                        amplitude: 18,
                        amplitudeAcceleration: 0,
                        frequency: 0.032,
                        frequencyAcceleration: 0.002,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 1.1
                    ),
                    scrollSpeed: CGPoint(x: 0.24, y: 0)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 245, // Gradient pattern
                    paletteIndex: 1, // Ice palette
                    distortion: DistortionEffect(
                        type: .horizontal,
                        amplitude: 12,
                        amplitudeAcceleration: 0.01,
                        frequency: 0.026,
                        frequencyAcceleration: 0,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: -0.9
                    ),
                    scrollSpeed: CGPoint(x: -0.18, y: 0.06)
                )
            ),
            
            EarthboundBackground(
                name: "Starman",
                layer1: BackgroundLayer(
                    patternIndex: 222, // Star pattern
                    paletteIndex: 11, // Cosmic palette
                    distortion: DistortionEffect(
                        type: .vertical,
                        amplitude: 16,
                        amplitudeAcceleration: 0,
                        frequency: 0.024,
                        frequencyAcceleration: 0,
                        compression: 0.18,
                        compressionAcceleration: 0,
                        speed: 0.6
                    ),
                    scrollSpeed: CGPoint(x: 0.4, y: 0.4)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 205, // Hexagon pattern
                    paletteIndex: 9, // Royal palette
                    distortion: DistortionEffect(
                        type: .horizontalInterlaced,
                        amplitude: 20,
                        amplitudeAcceleration: 0.02,
                        frequency: 0.02,
                        frequencyAcceleration: 0.001,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: -0.8
                    ),
                    scrollSpeed: CGPoint(x: -0.5, y: -0.3)
                )
            ),
            
            EarthboundBackground(
                name: "Plague Rat",
                layer1: BackgroundLayer(
                    patternIndex: 185, // Cross pattern
                    paletteIndex: 3, // Earth palette
                    distortion: DistortionEffect(
                        type: .horizontal,
                        amplitude: 12,
                        amplitudeAcceleration: 0,
                        frequency: 0.036,
                        frequencyAcceleration: 0,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 0.7
                    ),
                    scrollSpeed: CGPoint(x: 0.3, y: 0.1)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 168, // Noise pattern
                    paletteIndex: 5, // Monochrome palette
                    distortion: DistortionEffect(
                        type: .vertical,
                        amplitude: 8,
                        amplitudeAcceleration: -0.01,
                        frequency: 0.042,
                        frequencyAcceleration: 0,
                        compression: 0.12,
                        compressionAcceleration: 0.001,
                        speed: -0.5
                    ),
                    scrollSpeed: CGPoint(x: -0.2, y: 0.5)
                )
            ),
            
            EarthboundBackground(
                name: "Mondo Mole",
                layer1: BackgroundLayer(
                    patternIndex: 125, // Diamond pattern
                    paletteIndex: 3, // Earth palette
                    distortion: DistortionEffect(
                        type: .horizontalInterlaced,
                        amplitude: 18,
                        amplitudeAcceleration: 0.01,
                        frequency: 0.019,
                        frequencyAcceleration: 0,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 0.5
                    ),
                    scrollSpeed: CGPoint(x: 0.15, y: 0.1)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 265, // Mosaic pattern
                    paletteIndex: 10, // Lava palette
                    distortion: DistortionEffect(
                        type: .horizontal,
                        amplitude: 14,
                        amplitudeAcceleration: 0,
                        frequency: 0.029,
                        frequencyAcceleration: 0.001,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: -0.7
                    ),
                    scrollSpeed: CGPoint(x: -0.4, y: -0.2)
                )
            ),
            
            EarthboundBackground(
                name: "Trillionage Sprout",
                layer1: BackgroundLayer(
                    patternIndex: 308, // Organic pattern
                    paletteIndex: 8, // Forest palette
                    distortion: DistortionEffect(
                        type: .vertical,
                        amplitude: 14,
                        amplitudeAcceleration: 0.02,
                        frequency: 0.021,
                        frequencyAcceleration: 0,
                        compression: 0.22,
                        compressionAcceleration: 0,
                        speed: 1.0
                    ),
                    scrollSpeed: CGPoint(x: 0.2, y: 0.6)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 88, // Wave pattern
                    paletteIndex: 12, // Toxic palette
                    distortion: DistortionEffect(
                        type: .horizontal,
                        amplitude: 10,
                        amplitudeAcceleration: -0.01,
                        frequency: 0.034,
                        frequencyAcceleration: 0,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 0.8
                    ),
                    scrollSpeed: CGPoint(x: -0.3, y: -0.4)
                )
            ),
            
            EarthboundBackground(
                name: "Diamond Dog",
                layer1: BackgroundLayer(
                    patternIndex: 128, // Diamond pattern
                    paletteIndex: 13, // Candy palette
                    distortion: DistortionEffect(
                        type: .horizontalInterlaced,
                        amplitude: 8,
                        amplitudeAcceleration: 0.03,
                        frequency: 0.023,
                        frequencyAcceleration: 0.002,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 0.9
                    ),
                    scrollSpeed: CGPoint(x: 0.21, y: 0.03)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 324, // Radial gradient
                    paletteIndex: 6, // Sunset palette
                    distortion: DistortionEffect(
                        type: .vertical,
                        amplitude: 16,
                        amplitudeAcceleration: 0,
                        frequency: 0.027,
                        frequencyAcceleration: 0,
                        compression: 0.16,
                        compressionAcceleration: -0.001,
                        speed: -0.6
                    ),
                    scrollSpeed: CGPoint(x: -0.5, y: 0.4)
                )
            ),
            
            EarthboundBackground(
                name: "Giygas Final",
                layer1: BackgroundLayer(
                    patternIndex: 290, // Fractal pattern
                    paletteIndex: 0, // Fire palette
                    distortion: DistortionEffect(
                        type: .horizontal,
                        amplitude: 10,
                        amplitudeAcceleration: 0.04,
                        frequency: 0.015,
                        frequencyAcceleration: 0.003,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: 1.2
                    ),
                    scrollSpeed: CGPoint(x: 1.0, y: 0.5)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 148, // Spiral pattern
                    paletteIndex: 10, // Lava palette
                    distortion: DistortionEffect(
                        type: .horizontalInterlaced,
                        amplitude: 26,
                        amplitudeAcceleration: -0.03,
                        frequency: 0.025,
                        frequencyAcceleration: -0.002,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: -1.0
                    ),
                    scrollSpeed: CGPoint(x: -0.24, y: -0.18)
                )
            ),
            
            EarthboundBackground(
                name: "Thunder and Storm",
                layer1: BackgroundLayer(
                    patternIndex: 45, // Diagonal pattern
                    paletteIndex: 1, // Ice palette
                    distortion: DistortionEffect(
                        type: .vertical,
                        amplitude: 18,
                        amplitudeAcceleration: 0,
                        frequency: 0.018,
                        frequencyAcceleration: 0,
                        compression: 0.3,
                        compressionAcceleration: 0.003,
                        speed: 0.7
                    ),
                    scrollSpeed: CGPoint(x: 0.18, y: 0.06)
                ),
                layer2: BackgroundLayer(
                    patternIndex: 242, // Gradient pattern
                    paletteIndex: 11, // Cosmic palette
                    distortion: DistortionEffect(
                        type: .horizontal,
                        amplitude: 14,
                        amplitudeAcceleration: 0.02,
                        frequency: 0.031,
                        frequencyAcceleration: 0.001,
                        compression: 0,
                        compressionAcceleration: 0,
                        speed: -0.8
                    ),
                    scrollSpeed: CGPoint(x: -0.21, y: 0.09)
                )
            )
        ]
    }
}