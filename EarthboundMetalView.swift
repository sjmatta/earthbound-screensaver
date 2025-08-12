import MetalKit
import simd
import Cocoa

// Earthbound-style dialogue box view
class EarthboundDialogueBox: NSView {
    private var messageLabel: NSTextField!
    private var backgroundView: NSView!
    private var borderView: NSView!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupDialogueBox()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDialogueBox()
    }
    
    private func setupDialogueBox() {
        // Create background (dark blue-gray like Earthbound)
        backgroundView = NSView()
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor(red: 0.1, green: 0.15, blue: 0.25, alpha: 0.95).cgColor
        addSubview(backgroundView)
        
        // Create border (white/light gray)
        borderView = NSView()
        borderView.wantsLayer = true
        borderView.layer?.borderColor = NSColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1.0).cgColor
        borderView.layer?.borderWidth = 3.0
        backgroundView.addSubview(borderView)
        
        // Create message label with Earthbound-style font
        messageLabel = NSTextField()
        messageLabel.isEditable = false
        messageLabel.isBordered = false
        messageLabel.backgroundColor = NSColor.clear
        messageLabel.textColor = NSColor.white
        messageLabel.alignment = .center
        messageLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        borderView.addSubview(messageLabel)
        
        // Initially hidden
        alphaValue = 0.0
    }
    
    override func layout() {
        super.layout()
        
        let padding: CGFloat = 20
        let borderInset: CGFloat = 8
        
        // Position background to fill the view
        backgroundView.frame = bounds
        
        // Create inner border with padding
        borderView.frame = NSRect(x: borderInset, y: borderInset, 
                                 width: bounds.width - borderInset * 2, 
                                 height: bounds.height - borderInset * 2)
        
        // Position label inside border with padding
        messageLabel.frame = NSRect(x: padding, y: padding,
                                   width: borderView.bounds.width - padding * 2,
                                   height: borderView.bounds.height - padding * 2)
    }
    
    func show(message: String, duration: TimeInterval = 4.0) {
        messageLabel.stringValue = message
        
        // Animate in with a quick fade
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1.0
        } completionHandler: {
            // Wait then animate out
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.5
                    context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    self.animator().alphaValue = 0.0
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
    private let transitionDuration: CFTimeInterval = 30.0
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
        preferredFramesPerSecond = 60
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
        let boxWidth: CGFloat = 400
        let boxHeight: CGFloat = 80
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
        let boxWidth: CGFloat = 400
        let boxHeight: CGFloat = 80
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
            // Show with Earthbound-style message
            dialogue.show(message: "Now playing: \(name)", duration: 4.0)
        }
    }
    
    private func updateScrollOffsets(deltaTime: Float) {
        guard let bg = currentBackground else { return }
        
        // Update layer 1 scroll
        layer1ScrollOffset.x += Float(bg.layer1.scrollSpeed.x) * deltaTime * 60
        layer1ScrollOffset.y += Float(bg.layer1.scrollSpeed.y) * deltaTime * 60
        
        // Update layer 2 scroll
        layer2ScrollOffset.x += Float(bg.layer2.scrollSpeed.x) * deltaTime * 60
        layer2ScrollOffset.y += Float(bg.layer2.scrollSpeed.y) * deltaTime * 60
        
        // Wrap to prevent precision issues
        if abs(layer1ScrollOffset.x) > 10000 {
            layer1ScrollOffset.x = layer1ScrollOffset.x.truncatingRemainder(dividingBy: 256)
        }
        if abs(layer1ScrollOffset.y) > 10000 {
            layer1ScrollOffset.y = layer1ScrollOffset.y.truncatingRemainder(dividingBy: 256)
        }
        if abs(layer2ScrollOffset.x) > 10000 {
            layer2ScrollOffset.x = layer2ScrollOffset.x.truncatingRemainder(dividingBy: 256)
        }
        if abs(layer2ScrollOffset.y) > 10000 {
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
            animSpeed = 0.5  // Default SNES speed
        }
        let frameTime = Float(currentTime - startTime) * animSpeed
        
        // Update scroll offsets
        updateScrollOffsets(deltaTime: 1.0/60.0)
        
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