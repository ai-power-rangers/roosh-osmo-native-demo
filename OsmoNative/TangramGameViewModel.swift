import SwiftUI
import Foundation

// MARK: - Tangram Game View Model
@Observable
final class TangramGameViewModel: TangramGameDelegate {
    
    // MARK: - Game State
    var currentLevel: Int = 1
    var placedPieces: Int = 0
    var showSuccess: Bool = false
    var autoResetCountdown: Int = 0
    
    // MARK: - Templates
    var currentTemplateIndex: Int = 0
    
    // Auto-reset timer
    private var resetTimer: Timer?
    
    init() {
        print("🎯 TangramGameViewModel initialized")
        setupInitialState()
    }
    
    // MARK: - Public Methods
    
    func resetPuzzle() {
        placedPieces = 0
        showSuccess = false
        autoResetCountdown = 0
        resetTimer?.invalidate()
        resetTimer = nil
        print("🔄 Puzzle reset")
    }
    
    func nextLevel() {
        currentLevel += 1
        currentTemplateIndex = (currentTemplateIndex + 1) % tangramTemplates.count
        resetPuzzle()
        print("⬆️ Advanced to level \(currentLevel)")
    }
    
    // MARK: - Current Template
    
    var currentTemplate: TangramTemplate {
        return tangramTemplates[currentTemplateIndex]
    }
    
    // MARK: - Private Methods
    
    private func setupInitialState() {
        // No game message setup needed anymore
    }
    
    private func completePuzzle() {
        showSuccess = true
        
        // Start 5-second countdown for auto-reset
        autoResetCountdown = 5
        resetTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.autoResetCountdown -= 1
            
            if self.autoResetCountdown <= 0 {
                timer.invalidate()
                self.resetTimer = nil
                self.nextLevel()
                // Trigger scene reset in the view
                NotificationCenter.default.post(name: .tangramLevelAdvanced, object: nil)
            }
        }
        
        print("🎉 Puzzle completed! Auto-advancing in 5 seconds...")
    }
    
    // MARK: - TangramGameDelegate
    
    func pieceSnapped() {
        // This method is called from the SpriteKit scene when a piece snaps into place
        placedPieces += 1
        
        // Check for completion - now just need 1 piece
        if placedPieces >= 1 {
            completePuzzle()
        }
        
        print("📍 Piece snapped! Total placed: \(placedPieces)/1")
    }
    
    func pieceUnsnapped() {
        // This method is called from the SpriteKit scene when a piece is removed from its target
        placedPieces = max(0, placedPieces - 1)
        print("🔄 Piece unsnapped! Total placed: \(placedPieces)/1")
    }
}

// MARK: - Tangram Piece Definitions

enum TangramPieceType: String, CaseIterable {
    case largTriangle1 = "large_triangle_1"
    case largTriangle2 = "large_triangle_2"
    case mediumTriangle = "medium_triangle"
    case smallTriangle1 = "small_triangle_1"
    case smallTriangle2 = "small_triangle_2"
    case square = "square"
    case parallelogram = "parallelogram"
}

struct TangramPiece {
    let type: TangramPieceType
    let id: String
    let color: UIColor
    let points: [CGPoint] // Relative to center, normalized to unit size
    let size: CGFloat // Scale factor for this piece
    
