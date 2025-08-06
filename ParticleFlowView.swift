import ScreenSaver
import SpriteKit

@objc(ParticleFlowView)
public class ParticleFlowView: ScreenSaverView {
    
    private var skView: SKView?
    private var scene: SKScene?
    
    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 60.0
        NSLog("ParticleFlow: Initialized with frame: \(frame), isPreview: \(isPreview)")
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 60.0
    }
    
    public override var hasConfigureSheet: Bool {
        return true
    }
    
    public override var configureSheet: NSWindow? {
        let controller = ConfigureSheetController()
        return controller.window
    }
    
    public override func startAnimation() {
        super.startAnimation()
        NSLog("ParticleFlow: startAnimation called, bounds: \(bounds)")
        
        if skView == nil {
            NSLog("ParticleFlow: Creating SKView")
            let view = SKView(frame: bounds)
            view.ignoresSiblingOrder = true
            view.showsFPS = true  // Show FPS for debugging
            view.showsNodeCount = true  // Show node count for debugging
            view.preferredFramesPerSecond = 60
            
            self.skView = view
            addSubview(view)
            NSLog("ParticleFlow: SKView added to view hierarchy")
            
            // Use simple test scene first to verify rendering
            let scene = SimpleTestScene(size: bounds.size)
            scene.scaleMode = .resizeFill
            scene.backgroundColor = NSColor.black
            
            self.scene = scene
            view.presentScene(scene)
            NSLog("ParticleFlow: Scene presented, size: \(scene.size)")
        }
    }
    
    public override func stopAnimation() {
        super.stopAnimation()
        
        scene?.removeAllActions()
        scene?.removeAllChildren()
        scene = nil
        
        skView?.presentScene(nil)
        skView?.removeFromSuperview()
        skView = nil
    }
    
    public override var frame: NSRect {
        didSet {
            skView?.frame = bounds
            scene?.size = bounds.size
        }
    }
}