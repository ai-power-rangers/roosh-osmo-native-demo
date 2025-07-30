import SpriteKit
import SwiftUI

// SpriteKit scene for emoji facial expression animation
// Responds to ARKit blend shape data to create realistic emoji expressions
class EmojiScene: SKScene {
    
    // Emoji sprite nodes for different facial features
    private var faceNode: SKSpriteNode!
    private var leftEyeNode: SKSpriteNode!
    private var rightEyeNode: SKSpriteNode!
    
    // Enhanced mouth system with multiple components
    private var mouthContainer: SKNode! // Container for all mouth elements
    private var neutralMouthNode: SKSpriteNode! // Base neutral mouth
    private var smileMouthNode: SKShapeNode! // Curved smile shape
    private var frownMouthNode: SKShapeNode! // Curved frown shape  
    private var openMouthNode: SKShapeNode! // Open mouth (oval)
    private var puckerMouthNode: SKShapeNode! // Pucker/kiss mouth
    
    private var eyebrowNode: SKSpriteNode!
    
    // Animation properties
    private var originalFaceScale: CGFloat = 1.0
    
    // Emoji expression states for smooth transitions
    private var currentSmileLevel: Float = 0.0
    private var currentFrownLevel: Float = 0.0
    private var currentBlinkLevel: Float = 0.0
    private var currentEyebrowLevel: Float = 0.0
    private var currentMouthOpenness: Float = 0.0
    private var currentPuckerLevel: Float = 0.0
    
    override func didMove(to view: SKView) {
        setupEmoji()
        print("🎮 EmojiScene initialized and ready for facial expressions")
    }
    
    // MARK: - Setup Methods
    private func setupEmoji() {
        // Set background to clear for transparency
        backgroundColor = .clear
        
        // Create main face (yellow circle)
        createFaceBase()
        
        // Create facial features
        createEyes()
        createMouth()
        createEyebrows()
        
        print("😊 Emoji components created and positioned")
    }
    
    private func createFaceBase() {
        // Create yellow circular face
        faceNode = SKSpriteNode(color: .systemYellow, size: CGSize(width: 200, height: 200))
        faceNode.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Make it circular with corner radius effect
        let circleTexture = createCircleTexture(color: .systemYellow, size: CGSize(width: 200, height: 200))
        faceNode.texture = circleTexture
        
        addChild(faceNode)
        originalFaceScale = faceNode.xScale
    }
    
    private func createEyes() {
        let eyeSize = CGSize(width: 20, height: 20)
        
        // Left eye
        leftEyeNode = SKSpriteNode(color: .black, size: eyeSize)
        leftEyeNode.position = CGPoint(x: -30, y: 20)
        faceNode.addChild(leftEyeNode)
        
        // Right eye  
        rightEyeNode = SKSpriteNode(color: .black, size: eyeSize)
        rightEyeNode.position = CGPoint(x: 30, y: 20)
        faceNode.addChild(rightEyeNode)
    }
    
