import Foundation
import ARKit
import UIKit

// ARKit Face Tracking ViewModel for emoji facial expression matching
// Using @Observable macro for modern SwiftUI state management
@Observable final class CameraViewModel: NSObject, ARSessionDelegate {
    
    // Published facial expression properties for SwiftUI observation
    var isSmiling: Bool = false
    var isBlinking: Bool = false
    var eyebrowPosition: Float = 0.0 // -1.0 (down) to 1.0 (up)
    var mouthOpenness: Float = 0.0 // 0.0 (closed) to 1.0 (wide open)
    var smileIntensity: Float = 0.0 // 0.0 to 1.0
    
    // Enhanced mouth expression properties for more detailed mouth tracking
    var frownIntensity: Float = 0.0 // 0.0 to 1.0 (frowning)
    var mouthPucker: Float = 0.0 // 0.0 to 1.0 (lip pucker/kiss)
    var mouthStretch: Float = 0.0 // 0.0 to 1.0 (mouth stretched wide)
    var lipPress: Float = 0.0 // 0.0 to 1.0 (lips pressed together)
    var mouthFunnel: Float = 0.0 // 0.0 to 1.0 (mouth funnel shape)
    
    // ARKit session and configuration
    private let arSession = ARSession()
    private let sessionQueue = DispatchQueue(label: "com.osmo.arSession")
    
    // Debug logging for easier debugging
    private var lastLogTime: TimeInterval = 0
    private let logInterval: TimeInterval = 1.0 // Log every second
    
    override init() {
        super.init()
        setupARSession()
        print("🔧 ARKit CameraViewModel initialized")
    }
    
    // MARK: - Public Control Methods
    func startSession() {
        sessionQueue.async {
            self.setupAndStartARSession()
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            self.arSession.pause()
            print("🛑 ARKit session stopped")
        }
    }
    
    // MARK: - ARKit Setup
    private func setupARSession() {
        // Set delegate for receiving face tracking updates
        arSession.delegate = self
        print("🎯 ARSession delegate configured")
    }
    
    private func setupAndStartARSession() {
        // Check if Face Tracking is supported on this device
        guard ARFaceTrackingConfiguration.isSupported else {
            print("❌ Face tracking is not supported on this device")
            return
        }
        
        // Create and configure ARKit Face Tracking
        let configuration = ARFaceTrackingConfiguration()
        configuration.maximumNumberOfTrackedFaces = 1 // Only track one face for performance
        
        // Start ARKit session with face tracking
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        print("🚀 ARKit Face Tracking session started")
    }
    
    // MARK: - ARSessionDelegate Methods
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Extract face anchor data for blend shapes
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        
        // Process blend shapes on main thread for SwiftUI updates
        DispatchQueue.main.async {
            self.processFaceBlendShapes(faceAnchor)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ ARSession failed with error: \(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("⚠️ ARSession was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("✅ ARSession interruption ended")
    }
    
    // MARK: - Blend Shape Processing
    private func processFaceBlendShapes(_ faceAnchor: ARFaceAnchor) {
        let blendShapes = faceAnchor.blendShapes
        
        // Extract smile data from left and right mouth corners
        let leftSmile = blendShapes[.mouthSmileLeft]?.floatValue ?? 0.0
        let rightSmile = blendShapes[.mouthSmileRight]?.floatValue ?? 0.0
        let averageSmile = (leftSmile + rightSmile) / 2.0
        
        // Extract frown data from mouth corners
        let leftFrown = blendShapes[.mouthFrownLeft]?.floatValue ?? 0.0
        let rightFrown = blendShapes[.mouthFrownRight]?.floatValue ?? 0.0
        let averageFrown = (leftFrown + rightFrown) / 2.0
        
        // Extract advanced mouth expressions
        let pucker = blendShapes[.mouthPucker]?.floatValue ?? 0.0
        let stretch = blendShapes[.mouthStretchLeft]?.floatValue ?? 0.0 // Using left as representative
        let press = blendShapes[.mouthPressLeft]?.floatValue ?? 0.0 // Using left as representative  
        let funnel = blendShapes[.mouthFunnel]?.floatValue ?? 0.0
        
        // Extract blink data from both eyes
        let leftBlink = blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
        let rightBlink = blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
        let averageBlink = (leftBlink + rightBlink) / 2.0
        
        // Extract eyebrow position (inner up vs down)
        let browInnerUp = blendShapes[.browInnerUp]?.floatValue ?? 0.0
        let browDown = blendShapes[.browDownLeft]?.floatValue ?? 0.0
        let eyebrowPos = browInnerUp - browDown // Range from -1 to 1
        
        // Extract mouth openness with multiple blend shapes for accuracy
        let jawOpen = blendShapes[.jawOpen]?.floatValue ?? 0.0
        let mouthClose = blendShapes[.mouthClose]?.floatValue ?? 0.0
        let combinedOpenness = max(0.0, jawOpen - mouthClose) // Subtract close from open for accuracy
        
        // Update observable properties with enhanced mouth tracking
        self.smileIntensity = averageSmile
        self.frownIntensity = averageFrown
        self.mouthPucker = pucker
        self.mouthStretch = stretch
        self.lipPress = press
        self.mouthFunnel = funnel
        self.isSmiling = averageSmile > 0.3 // Threshold for smile detection
        self.isBlinking = averageBlink > 0.5 // Threshold for blink detection
        self.eyebrowPosition = eyebrowPos
        self.mouthOpenness = combinedOpenness
        
        // Enhanced debug logging (throttled to avoid spam)
        logEnhancedFacialData(smile: averageSmile, frown: averageFrown, blink: averageBlink, 
                             eyebrow: eyebrowPos, mouth: combinedOpenness, pucker: pucker)
    }
    
    // Enhanced debug logging helper with more mouth data
    private func logEnhancedFacialData(smile: Float, frown: Float, blink: Float, eyebrow: Float, mouth: Float, pucker: Float) {
        let currentTime = CACurrentMediaTime()
        if currentTime - lastLogTime >= logInterval {
            print("😊 Smile: \(String(format: "%.2f", smile)) | ☹️ Frown: \(String(format: "%.2f", frown)) | 👁️ Blink: \(String(format: "%.2f", blink)) | 🤨 Eyebrow: \(String(format: "%.2f", eyebrow)) | 😮 Mouth: \(String(format: "%.2f", mouth)) | 😘 Pucker: \(String(format: "%.2f", pucker))")
            lastLogTime = currentTime
        }
    }
}
