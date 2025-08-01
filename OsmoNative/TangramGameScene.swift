import SpriteKit
import Foundation

// MARK: - Game Delegate Protocol
protocol TangramGameDelegate: AnyObject {
    func pieceSnapped()
    func pieceUnsnapped()
}

// MARK: - Tangram Game Scene
class TangramGameScene: SKScene {
    
    // MARK: - Properties
    weak var gameDelegate: TangramGameDelegate?
    var initialTemplate: TangramTemplate?
    
    // Scene areas
    private var templateArea: CGRect = .zero
    private var trayArea: CGRect = .zero
    private var templateCenter: CGPoint = .zero
    
    // Template and pieces
    private var currentTemplate: TangramTemplate?
    private var templateOutlineNode: SKShapeNode?
    private var targetNodes: [SKShapeNode] = []
    private var pieceNodes: [TangramPieceNode] = []
    
    // Visual enhancements
    private var backgroundParticles: SKEmitterNode?
    private var snapParticles: SKEmitterNode?
    
    // Dragging state
    private var draggedPiece: TangramPieceNode?
    private var initialTouchPoint: CGPoint = .zero
    private var pieceInitialPosition: CGPoint = .zero
    
    // Constants
    private let snapThreshold: CGFloat = 40.0 // Slightly increased for better UX
    private let rotationSnapThreshold: CGFloat = 0.2 // ~11 degrees in radians
    private let trayHeight: CGFloat = 150.0
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        setupEnhancedSceneAreas()
        setupParticleEffects()
        setupNotifications()
        
        // Set up initial template now that scene is properly initialized
        if let template = initialTemplate {
            setupTemplate(template)
            setupTangramPieces()
            initialTemplate = nil // Clear after use
        }
        
        print("🎮 Enhanced TangramGameScene initialized")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Enhanced Setup Methods
    