    private func createMouth() {
        // Create container for all mouth elements
        mouthContainer = SKNode()
        mouthContainer.position = CGPoint(x: 0, y: -30)
        
        // Create neutral mouth (horizontal line)
        neutralMouthNode = SKSpriteNode(color: .black, size: CGSize(width: 40, height: 6))
        mouthContainer.addChild(neutralMouthNode)
        
        // Create smile mouth (curved upward arc)
        let smilePath = createCurvedMouthPath(width: 50, height: 15, curveDirection: .up)
        smileMouthNode = SKShapeNode(path: smilePath)
        smileMouthNode.fillColor = .black
        smileMouthNode.strokeColor = .clear
        smileMouthNode.alpha = 0.0 // Initially hidden
        mouthContainer.addChild(smileMouthNode)
        
        // Create frown mouth (curved downward arc)
        let frownPath = createCurvedMouthPath(width: 40, height: 12, curveDirection: .down)
        frownMouthNode = SKShapeNode(path: frownPath)
        frownMouthNode.fillColor = .black
        frownMouthNode.strokeColor = .clear
        frownMouthNode.alpha = 0.0 // Initially hidden
        mouthContainer.addChild(frownMouthNode)
        
        // Create open mouth (oval shape)
        openMouthNode = SKShapeNode(ellipseIn: CGRect(x: -15, y: -20, width: 30, height: 40))
        openMouthNode.fillColor = .black
        openMouthNode.strokeColor = .clear
        openMouthNode.alpha = 0.0 // Initially hidden
        mouthContainer.addChild(openMouthNode)
        
        // Create pucker mouth (small circle)
        puckerMouthNode = SKShapeNode(ellipseIn: CGRect(x: -8, y: -8, width: 16, height: 16))
        puckerMouthNode.fillColor = .black
        puckerMouthNode.strokeColor = .clear
        puckerMouthNode.alpha = 0.0 // Initially hidden
        mouthContainer.addChild(puckerMouthNode)
        
        faceNode.addChild(mouthContainer)
        print("👄 Enhanced mouth system created with multiple expression shapes")
    }
    
    // Helper function to create curved mouth paths
    private func createCurvedMouthPath(width: CGFloat, height: CGFloat, curveDirection: CurveDirection) -> CGPath {
        let path = CGMutablePath()
        let startX = -width / 2
        let endX = width / 2
        let curveY = curveDirection == .up ? height : -height
        
        // Create curved smile/frown using quadratic curve
        path.move(to: CGPoint(x: startX, y: 0))
        path.addQuadCurve(to: CGPoint(x: endX, y: 0), 
                         control: CGPoint(x: 0, y: curveY))
        path.addLine(to: CGPoint(x: endX, y: -3))
        path.addQuadCurve(to: CGPoint(x: startX, y: -3), 
                         control: CGPoint(x: 0, y: curveY - 3))
        path.closeSubpath()
        
        return path
    }
    
    private enum CurveDirection {
        case up, down
    }
    
    private func createEyebrows() {
        // Create eyebrows container
        eyebrowNode = SKSpriteNode(color: .clear, size: CGSize(width: 80, height: 20))
        eyebrowNode.position = CGPoint(x: 0, y: 50)
        
        // Left eyebrow
        let leftBrow = SKSpriteNode(color: .darkGray, size: CGSize(width: 25, height: 4))
        leftBrow.position = CGPoint(x: -20, y: 0)
        eyebrowNode.addChild(leftBrow)
        
        // Right eyebrow
        let rightBrow = SKSpriteNode(color: .darkGray, size: CGSize(width: 25, height: 4))
        rightBrow.position = CGPoint(x: 20, y: 0)
        eyebrowNode.addChild(rightBrow)
        
        faceNode.addChild(eyebrowNode)
    }
    
    // MARK: - Expression Update Methods
    func updateExpression(smile: Float, blink: Float, eyebrow: Float, mouthOpen: Float) {
        // Enhanced expression update with additional mouth parameters
        updateMouthExpression(smile: smile, frown: 0.0, mouthOpen: mouthOpen, pucker: 0.0)
        updateBlink(intensity: blink)
        updateEyebrows(position: eyebrow)
        
        // Store current levels for smooth transitions
        currentSmileLevel = smile
        currentFrownLevel = 0.0
        currentBlinkLevel = blink
        currentEyebrowLevel = eyebrow
        currentMouthOpenness = mouthOpen
        currentPuckerLevel = 0.0
    }
    
