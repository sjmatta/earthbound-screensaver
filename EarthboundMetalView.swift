import MetalKit
import simd

class EarthboundMetalView: MTKView {
    private var renderer: EarthboundMetalRenderer?
    private var background: EarthboundBackground?
    private var backgroundIndex: Int = 0
    private var startTime: CFTimeInterval = 0
    private var transitionTimer: CFTimeInterval = 0
    private let transitionDuration: CFTimeInterval = 30.0
    
    // Layer scroll offsets
    private var layer1ScrollOffset = SIMD2<Float>(0, 0)
    private var layer2ScrollOffset = SIMD2<Float>(0, 0)
    
    // Text label for background names
    private var nameLabel: NSTextField?
    
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
        loadBackground(at: backgroundIndex)
        
        startTime = CACurrentMediaTime()
        lastFrameTime = startTime
        
        // Create name label
        setupNameLabel()
        
        // Initialize textures for current size
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        if width > 0 && height > 0 {
            renderer?.updateTextures(width: min(width, 2048), height: min(height, 2048))
        }
    }
    
    private func setupNameLabel() {
        nameLabel = NSTextField(labelWithString: "")
        guard let label = nameLabel else { return }
        
        label.font = NSFont.boldSystemFont(ofSize: 24)
        label.textColor = NSColor.white
        label.backgroundColor = NSColor.clear
        label.isBordered = false
        label.alignment = .center
        label.alphaValue = 0
        
        addSubview(label)
        updateNameLabelFrame()
    }
    
    private func updateNameLabelFrame() {
        guard let label = nameLabel else { return }
        let labelHeight: CGFloat = 30
        let margin: CGFloat = 20
        label.frame = NSRect(x: margin, y: bounds.height - labelHeight - margin, 
                           width: bounds.width - 2 * margin, height: labelHeight)
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateNameLabelFrame()
        
        // Update Metal textures for new size
        let width = Int(newSize.width)
        let height = Int(newSize.height)
        if width > 0 && height > 0 {
            renderer?.updateTextures(width: min(width, 2048), height: min(height, 2048))
        }
    }
    
    private func loadBackground(at index: Int) {
        let backgrounds = EarthboundBackground.getAllBackgrounds()
        background = backgrounds[index % backgrounds.count]
        
        // Show background name
        if let bg = background {
            showBackgroundName(bg.name)
        }
    }
    
    private func showBackgroundName(_ name: String) {
        guard let label = nameLabel else { return }
        
        let defaults = UserDefaults.standard
        let shouldShow = defaults.bool(forKey: "EarthboundShowNames")
        
        if shouldShow {
            label.stringValue = name
            
            // Animate in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                label.animator().alphaValue = 1.0
            } completionHandler: {
                // Wait then animate out
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 1.0
                        label.animator().alphaValue = 0.0
                    }
                }
            }
        }
    }
    
    private func updateScrollOffsets(deltaTime: Float) {
        guard let bg = background else { return }
        
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
                loadBackground(at: backgroundIndex)
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
        
        // Render frame
        guard let renderer = renderer,
              let background = background,
              let drawable = currentDrawable else {
            return
        }
        
        renderer.render(background: background,
                       time: frameTime,
                       layer1ScrollOffset: layer1ScrollOffset,
                       layer2ScrollOffset: layer2ScrollOffset,
                       drawable: drawable)
    }
}