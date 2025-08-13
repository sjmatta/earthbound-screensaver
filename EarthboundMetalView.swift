import MetalKit
import simd
import Cocoa

// Custom pixel text renderer for authentic Earthbound font look
class EarthboundPixelTextView: NSView {
    private var text: String = ""
    private let pixelSize: CGFloat = 4.0 // Chunky pixels for that authentic low-res SNES feel
    
    func setText(_ text: String) {
        self.text = text
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Set pixel-perfect rendering
        context.setShouldAntialias(false)
        context.interpolationQuality = .none
        
        // Earthbound text color (slightly blue-white like CRT)
        context.setFillColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0)
        
        // Center the text horizontally
        let textWidth = CGFloat(text.count) * (8 * pixelSize + pixelSize) - pixelSize
        let x = (bounds.width - textWidth) / 2
        drawPixelText(context: context, text: text, at: CGPoint(x: x, y: bounds.height / 2))
    }
    
    private func drawPixelText(context: CGContext, text: String, at point: CGPoint) {
        let charWidth: CGFloat = 8 * pixelSize
        let charHeight: CGFloat = 8 * pixelSize
        var x = point.x
        let y = point.y - charHeight / 2
        
        for char in text.uppercased() {
            drawPixelCharacter(context: context, character: char, at: CGPoint(x: x, y: y))
            x += charWidth + pixelSize // Add 1 pixel spacing between characters
        }
    }
    
    private func drawPixelCharacter(context: CGContext, character: Character, at point: CGPoint) {
        guard let pattern = getEarthboundCharacterPattern(character) else { return }
        
        for (row, rowPattern) in pattern.enumerated() {
            for (col, pixel) in rowPattern.enumerated() {
                if pixel == 1 {
                    let pixelRect = CGRect(
                        x: point.x + CGFloat(col) * pixelSize,
                        y: point.y + CGFloat(7 - row) * pixelSize, // Flip Y coordinate
                        width: pixelSize,
                        height: pixelSize
                    )
                    context.fill(pixelRect)
                }
            }
        }
    }
    
    private func getEarthboundCharacterPattern(_ char: Character) -> [[Int]]? {
        // Simplified 8x8 pixel patterns inspired by Earthbound's font
        // Each pattern is an 8x8 grid where 1 = filled pixel, 0 = empty
        switch char {
        case "A": return [
            [0,0,1,1,1,1,0,0],
            [0,1,1,0,0,1,1,0],
            [1,1,0,0,0,0,1,1],
            [1,1,0,0,0,0,1,1],
            [1,1,1,1,1,1,1,1],
            [1,1,0,0,0,0,1,1],
            [1,1,0,0,0,0,1,1],
            [0,0,0,0,0,0,0,0]
        ]
        case "B": return [
            [1,1,1,1,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,1,1,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,1,1,1,1,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "C": return [
            [0,1,1,1,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,1,1,0],
            [0,1,1,1,1,1,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "D": return [
            [1,1,1,1,1,0,0,0],
            [1,1,0,0,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,1,1,0,0],
            [1,1,1,1,1,0,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "E": return [
            [1,1,1,1,1,1,1,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,1,1,1,1,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,1,1,1,1,1,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "F": return [
            [1,1,1,1,1,1,1,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,1,1,1,1,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "G": return [
            [0,1,1,1,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,1,1,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [0,1,1,1,1,1,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "H": return [
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,1,1,1,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "I": return [
            [1,1,1,1,1,1,1,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [1,1,1,1,1,1,1,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "J": return [
            [1,1,1,1,1,1,1,0],
            [0,0,0,0,1,1,0,0],
            [0,0,0,0,1,1,0,0],
            [0,0,0,0,1,1,0,0],
            [1,1,0,0,1,1,0,0],
            [1,1,0,0,1,1,0,0],
            [0,1,1,1,1,0,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "K": return [
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,1,1,0,0],
            [1,1,0,1,1,0,0,0],
            [1,1,1,1,0,0,0,0],
            [1,1,0,1,1,0,0,0],
            [1,1,0,0,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "L": return [
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,1,1,1,1,1,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "M": return [
            [1,1,0,0,0,0,1,1],
            [1,1,1,0,0,1,1,1],
            [1,1,0,1,1,0,1,1],
            [1,1,0,1,1,0,1,1],
            [1,1,0,0,0,0,1,1],
            [1,1,0,0,0,0,1,1],
            [1,1,0,0,0,0,1,1],
            [0,0,0,0,0,0,0,0]
        ]
        case "N": return [
            [1,1,0,0,0,1,1,0],
            [1,1,1,0,0,1,1,0],
            [1,1,0,1,0,1,1,0],
            [1,1,0,1,0,1,1,0],
            [1,1,0,0,1,1,1,0],
            [1,1,0,0,1,1,1,0],
            [1,1,0,0,0,1,1,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "O": return [
            [0,1,1,1,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [0,1,1,1,1,1,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "P": return [
            [1,1,1,1,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,1,1,1,1,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [1,1,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "Q": return [
            [0,1,1,1,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,1,0,1,1,0],
            [1,1,0,0,1,1,0,0],
            [0,1,1,1,1,0,1,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "R": return [
            [1,1,1,1,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,1,1,1,1,0,0],
            [1,1,0,1,1,0,0,0],
            [1,1,0,0,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "S": return [
            [0,1,1,1,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,0,0,0],
            [0,1,1,1,1,0,0,0],
            [0,0,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [0,1,1,1,1,1,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "T": return [
            [1,1,1,1,1,1,1,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "U": return [
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [0,1,1,1,1,1,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "V": return [
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [0,1,1,0,1,1,0,0],
            [0,1,1,0,1,1,0,0],
            [0,0,1,1,1,0,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "W": return [
            [1,1,0,0,0,0,1,1],
            [1,1,0,0,0,0,1,1],
            [1,1,0,0,0,0,1,1],
            [1,1,0,1,1,0,1,1],
            [1,1,0,1,1,0,1,1],
            [1,1,1,0,0,1,1,1],
            [1,1,0,0,0,0,1,1],
            [0,0,0,0,0,0,0,0]
        ]
        case "X": return [
            [1,1,0,0,0,1,1,0],
            [0,1,1,0,1,1,0,0],
            [0,0,1,1,1,0,0,0],
            [0,0,1,1,1,0,0,0],
            [0,0,1,1,1,0,0,0],
            [0,1,1,0,1,1,0,0],
            [1,1,0,0,0,1,1,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "Y": return [
            [1,1,0,0,0,1,1,0],
            [1,1,0,0,0,1,1,0],
            [0,1,1,0,1,1,0,0],
            [0,0,1,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case "Z": return [
            [1,1,1,1,1,1,1,0],
            [0,0,0,0,0,1,1,0],
            [0,0,0,0,1,1,0,0],
            [0,0,0,1,1,0,0,0],
            [0,0,1,1,0,0,0,0],
            [0,1,1,0,0,0,0,0],
            [1,1,1,1,1,1,1,0],
            [0,0,0,0,0,0,0,0]
        ]
        case " ": return [
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        case ":": return [
            [0,0,0,0,0,0,0,0],
            [0,0,1,1,1,0,0,0],
            [0,0,1,1,1,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,1,1,1,0,0,0],
            [0,0,1,1,1,0,0,0],
            [0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,0]
        ]
        default: return nil
        }
    }
}

// Earthbound-style dialogue box view with typewriter effect
class EarthboundDialogueBox: NSView {
    private var pixelTextView: EarthboundPixelTextView!
    private var backgroundView: NSView!
    private var borderView: NSView!
    private var typewriterTimer: Timer?
    private var fullText: String = ""
    private var currentCharIndex: Int = 0
    private let typewriterSpeed: TimeInterval = 0.05  // Authentic SNES text speed
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupDialogueBox()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDialogueBox()
    }
    
    private func setupDialogueBox() {
        // Create background (authentic Earthbound battle window blue)
        backgroundView = NSView()
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor(red: 0.078, green: 0.157, blue: 0.314, alpha: 1.0).cgColor // RGB(20, 40, 80) - authentic darker blue
        // NO rounded corners - SNES windows are sharp and rectangular
        
        // NO shadows - SNES era had no shadow effects
        addSubview(backgroundView)
        
        // Create thick authentic SNES-style border (bright white)
        borderView = NSView()
        borderView.wantsLayer = true
        borderView.layer?.borderColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor // Pure white for authentic pixel art look
        borderView.layer?.borderWidth = 4.0 // Thick authentic SNES border
        // NO rounded corners - keep it sharp and rectangular like real SNES
        backgroundView.addSubview(borderView)
        
        // Create custom pixel text renderer for authentic Earthbound font
        pixelTextView = EarthboundPixelTextView()
        borderView.addSubview(pixelTextView)
        
        // Initially hidden
        alphaValue = 0.0
    }
    
    override func layout() {
        super.layout()
        
        let padding: CGFloat = 24 // More generous padding for chunky pixel text
        let borderInset: CGFloat = 12 // Larger inset for thicker authentic border
        
        // Position background to fill the view
        backgroundView.frame = bounds
        
        // Create inner border with authentic SNES spacing
        borderView.frame = NSRect(x: borderInset, y: borderInset, 
                                 width: bounds.width - borderInset * 2, 
                                 height: bounds.height - borderInset * 2)
        
        // Position pixel text view inside border with authentic spacing
        pixelTextView.frame = NSRect(x: padding, y: padding,
                                    width: borderView.bounds.width - padding * 2,
                                    height: borderView.bounds.height - padding * 2)
    }
    
    func show(message: String, duration: TimeInterval = 4.0) {
        // Stop any existing typewriter effect
        typewriterTimer?.invalidate()
        
        // Set up for typewriter effect
        fullText = message
        currentCharIndex = 0
        pixelTextView.setText("")  // Start with empty text
        
        // Show dialogue box immediately (no fade)
        alphaValue = 1.0
        
        // Start typewriter effect
        startTypewriterEffect(duration: duration)
    }
    
    private func startTypewriterEffect(duration: TimeInterval) {
        typewriterTimer = Timer.scheduledTimer(withTimeInterval: typewriterSpeed, repeats: true) { _ in
            if self.currentCharIndex < self.fullText.count {
                let endIndex = self.fullText.index(self.fullText.startIndex, offsetBy: self.currentCharIndex + 1)
                let currentText = String(self.fullText[..<endIndex])
                self.pixelTextView.setText(currentText)
                self.currentCharIndex += 1
            } else {
                // Typewriter complete, stop timer
                self.typewriterTimer?.invalidate()
                
                // Wait then hide immediately (no fade)
                DispatchQueue.main.asyncAfter(deadline: .now() + duration - TimeInterval(self.fullText.count) * self.typewriterSpeed) {
                    self.alphaValue = 0.0  // Immediate hide, no animation
                }
            }
        }
    }
}

class EarthboundMetalView: MTKView {
    private var renderer: EarthboundMetalRenderer?
    private var currentBackground: EarthboundBackground?
    private var nextBackground: EarthboundBackground?
    private var backgroundIndex: Int = 0
    private var startTime: CFTimeInterval = 0
    private var transitionTimer: CFTimeInterval = 0
    private let transitionDuration: CFTimeInterval = 75.0
    private var transitionStartTime: CFTimeInterval = 0
    private var isTransitioning = false
    private let crossfadeDuration: CFTimeInterval = 2.0
    
    // Layer scroll offsets
    private var layer1ScrollOffset = SIMD2<Float>(0, 0)
    private var layer2ScrollOffset = SIMD2<Float>(0, 0)
    
    // Earthbound-style dialogue box for background names
    private var dialogueBox: EarthboundDialogueBox?
    
    // Debug tracking
    private var frameCount = 0
    private var lastFrameTime: CFTimeInterval = 0
    
    override init(frame frameRect: NSRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        setup()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        guard let device = device else {
            return
        }
        
        // Configure MTKView
        colorPixelFormat = .bgra8Unorm
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        preferredFramesPerSecond = 30  // Authentic SNES 30 FPS
        isPaused = false  // Ensure it's not paused
        enableSetNeedsDisplay = false  // Use timer-based drawing
        
        // Create renderer
        renderer = EarthboundMetalRenderer(device: device)
        if renderer == nil {
            return
        }
        
        // Set delegate
        delegate = self
        
        // Initialize with random background
        backgroundIndex = Int.random(in: 0..<EarthboundBackground.getAllBackgrounds().count)
        loadBackground(at: backgroundIndex, immediate: true)
        
        startTime = CACurrentMediaTime()
        lastFrameTime = startTime
        
        // Create dialogue box
        setupDialogueBox()
        
        // Initialize textures for current size
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        if width > 0 && height > 0 {
            renderer?.updateTextures(width: min(width, 2048), height: min(height, 2048))
        }
    }
    
    private func setupDialogueBox() {
        // Create dialogue box positioned at bottom center like Earthbound
        let boxWidth: CGFloat = 800 // Wider for longest names like "New Age Retro Hippie"
        let boxHeight: CGFloat = 140 // Taller for authentic SNES window proportions
        let margin: CGFloat = 40
        
        let boxFrame = NSRect(
            x: (bounds.width - boxWidth) / 2,
            y: margin,
            width: boxWidth,
            height: boxHeight
        )
        
        dialogueBox = EarthboundDialogueBox(frame: boxFrame)
        if let dialogue = dialogueBox {
            addSubview(dialogue)
        }
    }
    
    private func updateDialogueBoxFrame() {
        guard let dialogue = dialogueBox else { return }
        let boxWidth: CGFloat = 800 // Wider for longest names like "New Age Retro Hippie"
        let boxHeight: CGFloat = 140 // Taller for authentic SNES window proportions
        let margin: CGFloat = 40
        
        dialogue.frame = NSRect(
            x: (bounds.width - boxWidth) / 2,
            y: margin,
            width: boxWidth,
            height: boxHeight
        )
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateDialogueBoxFrame()
        
        // Update Metal textures for new size
        let width = Int(newSize.width)
        let height = Int(newSize.height)
        if width > 0 && height > 0 {
            renderer?.updateTextures(width: min(width, 2048), height: min(height, 2048))
        }
    }
    
    private func loadBackground(at index: Int, immediate: Bool = false) {
        let backgrounds = EarthboundBackground.getAllBackgrounds()
        let newBackground = backgrounds[index % backgrounds.count]
        
        if immediate || currentBackground == nil {
            // Immediate load (initial startup or forced)
            currentBackground = newBackground
            nextBackground = nil
            isTransitioning = false
            
            // Show background name
            showBackgroundName(newBackground.name)
        } else {
            // Start smooth transition
            nextBackground = newBackground
            isTransitioning = true
            transitionStartTime = CACurrentMediaTime()
            
            // Show background name
            showBackgroundName(newBackground.name)
        }
    }
    
    private func showBackgroundName(_ name: String) {
        guard let dialogue = dialogueBox else { return }
        
        let defaults = UserDefaults.standard
        let shouldShow = defaults.bool(forKey: "EarthboundShowNames")
        
        if shouldShow {
            // Show with authentic Earthbound battle text style
            dialogue.show(message: name, duration: 4.0)
        }
    }
    
    private func updateScrollOffsets(deltaTime: Float) {
        guard let bg = currentBackground else { return }
        
        // Update layer 1 scroll with authentic 30 FPS timing
        layer1ScrollOffset.x += Float(bg.layer1.scrollSpeed.x) * deltaTime * 30
        layer1ScrollOffset.y += Float(bg.layer1.scrollSpeed.y) * deltaTime * 30
        
        // Update layer 2 scroll with authentic 30 FPS timing
        layer2ScrollOffset.x += Float(bg.layer2.scrollSpeed.x) * deltaTime * 30
        layer2ScrollOffset.y += Float(bg.layer2.scrollSpeed.y) * deltaTime * 30
        
        // Wrap to prevent precision issues and corruption
        if abs(layer1ScrollOffset.x) > 1000 {
            layer1ScrollOffset.x = layer1ScrollOffset.x.truncatingRemainder(dividingBy: 256)
        }
        if abs(layer1ScrollOffset.y) > 1000 {
            layer1ScrollOffset.y = layer1ScrollOffset.y.truncatingRemainder(dividingBy: 256)
        }
        if abs(layer2ScrollOffset.x) > 1000 {
            layer2ScrollOffset.x = layer2ScrollOffset.x.truncatingRemainder(dividingBy: 256)
        }
        if abs(layer2ScrollOffset.y) > 1000 {
            layer2ScrollOffset.y = layer2ScrollOffset.y.truncatingRemainder(dividingBy: 256)
        }
    }
    
    private func checkForTransition(currentTime: CFTimeInterval) {
        let defaults = UserDefaults.standard
        let selectedBg = defaults.integer(forKey: "EarthboundBackgroundIndex")
        let transitionSpeed = defaults.double(forKey: "EarthboundTransitionSpeed")
        let duration = transitionSpeed > 0 ? transitionSpeed : transitionDuration
        
        // If user selected a specific background (index > 0), don't auto-transition
        if selectedBg > 0 {
            let desiredIndex = selectedBg - 1 // Subtract 1 because index 0 is "Random"
            if backgroundIndex != desiredIndex {
                backgroundIndex = desiredIndex
                loadBackground(at: backgroundIndex, immediate: true)
                transitionTimer = currentTime
            }
            return
        }
        
        // Auto-transition for random mode
        if currentTime - transitionTimer >= duration {
            transitionTimer = currentTime
            backgroundIndex = (backgroundIndex + 1) % EarthboundBackground.getAllBackgrounds().count
            loadBackground(at: backgroundIndex)
        }
    }
    
    private func updateTransition(currentTime: CFTimeInterval) {
        guard isTransitioning, let next = nextBackground else { return }
        
        let elapsed = currentTime - transitionStartTime
        if elapsed >= crossfadeDuration {
            // Transition complete
            currentBackground = next
            nextBackground = nil
            isTransitioning = false
        }
    }
}

// MARK: - MTKViewDelegate
extension EarthboundMetalView: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let width = Int(size.width)
        let height = Int(size.height)
        if width > 0 && height > 0 {
            renderer?.updateTextures(width: min(width, 2048), height: min(height, 2048))
        }
    }
    
    func draw(in view: MTKView) {
        let currentTime = CACurrentMediaTime()
        
        // Read animation speed from user defaults
        let defaults = UserDefaults.standard
        var animSpeed = Float(defaults.double(forKey: "EarthboundAnimationSpeed"))
        if animSpeed == 0 {
            animSpeed = 0.8  // Slower, more meditative authentic SNES speed for 30 FPS
        }
        let frameTime = Float(currentTime - startTime) * animSpeed
        
        // Update scroll offsets with authentic 30 FPS timing
        updateScrollOffsets(deltaTime: 1.0/30.0)
        
        // Check for background transitions
        checkForTransition(currentTime: currentTime)
        
        // Update ongoing transitions
        updateTransition(currentTime: currentTime)
        
        // Render frame
        guard let renderer = renderer,
              let current = currentBackground,
              let drawable = currentDrawable else {
            return
        }
        
        if isTransitioning, let next = nextBackground {
            // Calculate crossfade alpha
            let elapsed = currentTime - transitionStartTime
            let alpha = Float(min(elapsed / crossfadeDuration, 1.0))
            
            renderer.renderTransition(currentBackground: current,
                                    nextBackground: next,
                                    alpha: alpha,
                                    time: frameTime,
                                    layer1ScrollOffset: layer1ScrollOffset,
                                    layer2ScrollOffset: layer2ScrollOffset,
                                    drawable: drawable)
        } else {
            renderer.render(background: current,
                           time: frameTime,
                           layer1ScrollOffset: layer1ScrollOffset,
                           layer2ScrollOffset: layer2ScrollOffset,
                           drawable: drawable)
        }
    }
}