    // Enhanced expression update method with full mouth expression support
    func updateEnhancedExpression(smile: Float, frown: Float, blink: Float, eyebrow: Float, mouthOpen: Float, pucker: Float) {
        // Update all facial features with enhanced mouth expressions
        updateMouthExpression(smile: smile, frown: frown, mouthOpen: mouthOpen, pucker: pucker)
        updateBlink(intensity: blink)
        updateEyebrows(position: eyebrow)
        
        // Store current levels for smooth transitions
        currentSmileLevel = smile
        currentFrownLevel = frown
        currentBlinkLevel = blink
        currentEyebrowLevel = eyebrow
        currentMouthOpenness = mouthOpen
        currentPuckerLevel = pucker
        
        print("👄 Updated enhanced expression - Smile: \(String(format: "%.2f", smile)), Frown: \(String(format: "%.2f", frown)), Pucker: \(String(format: "%.2f", pucker)), Open: \(String(format: "%.2f", mouthOpen))")
    }
    
    // Enhanced mouth expression update with multiple mouth states
    private func updateMouthExpression(smile: Float, frown: Float, mouthOpen: Float, pucker: Float) {
        // Reset mouth container position for clean animations
        mouthContainer.position = CGPoint(x: 0, y: -30)
        mouthContainer.setScale(1.0)
        
        // Determine dominant mouth expression with better logic
        let expressions = [
            ("smile", smile),
            ("frown", frown), 
            ("open", mouthOpen),
            ("pucker", pucker)
        ]
        
        // Find the strongest expression above threshold
        let dominantExpression = expressions.filter { $0.1 > 0.1 }.max { $0.1 < $1.1 }
        
        // Hide all mouth shapes first
        neutralMouthNode.alpha = 0.0
        smileMouthNode.alpha = 0.0
        frownMouthNode.alpha = 0.0
        openMouthNode.alpha = 0.0
        puckerMouthNode.alpha = 0.0
        
        // Reset individual mouth node scales and positions
        [smileMouthNode, frownMouthNode, openMouthNode, puckerMouthNode].forEach { node in
            node?.setScale(1.0)
            node?.position = CGPoint.zero
        }
        
        // Show and animate the dominant expression or neutral
        if let dominant = dominantExpression {
            let intensity = dominant.1
            
            switch dominant.0 {
            case "smile":
                animateSmileExpression(intensity: intensity)
            case "frown":
                animateFrownExpression(intensity: intensity)
            case "open":
                animateOpenMouthExpression(intensity: intensity)
            case "pucker":
                animatePuckerExpression(intensity: intensity)
            default:
                showNeutralMouth()
            }
            
            // Scale face slightly for natural expression changes
            let faceScale = originalFaceScale + CGFloat(intensity) * 0.03
            let faceAction = SKAction.scale(to: faceScale, duration: 0.1)
            faceNode.run(faceAction)
        } else {
            showNeutralMouth()
            // Reset face scale to original
            let faceAction = SKAction.scale(to: originalFaceScale, duration: 0.1)
            faceNode.run(faceAction)
        }
    }
    
    private func showNeutralMouth() {
        neutralMouthNode.alpha = 1.0
    }
    
    private func animateSmileExpression(intensity: Float) {
        smileMouthNode.alpha = CGFloat(intensity)
        
        // Scale smile mouth based on intensity
        let smileScale = 1.0 + CGFloat(intensity) * 0.3
        let scaleAction = SKAction.scale(to: smileScale, duration: 0.1)
        smileMouthNode.run(scaleAction)
        
        // Move mouth container up slightly when smiling
        let moveY = CGFloat(intensity) * 5.0
        let moveAction = SKAction.moveBy(x: 0, y: moveY, duration: 0.1)
        mouthContainer.run(moveAction)
    }
    
    private func animateFrownExpression(intensity: Float) {
        frownMouthNode.alpha = CGFloat(intensity)
        
        // Scale frown mouth based on intensity  
        let frownScale = 1.0 + CGFloat(intensity) * 0.2
        let scaleAction = SKAction.scale(to: frownScale, duration: 0.1)
        frownMouthNode.run(scaleAction)
        
        // Move mouth container down slightly when frowning
        let moveY = -CGFloat(intensity) * 3.0
        let moveAction = SKAction.moveBy(x: 0, y: moveY, duration: 0.1)
        mouthContainer.run(moveAction)
    }
    