    private func setupEnhancedSceneAreas() {
        // Define template area (middle section of screen)
        let templateHeight = size.height * 0.5
        let templateY = trayHeight + 60
        templateArea = CGRect(
            x: 0,
            y: templateY,
            width: size.width,
            height: templateHeight
        )
        // Center the template in the middle of the screen (vertically)
        templateCenter = CGPoint(x: size.width/2, y: size.height/2)
        
        // Define tray area (bottom)
        trayArea = CGRect(
            x: 0,
            y: 0,
            width: size.width,
            height: trayHeight + 60
        )
        
        // Enhanced visual separator with gradient effect
        let separatorBackground = SKShapeNode(rect: CGRect(x: 0, y: trayHeight + 50, width: size.width, height: 20))
        separatorBackground.fillColor = UIColor.systemBlue.withAlphaComponent(0.05)
        separatorBackground.strokeColor = UIColor.clear
        addChild(separatorBackground)
        
        let separator = SKShapeNode(rect: CGRect(x: 20, y: trayHeight + 58, width: size.width - 40, height: 4))
        separator.fillColor = UIColor.systemBlue.withAlphaComponent(0.3)
        separator.strokeColor = UIColor.clear
        addChild(separator)
        
        // Enhanced template area background with modern styling
        let templateBackground = SKShapeNode(circleOfRadius: 160)
        templateBackground.position = templateCenter
        templateBackground.fillColor = UIColor.systemBlue.withAlphaComponent(0.03)
        templateBackground.strokeColor = UIColor.systemBlue.withAlphaComponent(0.15)
        templateBackground.lineWidth = 3
        templateBackground.zPosition = -10
        
        // Add subtle pulsing animation to template background
        let pulseAction = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 2.0),
            SKAction.scale(to: 1.0, duration: 2.0)
        ])
        templateBackground.run(SKAction.repeatForever(pulseAction))
        addChild(templateBackground)
        
        // Add decorative corner elements
        addDecorativeElements()
        
        print("📏 Enhanced scene areas configured - Template: \(templateArea), Tray: \(trayArea)")
    }
    
    private func addDecorativeElements() {
        // Add subtle corner decorations
        let corners = [
            CGPoint(x: 30, y: size.height - 30),
            CGPoint(x: size.width - 30, y: size.height - 30),
            CGPoint(x: 30, y: trayHeight + 90),
            CGPoint(x: size.width - 30, y: trayHeight + 90)
        ]
        
        for corner in corners {
            let decoration = SKShapeNode(circleOfRadius: 8)
            decoration.position = corner
            decoration.fillColor = UIColor.systemBlue.withAlphaComponent(0.1)
            decoration.strokeColor = UIColor.systemBlue.withAlphaComponent(0.3)
            decoration.lineWidth = 2
            decoration.zPosition = -5
            
            // Add gentle floating animation
            let floatAction = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 5, duration: 1.5),
                SKAction.moveBy(x: 0, y: -5, duration: 1.5)
            ])
            decoration.run(SKAction.repeatForever(floatAction))
            addChild(decoration)
        }
    }
    
    private func setupParticleEffects() {
        // Background ambient particles - subtle floating sparkles
        backgroundParticles = SKEmitterNode()
        if let particles = backgroundParticles {
            particles.particleTexture = SKTexture(imageNamed: "spark") // Will use a simple circle if image not found
            particles.particleBirthRate = 2
            particles.particleLifetime = 8.0
            particles.particleLifetimeRange = 2.0
            particles.particlePosition = CGPoint(x: size.width/2, y: size.height/2)
            particles.particlePositionRange = CGVector(dx: size.width, dy: size.height)
            particles.particleSpeed = 10
            particles.particleSpeedRange = 5
            particles.particleAlpha = 0.1
            particles.particleAlphaRange = 0.05
            particles.particleScale = 0.1
            particles.particleScaleRange = 0.05
            particles.particleColor = UIColor(red: 0.9, green: 0.7, blue: 0.9, alpha: 1.0)
            particles.particleColorBlendFactor = 1.0
            particles.zPosition = -20
            addChild(particles)
        }
        
        // Snap success particles - celebratory burst
        snapParticles = SKEmitterNode()
        if let particles = snapParticles {
            particles.particleTexture = SKTexture(imageNamed: "star") // Will use a simple shape if image not found
            particles.particleBirthRate = 50
            particles.particleLifetime = 1.0
            particles.particleLifetimeRange = 0.5
            particles.particleSpeed = 100
            particles.particleSpeedRange = 50
            particles.particleAlpha = 0.8
            particles.particleAlphaSpeed = -0.8
            particles.particleScale = 0.3
            particles.particleScaleSpeed = -0.3
            particles.particleColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
            particles.particleColorBlendFactor = 1.0
            particles.zPosition = 100
            particles.emissionAngle = 0
            particles.emissionAngleRange = CGFloat.pi * 2
            // Don't add to scene yet - will be positioned and activated on snap
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLevelAdvanced),
            name: .tangramLevelAdvanced,
            object: nil
        )
    }
    
    @objc private func handleLevelAdvanced() {
        // This notification is handled by the SwiftUI view
        // which will call setupTemplate and resetAllPieces
        print("🔄 Level advanced notification received")
    }
    
    // MARK: - Public Methods
    
    func setupTemplate(_ template: TangramTemplate) {
        currentTemplate = template
        createTemplateOutline()
        createEnhancedTargetAreas()
        print("🎯 Template '\(template.name)' loaded with \(template.targetPositions.count) pieces")
    }
    
    func setupTangramPieces() {
        clearExistingPieces()
        
        // Create enhanced piece nodes for each tangram piece
        for (index, piece) in TangramPiece.allPieces.enumerated() {
            let pieceNode = EnhancedTangramPieceNode(piece: piece)
            
            // Position pieces in the tray with better spacing
            let spacing: CGFloat = 85
            let startX: CGFloat = spacing
            let y: CGFloat = trayArea.midY - 10 // Slightly adjust vertical position
            let x = startX + CGFloat(index) * spacing
            
            pieceNode.position = CGPoint(x: x, y: y)
            pieceNode.originalTrayPosition = pieceNode.position
            
            addChild(pieceNode)
            pieceNodes.append(pieceNode)
        }
        
        print("🧩 \(pieceNodes.count) enhanced tangram pieces created and positioned in tray")
    }
    
    func resetAllPieces() {
        // Move all pieces back to tray with enhanced animation
        for (index, pieceNode) in pieceNodes.enumerated() {
            let delay = TimeInterval(index) * 0.1 // Stagger the animations
            let delayAction = SKAction.wait(forDuration: delay)
            let resetAction = SKAction.run { pieceNode.returnToTray() }
            pieceNode.run(SKAction.sequence([delayAction, resetAction]))
        }
        print("🔄 All pieces reset to tray with staggered animation")
    }
    
    // MARK: - Enhanced Template Methods
    
    private func createTemplateOutline() {
        // Remove existing outline
        templateOutlineNode?.removeFromParent()
        templateOutlineNode = nil
        
        // No template outline needed for single piece matching
        print("🎯 Template outline removed - using individual piece targets only")
    }
    
    private func createEnhancedTargetAreas() {
        // Clear existing target nodes
        targetNodes.forEach { $0.removeFromParent() }
        targetNodes.removeAll()
        
        guard let template = currentTemplate else { return }
        
        // Create enhanced target area nodes for each piece position
        for target in template.targetPositions {
            guard let piece = TangramPiece.allPieces.first(where: { $0.type == target.pieceType }) else { continue }
            
            // Create target shape path with proper scaling
            let path = createPiecePath(from: piece.points, scale: piece.size)
            let targetNode = SKShapeNode(path: path)
            
            // Position and rotate target (centered since position is 0,0)
            targetNode.position = templateCenter
            targetNode.zRotation = target.rotation
            
            // Enhanced styling with gradient-like effect using multiple overlays
            targetNode.strokeColor = UIColor.systemBlue
            targetNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.15)
            targetNode.lineWidth = 5
            targetNode.alpha = 0.9
            
            // Add inner glow effect
            let innerGlow = SKShapeNode(path: path)
            innerGlow.position = CGPoint.zero
            innerGlow.strokeColor = UIColor.systemBlue.withAlphaComponent(0.6)
            innerGlow.fillColor = UIColor.clear
            innerGlow.lineWidth = 2
            innerGlow.zPosition = 1
            targetNode.addChild(innerGlow)
            
            // Add enhanced pulsing animation with color changes
            let colorPulse = SKAction.sequence([
                SKAction.run {
                    targetNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.25)
                    innerGlow.strokeColor = UIColor.systemBlue.withAlphaComponent(0.8)
                },
                SKAction.wait(forDuration: 1.2),
                SKAction.run {
                    targetNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.15)
                    innerGlow.strokeColor = UIColor.systemBlue.withAlphaComponent(0.6)
                },
                SKAction.wait(forDuration: 1.2)
            ])
            targetNode.run(SKAction.repeatForever(colorPulse))
            
            // Store target data
            targetNode.userData = NSMutableDictionary()
            targetNode.userData?["pieceType"] = target.pieceType.rawValue
            targetNode.userData?["targetPosition"] = NSValue(cgPoint: target.position)
            targetNode.userData?["targetRotation"] = target.rotation
            
            addChild(targetNode)
            targetNodes.append(targetNode)
            
            print("🎯 Created enhanced target for \(piece.type.rawValue) at center")
        }
        
        print("🎯 Created \(targetNodes.count) enhanced target areas")
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Find the topmost tangram piece at touch location
        let touchedNodes = nodes(at: location)
        for node in touchedNodes {
            if let pieceNode = node as? TangramPieceNode, !pieceNode.isLocked {
                startDragging(pieceNode, at: location)
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let draggedPiece = draggedPiece else { return }
        
        let location = touch.location(in: self)
        
        // Calculate movement delta
        let deltaX = location.x - initialTouchPoint.x
        let deltaY = location.y - initialTouchPoint.y
        
        // Update piece position
        draggedPiece.position = CGPoint(
            x: pieceInitialPosition.x + deltaX,
            y: pieceInitialPosition.y + deltaY
        )
        
        // Check for potential snap targets and highlight them
        highlightNearbyTargets(for: draggedPiece)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let draggedPiece = draggedPiece else { return }
        
        // Try to snap piece to target
        if let targetNode = findSnapTarget(for: draggedPiece) {
            snapPieceToTarget(draggedPiece, target: targetNode)
        } else {
            // No valid snap target - return to tray if not in template area
            if !templateArea.contains(draggedPiece.position) {
                draggedPiece.returnToTray()
            }
        }
        
        // Clear highlighting
        clearTargetHighlights()
        
        // End dragging
        self.draggedPiece = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Handle cancelled touch the same as ended
        touchesEnded(touches, with: event)
    }
    
    // MARK: - Enhanced Dragging Logic
    
    private func startDragging(_ pieceNode: TangramPieceNode, at location: CGPoint) {
        draggedPiece = pieceNode
        initialTouchPoint = location
        pieceInitialPosition = pieceNode.position
        
        // Enhanced drag start feedback
        pieceNode.zPosition = 100
        
        // Add subtle scale and shadow effect when picking up
        let pickupAction = SKAction.group([
            SKAction.scale(to: 1.1, duration: 0.2),
            SKAction.run {
                if let enhancedPiece = pieceNode as? EnhancedTangramPieceNode {
                    enhancedPiece.setDragging(true)
                }
            }
        ])
        pieceNode.run(pickupAction)
        
        // If piece was previously snapped, unsnap it
        if pieceNode.isSnapped {
            pieceNode.unsnap()
            gameDelegate?.pieceUnsnapped()
        }
        
        print("👆 Started dragging \(pieceNode.piece.type.rawValue) with enhanced feedback")
    }
    
    private func findSnapTarget(for pieceNode: TangramPieceNode) -> SKShapeNode? {
        guard let template = currentTemplate else { return nil }
        
        for targetNode in targetNodes {
            guard let pieceTypeString = targetNode.userData?["pieceType"] as? String,
                  let targetPieceType = TangramPieceType(rawValue: pieceTypeString),
                  targetPieceType == pieceNode.piece.type else {
                continue
            }
            
            // Check if target is already occupied
            if isTargetOccupied(targetNode) {
                continue
            }
            
            // Check distance threshold
            let distance = distanceBetween(pieceNode.position, targetNode.position)
            if distance > snapThreshold {
                continue
            }
            
            // Since all pieces are now at 0 rotation, no rotation check needed
            // Pieces should already be in correct orientation from tray
            
            return targetNode
        }
        
        return nil
    }
    
    private func snapPieceToTarget(_ pieceNode: TangramPieceNode, target: SKShapeNode) {
        guard let targetRotation = target.userData?["targetRotation"] as? CGFloat else { return }
        
        // Enhanced snap animation
        let snapAction = SKAction.group([
            SKAction.move(to: target.position, duration: 0.3),
            SKAction.rotate(toAngle: targetRotation, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        snapAction.timingMode = .easeOut
        
        // Snap piece to exact target position and rotation
        pieceNode.run(snapAction) { [weak self] in
            pieceNode.zPosition = 1
            pieceNode.snap()
            
            // Enhanced visual feedback
            if let enhancedPiece = pieceNode as? EnhancedTangramPieceNode {
                enhancedPiece.setDragging(false)
                enhancedPiece.celebrateSnap()
            }
            
            // Trigger particle effect
            self?.triggerSnapParticles(at: target.position)
            
            // Notify delegate
            self?.gameDelegate?.pieceSnapped()
        }
        
        print("📍 Piece \(pieceNode.piece.type.rawValue) snapped to target with enhanced animation")
    }
    
    private func triggerSnapParticles(at position: CGPoint) {
        guard let particles = snapParticles else { return }
        
        particles.position = position
        particles.resetSimulation()
        addChild(particles)
        
        // Remove particles after animation
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.removeFromParent()
        ])
        particles.run(removeAction)
    }
    
    private func isTargetOccupied(_ targetNode: SKShapeNode) -> Bool {
        // Check if any locked piece is at this target position
        for pieceNode in pieceNodes {
            if pieceNode.isSnapped && distanceBetween(pieceNode.position, targetNode.position) < 10 {
                return true
            }
        }
        return false
    }
    
    private func highlightNearbyTargets(for pieceNode: TangramPieceNode) {
        for targetNode in targetNodes {
            let isNearby = findSnapTarget(for: pieceNode) == targetNode
            if isNearby {
                // Enhanced highlight with magnetic effect
                targetNode.removeAllActions()
                targetNode.strokeColor = UIColor.systemGreen
                targetNode.fillColor = UIColor.systemGreen.withAlphaComponent(0.3)
                targetNode.alpha = 1.0
                targetNode.lineWidth = 6
                
                // Add magnetic pulsing
                let magneticPulse = SKAction.sequence([
                    SKAction.scale(to: 1.1, duration: 0.3),
                    SKAction.scale(to: 1.0, duration: 0.3)
                ])
                targetNode.run(SKAction.repeatForever(magneticPulse))
                
                // Update inner glow
                if let innerGlow = targetNode.children.first as? SKShapeNode {
                    innerGlow.strokeColor = UIColor.systemGreen.withAlphaComponent(0.8)
                }
            } else {
                // Reset to normal enhanced state
                resetTargetToNormalState(targetNode)
            }
        }
    }
    
    private func clearTargetHighlights() {
        for targetNode in targetNodes {
            resetTargetToNormalState(targetNode)
        }
    }
    
    private func resetTargetToNormalState(_ targetNode: SKShapeNode) {
        targetNode.removeAllActions()
        targetNode.strokeColor = UIColor.systemBlue
        targetNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.15)
        targetNode.alpha = 0.9
        targetNode.lineWidth = 5
        
        // Reset inner glow
        if let innerGlow = targetNode.children.first as? SKShapeNode {
            innerGlow.strokeColor = UIColor.systemBlue.withAlphaComponent(0.6)
        }
        
        // Restart enhanced pulsing animation
        let colorPulse = SKAction.sequence([
            SKAction.run {
                targetNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.25)
                if let innerGlow = targetNode.children.first as? SKShapeNode {
                    innerGlow.strokeColor = UIColor.systemBlue.withAlphaComponent(0.8)
                }
            },
            SKAction.wait(forDuration: 1.2),
            SKAction.run {
                targetNode.fillColor = UIColor.systemBlue.withAlphaComponent(0.15)
                if let innerGlow = targetNode.children.first as? SKShapeNode {
                    innerGlow.strokeColor = UIColor.systemBlue.withAlphaComponent(0.6)
                }
            },
            SKAction.wait(forDuration: 1.2)
        ])
        targetNode.run(SKAction.repeatForever(colorPulse))
    }
    
    // MARK: - Utility Methods
    
    private func clearExistingPieces() {
        pieceNodes.forEach { $0.removeFromParent() }
        pieceNodes.removeAll()
    }
    
    private func createPiecePath(from points: [CGPoint], scale: CGFloat = 1.0) -> CGPath {
        let path = CGMutablePath()
        
        if let firstPoint = points.first {
            let scaledFirstPoint = CGPoint(x: firstPoint.x * scale, y: firstPoint.y * scale)
            path.move(to: scaledFirstPoint)
            for point in points.dropFirst() {
                let scaledPoint = CGPoint(x: point.x * scale, y: point.y * scale)
                path.addLine(to: scaledPoint)
            }
            path.closeSubpath()
        }
        
        return path
    }
    
    private func distanceBetween(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - Base Tangram Piece Node

class TangramPieceNode: SKShapeNode {
    
    // MARK: - Properties
    let piece: TangramPiece
    var originalTrayPosition: CGPoint = .zero
    var isSnapped: Bool = false
    var isLocked: Bool { return isSnapped }
    
    // MARK: - Initialization
    
    init(piece: TangramPiece) {
        self.piece = piece
        super.init()
        
        setupNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    func setupNode() {
        // Create shape path from piece points
        let path = createPiecePath()
        self.path = path
        
        // Style the piece
        fillColor = piece.color
        strokeColor = UIColor.black.withAlphaComponent(0.8)
        lineWidth = 2
        
        // Set name for debugging
        name = piece.id
        
        print("🧩 Created piece node: \(piece.type.rawValue)")
    }
    
    private func createPiecePath() -> CGPath {
        let path = CGMutablePath()
        let scaledPoints = piece.points.map { point in
            CGPoint(x: point.x * piece.size, y: point.y * piece.size)
        }
        
        if let firstPoint = scaledPoints.first {
            path.move(to: firstPoint)
            for point in scaledPoints.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
        
        return path
    }
    
    // MARK: - State Management
    
    func snap() {
        isSnapped = true
        
        // Visual feedback for snapped state
        let snapAction = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        run(snapAction)
        
        // Add subtle glow effect
        strokeColor = UIColor.systemGreen
        lineWidth = 3
    }
    
    func unsnap() {
        isSnapped = false
        
        // Reset visual state
        strokeColor = UIColor.black.withAlphaComponent(0.8)
        lineWidth = 2
    }
    
    func returnToTray() {
        // Animate return to tray
        let moveAction = SKAction.move(to: originalTrayPosition, duration: 0.3)
        moveAction.timingMode = .easeOut
        
        let rotateAction = SKAction.rotate(toAngle: 0, duration: 0.3)
        
        let resetGroup = SKAction.group([moveAction, rotateAction])
        
        run(resetGroup) { [weak self] in
            self?.zPosition = 0
            self?.unsnap()
        }
    }
}

// MARK: - Enhanced Tangram Piece Node

class EnhancedTangramPieceNode: TangramPieceNode {
    
    // Enhanced visual elements
    private var shadowNode: SKShapeNode?
    private var glowNode: SKShapeNode?
    private var isDragging: Bool = false
    
    override func setupNode() {
        // Create enhanced shape path from piece points
        let path = createPiecePath()
        self.path = path
        
        // Create shadow layer
        shadowNode = SKShapeNode(path: path)
        if let shadow = shadowNode {
            shadow.fillColor = UIColor.black.withAlphaComponent(0.15)
            shadow.strokeColor = UIColor.clear
            shadow.position = CGPoint(x: 2, y: -2)
            shadow.zPosition = -1
            addChild(shadow)
        }
        
        // Enhanced piece styling with gradient-like effect
        fillColor = piece.color
        strokeColor = UIColor.white.withAlphaComponent(0.9)
        lineWidth = 3
        
        // Add subtle inner highlight
        glowNode = SKShapeNode(path: path)
        if let glow = glowNode {
            glow.fillColor = UIColor.clear
            glow.strokeColor = UIColor.white.withAlphaComponent(0.4)
            glow.lineWidth = 1
            glow.zPosition = 1
            addChild(glow)
        }
        
        // Set name for debugging
        name = piece.id
        
        // Add subtle breathing animation
        let breathe = SKAction.sequence([
            SKAction.scale(to: 1.02, duration: 2.0),
            SKAction.scale(to: 1.0, duration: 2.0)
        ])
        run(SKAction.repeatForever(breathe))
        
        print("🧩 Created enhanced piece node: \(piece.type.rawValue)")
    }
    
    private func createPiecePath() -> CGPath {
        let path = CGMutablePath()
        let scaledPoints = piece.points.map { point in
            CGPoint(x: point.x * piece.size, y: point.y * piece.size)
        }
        
        if let firstPoint = scaledPoints.first {
            path.move(to: firstPoint)
            for point in scaledPoints.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
        }
        
        return path
    }
    
    func setDragging(_ dragging: Bool) {
        isDragging = dragging
        
        if dragging {
            // Enhanced dragging visual feedback
            shadowNode?.position = CGPoint(x: 4, y: -4)
            shadowNode?.alpha = 0.3
            glowNode?.strokeColor = UIColor.white.withAlphaComponent(0.7)
            strokeColor = UIColor.white
            lineWidth = 4
        } else {
            // Return to normal state
            shadowNode?.position = CGPoint(x: 2, y: -2)
            shadowNode?.alpha = 1.0
            glowNode?.strokeColor = UIColor.white.withAlphaComponent(0.4)
            strokeColor = UIColor.white.withAlphaComponent(0.9)
            lineWidth = 3
        }
    }
    
    func celebrateSnap() {
        // Enhanced snap celebration
        let celebration = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.3),
            SKAction.run { [weak self] in
                // Add success glow
                self?.glowNode?.strokeColor = UIColor.systemGreen.withAlphaComponent(0.8)
                self?.strokeColor = UIColor.systemGreen
            },
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                // Return to normal colors
                self?.glowNode?.strokeColor = UIColor.white.withAlphaComponent(0.4)
                self?.strokeColor = UIColor.white.withAlphaComponent(0.9)
            }
        ])
        run(celebration)
    }
    
    override func returnToTray() {
        // Enhanced return animation with trail effect
        let moveAction = SKAction.move(to: originalTrayPosition, duration: 0.4)
        moveAction.timingMode = .easeOut
        
        let rotateAction = SKAction.rotate(toAngle: 0, duration: 0.4)
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.4)
        
        let resetGroup = SKAction.group([moveAction, rotateAction, scaleAction])
        
        run(resetGroup) { [weak self] in
            self?.zPosition = 0
            self?.unsnap()
            self?.setDragging(false)
        }
    }
}

// Make TangramPieceNode inherit from the enhanced version for backwards compatibility
// typealias TangramPieceNode = EnhancedTangramPieceNode 