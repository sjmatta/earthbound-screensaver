import SpriteKit

class SimpleTestScene: SKScene {
    
    override func didMove(to view: SKView) {
        NSLog("SimpleTestScene: didMove called, size: \(size)")
        
        // Set background to dark blue so we know scene is rendering
        backgroundColor = NSColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0)
        
        // Add a simple rotating square in the center
        let square = SKShapeNode(rectOf: CGSize(width: 100, height: 100))
        square.fillColor = NSColor.cyan
        square.strokeColor = NSColor.white
        square.lineWidth = 3
        square.position = CGPoint(x: size.width / 2, y: size.height / 2)
        square.name = "testSquare"
        addChild(square)
        
        // Add rotation animation
        let rotate = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 4.0)
        let forever = SKAction.repeatForever(rotate)
        square.run(forever)
        
        // Add a label
        let label = SKLabelNode(text: "Particle Flow Screensaver")
        label.fontSize = 36
        label.fontColor = NSColor.white
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        addChild(label)
        
        NSLog("SimpleTestScene: Added \(children.count) nodes")
    }
}