    static let allPieces: [TangramPiece] = [
        // Large triangles (isosceles right triangles) - Enhanced with vibrant colors
        TangramPiece(
            type: .largTriangle1,
            id: "large_tri_1",
            color: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), // Vibrant coral red
            points: [CGPoint(x: -50, y: -50), CGPoint(x: 50, y: -50), CGPoint(x: 0, y: 50)],
            size: 1.0
        ),
        TangramPiece(
            type: .largTriangle2,
            id: "large_tri_2",
            color: UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0), // Bright sky blue
            points: [CGPoint(x: -50, y: -50), CGPoint(x: 50, y: -50), CGPoint(x: 0, y: 50)],
            size: 1.0
        ),
        
        // Medium triangle - Enhanced green
        TangramPiece(
            type: .mediumTriangle,
            id: "medium_tri",
            color: UIColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0), // Fresh emerald green
            points: [CGPoint(x: -35, y: -35), CGPoint(x: 35, y: -35), CGPoint(x: 0, y: 35)],
            size: 0.7
        ),
        
        // Small triangles - Enhanced colors
        TangramPiece(
            type: .smallTriangle1,
            id: "small_tri_1",
            color: UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0), // Bright golden yellow
            points: [CGPoint(x: -25, y: -25), CGPoint(x: 25, y: -25), CGPoint(x: 0, y: 25)],
            size: 0.5
        ),
        TangramPiece(
            type: .smallTriangle2,
            id: "small_tri_2",
            color: UIColor(red: 0.8, green: 0.3, blue: 1.0, alpha: 1.0), // Vibrant purple
            points: [CGPoint(x: -25, y: -25), CGPoint(x: 25, y: -25), CGPoint(x: 0, y: 25)],
            size: 0.5
        ),
        
        // Square - Enhanced orange
        TangramPiece(
            type: .square,
            id: "square",
            color: UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0), // Warm tangerine orange
            points: [CGPoint(x: -25, y: -25), CGPoint(x: 25, y: -25), CGPoint(x: 25, y: 25), CGPoint(x: -25, y: 25)],
            size: 0.5
        ),
        
        // Parallelogram - Enhanced teal
        TangramPiece(
            type: .parallelogram,
            id: "parallelogram",
            color: UIColor(red: 0.2, green: 0.8, blue: 0.8, alpha: 1.0), // Bright turquoise teal
            points: [CGPoint(x: -35, y: -25), CGPoint(x: 10, y: -25), CGPoint(x: 35, y: 25), CGPoint(x: -10, y: 25)],
            size: 0.7
        )
    ]
}

// MARK: - Template Definitions

struct TangramTemplate {
    let name: String
    let targetPositions: [TangramPieceTarget]
    let outlinePoints: [CGPoint] // Overall shape outline for visual template
}

struct TangramPieceTarget {
    let pieceType: TangramPieceType
    let position: CGPoint // Relative to template center
    let rotation: CGFloat // In radians
}

// MARK: - Template Data

let tangramTemplates: [TangramTemplate] = [
    
    // Template 1: Just one large triangle
    TangramTemplate(
        name: "Large Triangle",
        targetPositions: [
            TangramPieceTarget(pieceType: .largTriangle1, position: CGPoint(x: 0, y: 0), rotation: 0)
        ],
        outlinePoints: [] // No outline needed
    ),
    
    // Template 2: Just one medium triangle
    TangramTemplate(
        name: "Medium Triangle",
        targetPositions: [
            TangramPieceTarget(pieceType: .mediumTriangle, position: CGPoint(x: 0, y: 0), rotation: 0)
        ],
        outlinePoints: [] // No outline needed
    ),
    
    // Template 3: Just one small triangle
    TangramTemplate(
        name: "Small Triangle",
        targetPositions: [
            TangramPieceTarget(pieceType: .smallTriangle1, position: CGPoint(x: 0, y: 0), rotation: 0)
        ],
        outlinePoints: [] // No outline needed
    ),
    
    // Template 4: Just the square
    TangramTemplate(
        name: "Square",
        targetPositions: [
            TangramPieceTarget(pieceType: .square, position: CGPoint(x: 0, y: 0), rotation: 0)
        ],
        outlinePoints: [] // No outline needed
    ),
    
    // Template 5: Just the parallelogram
    TangramTemplate(
        name: "Parallelogram",
        targetPositions: [
            TangramPieceTarget(pieceType: .parallelogram, position: CGPoint(x: 0, y: 0), rotation: 0)
        ],
        outlinePoints: [] // No outline needed
    )
]

// MARK: - Notification Names

extension Notification.Name {
    static let tangramLevelAdvanced = Notification.Name("tangramLevelAdvanced")
} 