import SpriteKit
import SwiftUI

class DrawingGameScene: SKScene {
    private var drawings: [SKSpriteNode] = []
    private var selectedNode: SKSpriteNode?
    
    override func didMove(to view: SKView) {
        // Set up physics world
        physicsWorld.gravity = CGVector(dx: 0, dy: -2)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        
        // Add background elements
        addBackground()
    }
    
    private func addBackground() {
        // Create a gradient background
        let topColor = UIColor.systemBlue.cgColor
        let bottomColor = UIColor.systemTeal.cgColor
        
        let gradientNode = SKSpriteNode(texture: gradientTexture(topColor: topColor, bottomColor: bottomColor, size: size))
        gradientNode.position = CGPoint(x: frame.midX, y: frame.midY)
        gradientNode.zPosition = -1
        addChild(gradientNode)
        
        // Add some clouds
        for i in 0..<3 {
            let cloud = createCloud()
            cloud.position = CGPoint(x: CGFloat.random(in: 100...size.width-100),
                                   y: CGFloat.random(in: size.height*0.6...size.height*0.8))
            addChild(cloud)
            
            // Animate clouds moving
            let moveAction = SKAction.moveBy(x: 100, y: 0, duration: 20)
            let reverseAction = moveAction.reversed()
            let sequence = SKAction.sequence([moveAction, reverseAction])
            cloud.run(SKAction.repeatForever(sequence))
        }
    }
    
    private func createCloud() -> SKShapeNode {
        let cloud = SKShapeNode()
        let path = UIBezierPath()
        
        // Draw cloud shape
        path.move(to: CGPoint(x: 0, y: 20))
        path.addCurve(to: CGPoint(x: 30, y: 30),
                      controlPoint1: CGPoint(x: 0, y: 35),
                      controlPoint2: CGPoint(x: 15, y: 35))
        path.addCurve(to: CGPoint(x: 60, y: 20),
                      controlPoint1: CGPoint(x: 45, y: 35),
                      controlPoint2: CGPoint(x: 60, y: 35))
        path.addCurve(to: CGPoint(x: 50, y: 0),
                      controlPoint1: CGPoint(x: 60, y: 10),
                      controlPoint2: CGPoint(x: 55, y: 0))
        path.addCurve(to: CGPoint(x: 10, y: 0),
                      controlPoint1: CGPoint(x: 35, y: -5),
                      controlPoint2: CGPoint(x: 20, y: -5))
        path.addCurve(to: CGPoint(x: 0, y: 20),
                      controlPoint1: CGPoint(x: 5, y: 0),
                      controlPoint2: CGPoint(x: 0, y: 10))
        
        cloud.path = path.cgPath
        cloud.fillColor = .white
        cloud.strokeColor = .clear
        cloud.alpha = 0.8
        cloud.zPosition = -0.5
        
        return cloud
    }
    
    func addDrawing(_ image: UIImage) {
        // Create texture from the processed drawing
        let texture = SKTexture(image: image)
        let sprite = SKSpriteNode(texture: texture)
        
        // Set initial size and position
        let aspectRatio = image.size.width / image.size.height
        let targetWidth: CGFloat = 150
        sprite.size = CGSize(width: targetWidth, height: targetWidth / aspectRatio)
        sprite.position = CGPoint(x: frame.midX, y: frame.height - 100)
        
        // Add physics
        sprite.physicsBody = SKPhysicsBody(texture: texture, size: sprite.size)
        sprite.physicsBody?.isDynamic = true
        sprite.physicsBody?.restitution = 0.4
        sprite.physicsBody?.friction = 0.5
        sprite.physicsBody?.allowsRotation = true
        
        // Add to scene with animation
        sprite.alpha = 0
        sprite.setScale(0.1)
        addChild(sprite)
        drawings.append(sprite)
        
        // Animate entrance
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let scale = SKAction.scale(to: 1.0, duration: 0.5)
        let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 0.5)
        let group = SKAction.group([fadeIn, scale, rotate])
        
        sprite.run(group) { [weak self] in
            // Add particle effect
            self?.addSparkleEffect(at: sprite.position)
            
            // Add a little jump
            sprite.physicsBody?.applyImpulse(CGVector(dx: CGFloat.random(in: -20...20), dy: 100))
        }
    }
    
    private func addSparkleEffect(at position: CGPoint) {
        if let sparkle = SKEmitterNode(fileNamed: "Sparkle") {
            sparkle.position = position
            sparkle.zPosition = 10
            addChild(sparkle)
            
            sparkle.run(SKAction.wait(forDuration: 1.0)) {
                sparkle.removeFromParent()
            }
        } else {
            // Create a simple particle effect if no particle file exists
            let emitter = SKEmitterNode()
            emitter.particleTexture = SKTexture(imageNamed: "spark")
            emitter.particleBirthRate = 100
            emitter.numParticlesToEmit = 20
            emitter.particleLifetime = 0.5
            emitter.particleScale = 0.2
            emitter.particleScaleSpeed = -0.4
            emitter.particleColor = .yellow
            emitter.particleColorBlendFactor = 1.0
            emitter.particleAlpha = 0.8
            emitter.particleAlphaSpeed = -1.6
            emitter.emissionAngleRange = .pi * 2
            emitter.particleSpeed = 100
            emitter.position = position
            emitter.zPosition = 10
            
            addChild(emitter)
            
            emitter.run(SKAction.wait(forDuration: 1.0)) {
                emitter.removeFromParent()
            }
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        // Find if we touched a drawing
        for node in touchedNodes {
            if let sprite = node as? SKSpriteNode, drawings.contains(sprite) {
                selectedNode = sprite
                
                // Visual feedback
                let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
                sprite.run(scaleUp)
                
                // Add glow effect
                sprite.run(SKAction.colorize(with: .yellow, colorBlendFactor: 0.5, duration: 0.1))
                
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let selected = selectedNode else { return }
        let location = touch.location(in: self)
        
        // Move the selected node
        selected.position = location
        selected.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        selected.physicsBody?.angularVelocity = 0
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let selected = selectedNode {
            // Remove visual feedback
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            selected.run(scaleDown)
            
            // Remove glow
            selected.run(SKAction.colorize(with: .white, colorBlendFactor: 0, duration: 0.1))
            
            // Give it a little spin when released
            selected.physicsBody?.applyAngularImpulse(CGFloat.random(in: -0.1...0.1))
            
            selectedNode = nil
        }
    }
    
    // Helper function to create gradient texture
    private func gradientTexture(topColor: CGColor, bottomColor: CGColor, size: CGSize) -> SKTexture {
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        let colors = [topColor, bottomColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                       colors: colors,
                                       locations: locations) else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        context.drawLinearGradient(gradient,
                                  start: CGPoint(x: size.width/2, y: 0),
                                  end: CGPoint(x: size.width/2, y: size.height),
                                  options: [])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image ?? UIImage())
    }
}