    private func animateOpenMouthExpression(intensity: Float) {
        openMouthNode.alpha = CGFloat(intensity)
        
        // Scale open mouth vertically based on intensity
        let openScale = 1.0 + CGFloat(intensity) * 1.5
        let scaleAction = SKAction.scaleY(to: openScale, duration: 0.1)
        openMouthNode.run(scaleAction)
    }
    
    private func animatePuckerExpression(intensity: Float) {
        puckerMouthNode.alpha = CGFloat(intensity)
        
        // Scale pucker mouth uniformly
        let puckerScale = 1.0 + CGFloat(intensity) * 0.5
        let scaleAction = SKAction.scale(to: puckerScale, duration: 0.1)
        puckerMouthNode.run(scaleAction)
        
        // Move mouth forward slightly (simulate pucker projection)
        let moveY = CGFloat(intensity) * 2.0
        let moveAction = SKAction.moveBy(x: 0, y: moveY, duration: 0.1)
        mouthContainer.run(moveAction)
    }
    
    // Legacy methods updated to work with new system
    private func updateSmile(intensity: Float) {
        // This method is now handled by updateMouthExpression
        updateMouthExpression(smile: intensity, frown: currentFrownLevel, 
                            mouthOpen: currentMouthOpenness, pucker: currentPuckerLevel)
    }
    
    private func updateBlink(intensity: Float) {
        // Scale eyes vertically to simulate blinking
        let eyeScale = 1.0 - CGFloat(intensity) * 0.9 // Almost close eyes when blinking
        
        let blinkAction = SKAction.scaleY(to: eyeScale, duration: 0.05)
        leftEyeNode.run(blinkAction)
        rightEyeNode.run(blinkAction)
    }
    
    private func updateEyebrows(position: Float) {
        // Move eyebrows up/down based on facial expression
        let browOffset = CGFloat(position) * 10.0 // Range: -10 to +10 pixels
        let browAction = SKAction.moveBy(x: 0, y: browOffset, duration: 0.1)
        
        eyebrowNode.run(browAction)
        
        // Slightly rotate eyebrows for more expression
        let browRotation = CGFloat(position) * 0.1
        let rotateAction = SKAction.rotate(toAngle: browRotation, duration: 0.1)
        eyebrowNode.run(rotateAction)
    }
    
    private func updateMouthOpenness(level: Float) {
        // This method is now handled by updateMouthExpression  
        updateMouthExpression(smile: currentSmileLevel, frown: currentFrownLevel,
                            mouthOpen: level, pucker: currentPuckerLevel)
    }
    
    // MARK: - Helper Methods
    private func createCircleTexture(color: UIColor, size: CGSize) -> SKTexture {
        // Create circular texture for face
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture()
        }
        
        color.setFill()
        let rect = CGRect(origin: .zero, size: size)
        context.fillEllipse(in: rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image ?? UIImage())
    }
}

// SwiftUI wrapper for SpriteKit scene
struct EmojiSpriteView: UIViewRepresentable {
    @Binding var viewModel: CameraViewModel
    
    func makeUIView(context: Context) -> SKView {
        let skView = SKView()
        
        // Create and present the emoji scene
        let scene = EmojiScene()
        scene.size = CGSize(width: 300, height: 300)
        scene.scaleMode = .aspectFit
        
        skView.presentScene(scene)
        skView.allowsTransparency = true
        skView.backgroundColor = .clear
        
        // Store scene reference for updates
        context.coordinator.scene = scene
        
        print("🎮 SpriteKit view created and configured")
        return skView
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        // Update emoji expression based on enhanced facial data
        context.coordinator.scene?.updateEnhancedExpression(
            smile: viewModel.smileIntensity,
            frown: viewModel.frownIntensity,
            blink: viewModel.isBlinking ? 1.0 : 0.0,
            eyebrow: viewModel.eyebrowPosition,
            mouthOpen: viewModel.mouthOpenness,
            pucker: viewModel.mouthPucker
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var scene: EmojiScene?
    }
} 