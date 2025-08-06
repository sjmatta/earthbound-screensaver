import Cocoa
import SpriteKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Particle Flow Test"
        window.center()
        
        // Create SKView
        let skView = SKView(frame: window.contentRect(forFrameRect: window.frame))
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = true
        
        // Create and present scene
        let scene = ParticleFlowScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = NSColor.black
        
        skView.presentScene(scene)
        
        window.contentView = skView
        window.makeKeyAndOrderFront(nil)
        
        self.window = window
        
        print("Test app launched with scene size: \(scene.size)")
        print("SKView frame: \(skView.frame)")
    }
}