import ScreenSaver
import Metal
import MetalKit

@objc(EarthboundBattleView)
public class EarthboundBattleView: ScreenSaverView {
    
    private var metalView: EarthboundMetalView?
    private var device: MTLDevice?
    
    public override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 60.0
        
        // Initialize Metal device
        device = MTLCreateSystemDefaultDevice()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 60.0
        
        // Initialize Metal device
        device = MTLCreateSystemDefaultDevice()
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
        
        if metalView == nil {
            let view = EarthboundMetalView(frame: bounds, device: device)
            view.autoresizingMask = [.width, .height]
            self.metalView = view
            addSubview(view)
        }
        
        // Start Metal rendering
        metalView?.isPaused = false
    }
    
    public override func stopAnimation() {
        super.stopAnimation()
        
        // Pause Metal rendering
        metalView?.isPaused = true
    }
    
    public override var frame: NSRect {
        didSet {
            metalView?.frame = bounds
        }
    }
}