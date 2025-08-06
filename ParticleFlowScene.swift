import SpriteKit
import GameplayKit

class ParticleFlowScene: SKScene {
    
    private var particleEmitters: [SKEmitterNode] = []
    private var flowFields: [SKFieldNode] = []
    private var lastUpdateTime: TimeInterval = 0
    private var flowPhase: CGFloat = 0
    
    private let colorPalette: [NSColor] = [
        NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0),
        NSColor(red: 0.8, green: 0.3, blue: 0.9, alpha: 1.0),
        NSColor(red: 0.3, green: 0.9, blue: 0.7, alpha: 1.0),
        NSColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0),
        NSColor(red: 0.9, green: 0.9, blue: 0.3, alpha: 1.0)
    ]
    
    override func didMove(to view: SKView) {
        NSLog("ParticleFlowScene: didMove called, size: \(size)")
        backgroundColor = NSColor.black
        setupParticleSystem()
        setupFlowFields()
        setupAnimations()
        NSLog("ParticleFlowScene: Setup complete, emitters: \(particleEmitters.count), fields: \(flowFields.count)")
    }
    
    private func setupParticleSystem() {
        let numEmitters = 3
        
        for i in 0..<numEmitters {
            if let emitter = createParticleEmitter(index: i) {
                emitter.position = CGPoint(
                    x: size.width * CGFloat(i + 1) / CGFloat(numEmitters + 1),
                    y: size.height / 2
                )
                particleEmitters.append(emitter)
                addChild(emitter)
            }
        }
    }
    
    private func createParticleEmitter(index: Int) -> SKEmitterNode? {
        let emitter = SKEmitterNode()
        
        emitter.particleTexture = createGradientTexture()
        emitter.particleBirthRate = 50
        emitter.particleLifetime = 8.0
        emitter.particleLifetimeRange = 2.0
        
        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 50
        
        emitter.emissionAngle = CGFloat.pi * 2.0 * CGFloat(index) / 3.0
        emitter.emissionAngleRange = CGFloat.pi / 4
        
        emitter.particleAlpha = 0.8
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -0.1
        
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = 0.1
        
        let startColor = colorPalette[index % colorPalette.count]
        let endColor = colorPalette[(index + 1) % colorPalette.count]
        
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColor = startColor
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [startColor, endColor],
            times: [0.0, 1.0]
        )
        
        emitter.particleBlendMode = .add
        
        return emitter
    }
    
    private func createGradientTexture() -> SKTexture {
        let renderer = SKShapeNode(circleOfRadius: 32)
        renderer.fillColor = .white
        renderer.strokeColor = .clear
        
        let texture = SKView().texture(from: renderer)
        return texture ?? SKTexture()
    }
    
    private func setupFlowFields() {
        let turbulenceField = SKFieldNode.turbulenceField(
            withSmoothness: 0.5,
            animationSpeed: 0.5
        )
        turbulenceField.strength = 0.5
        turbulenceField.position = CGPoint(x: size.width / 2, y: size.height / 2)
        turbulenceField.region = SKRegion(size: size)
        addChild(turbulenceField)
        flowFields.append(turbulenceField)
        
        let vortexField = SKFieldNode.vortexField()
        vortexField.strength = 0.2
        vortexField.position = CGPoint(x: size.width / 2, y: size.height / 2)
        vortexField.region = SKRegion(size: CGSize(width: size.width * 0.8, height: size.height * 0.8))
        addChild(vortexField)
        flowFields.append(vortexField)
    }
    
    private func setupAnimations() {
        for (index, emitter) in particleEmitters.enumerated() {
            let radius = min(size.width, size.height) * 0.3
            let duration = 20.0 + Double(index) * 2.0
            
            let path = CGMutablePath()
            path.addArc(
                center: CGPoint(x: size.width / 2, y: size.height / 2),
                radius: radius,
                startAngle: CGFloat(index) * 2.0 * .pi / CGFloat(particleEmitters.count),
                endAngle: CGFloat(index) * 2.0 * .pi / CGFloat(particleEmitters.count) + 2.0 * .pi,
                clockwise: true
            )
            
            let followPath = SKAction.follow(
                path,
                asOffset: false,
                orientToPath: false,
                duration: duration
            )
            
            let forever = SKAction.repeatForever(followPath)
            emitter.run(forever)
        }
        
        for field in flowFields {
            let strengthVariation = SKAction.sequence([
                SKAction.customAction(withDuration: 3.0) { node, elapsedTime in
                    if let fieldNode = node as? SKFieldNode {
                        let t = elapsedTime / 3.0
                        fieldNode.strength = Float(0.2 + 0.3 * sin(t * .pi))
                    }
                },
                SKAction.customAction(withDuration: 3.0) { node, elapsedTime in
                    if let fieldNode = node as? SKFieldNode {
                        let t = elapsedTime / 3.0
                        fieldNode.strength = Float(0.5 - 0.3 * sin(t * .pi))
                    }
                }
            ])
            
            field.run(SKAction.repeatForever(strengthVariation))
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        flowPhase += CGFloat(deltaTime) * 0.5
        
        for (index, emitter) in particleEmitters.enumerated() {
            let wave = sin(flowPhase + CGFloat(index) * .pi / 2.0)
            emitter.particleBirthRate = 30 + 40 * wave
            emitter.particleSpeed = 80 + 40 * wave
        }
        
        if Int(currentTime) % 30 == 0 && Int(currentTime) != Int(currentTime - deltaTime) {
            transitionColors()
        }
    }
    
    private func transitionColors() {
        for emitter in particleEmitters {
            let newStartColor = colorPalette.randomElement() ?? colorPalette[0]
            
            let colorTransition = SKAction.customAction(withDuration: 2.0) { node, elapsedTime in
                if let emitterNode = node as? SKEmitterNode {
                    let t = elapsedTime / 2.0
                    emitterNode.particleColor = self.interpolateColor(
                        from: emitterNode.particleColor,
                        to: newStartColor,
                        progress: t
                    )
                }
            }
            
            emitter.run(colorTransition)
        }
    }
    
    private func interpolateColor(from: NSColor, to: NSColor, progress: CGFloat) -> NSColor {
        let fromComponents = from.cgColor.components ?? [0, 0, 0, 1]
        let toComponents = to.cgColor.components ?? [0, 0, 0, 1]
        
        let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * progress
        let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * progress
        let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * progress
        let a = fromComponents[3] + (toComponents[3] - fromComponents[3]) * progress
        
        return NSColor(red: r, green: g, blue: b, alpha: a)
    }
}