import Foundation
import AVFoundation
import Vision
import UIKit

// CountingGame ViewModel using @Observable for modern SwiftUI state management
// Handles camera capture, hand pose detection, and game logic
@Observable final class CountingGameViewModel: NSObject {
    
    // MARK: - Game State Properties
    var targetNumber: Int = 1
    var currentFingerCount: Int = 0
    var gameActive: Bool = false
    var showSuccess: Bool = false
    var showError: Bool = false
    var gameMessage: String = "Get Ready!"
    var score: Int = 0
    var round: Int = 1
    
    // MARK: - Camera Properties
    var previewLayer: AVCaptureVideoPreviewLayer?
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    // MARK: - Hand Detection Properties
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private var lastFingerCount: Int = 0
    private var stableFrameCount: Int = 0
    private let requiredStableFrames = 10 // Require 10 consistent frames before counting
    
    override init() {
        super.init()
        print("🎮 CountingGameViewModel initialized")
        setupCamera()
        setupHandPoseDetection()
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        print("📷 Setting up front camera for hand detection")
        
        // Configure capture session
        captureSession.sessionPreset = .medium
        
        // Get front camera
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("❌ Front camera not available")
            return
        }
        
        do {
            // Create camera input
            let cameraInput = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
                print("✅ Front camera input added successfully")
            }
            
            // Configure video output
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
                videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
                print("✅ Video data output configured")
            }
            
            // Create preview layer
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            
        } catch {
            print("❌ Camera setup error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Hand Pose Detection Setup
    private func setupHandPoseDetection() {
        // Configure hand pose detection request
        handPoseRequest.maximumHandCount = 1 // Only detect one hand for simplicity
        print("✋ Hand pose detection configured")
    }
    
    // MARK: - Session Management
    func startSession() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                print("📹 Camera session started for counting game")
            }
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                print("⏹️ Camera session stopped for counting game")
            }
        }
    }
    
    // MARK: - Game Logic
    func startNewGame() {
        print("🎯 Starting new counting game")
        score = 0
        round = 1
        startNewRound()
    }
    
    func startNewRound() {
        print("🔄 Starting round \(round)")
        
        // Generate random target number (1-5)
        targetNumber = Int.random(in: 1...5)
        
        // Reset game state
        gameActive = true
        showSuccess = false
        showError = false
        currentFingerCount = 0
        stableFrameCount = 0
        
        // Update game message
        gameMessage = "Show \(targetNumber) finger\(targetNumber == 1 ? "" : "s")!"
        
        print("🎯 Target number: \(targetNumber)")
    }
    
    private func checkAnswer() {
        guard gameActive else { return }
        
        print("✋ Checking answer: detected \(currentFingerCount), target \(targetNumber)")
        
        if currentFingerCount == targetNumber {
            // Correct answer!
            gameActive = false
            showSuccess = true
            showError = false
            score += 10
            gameMessage = "Perfect! 🎉"
            
            print("✅ Correct answer! Score: \(score)")
            
            // Start next round after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.round += 1
                self.showSuccess = false
                self.startNewRound()
            }
        } else if currentFingerCount > 0 {
            // Wrong answer (but fingers detected)
            showError = true
            gameMessage = "Try \(targetNumber) finger\(targetNumber == 1 ? "" : "s")!"
            
            // Clear error after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.showError = false
                self.gameMessage = "Show \(self.targetNumber) finger\(self.targetNumber == 1 ? "" : "s")!"
            }
        }
    }
    
    // MARK: - Finger Counting Logic
    private func countExtendedFingers(from observation: VNHumanHandPoseObservation) -> Int {
        var fingerCount = 0
        var debugInfo: [String] = []
        
        do {
            // Check each finger individually with proper logic for each
            fingerCount += try isThumbExtended(observation: observation, debugInfo: &debugInfo) ? 1 : 0
            fingerCount += try isIndexFingerExtended(observation: observation, debugInfo: &debugInfo) ? 1 : 0
            fingerCount += try isMiddleFingerExtended(observation: observation, debugInfo: &debugInfo) ? 1 : 0
            fingerCount += try isRingFingerExtended(observation: observation, debugInfo: &debugInfo) ? 1 : 0
            fingerCount += try isPinkyExtended(observation: observation, debugInfo: &debugInfo) ? 1 : 0
            
            // Debug logging every few frames
            if debugInfo.count > 0 {
                print("👆 Finger Detection: \(debugInfo.joined(separator: ", ")) = Total: \(fingerCount)")
            }
            
        } catch {
            print("❌ Error counting fingers: \(error)")
        }
        
        return fingerCount
    }
    
    // MARK: - Individual Finger Detection Methods
    
    private func isThumbExtended(observation: VNHumanHandPoseObservation, debugInfo: inout [String]) throws -> Bool {
        let thumbTip = try observation.recognizedPoint(.thumbTip)
        let thumbIP = try observation.recognizedPoint(.thumbIP)
        let thumbCMC = try observation.recognizedPoint(.thumbCMC) // Base of thumb
        
        // Check confidence
        guard thumbTip.confidence > 0.7 && thumbIP.confidence > 0.7 && thumbCMC.confidence > 0.7 else {
            debugInfo.append("Thumb: low confidence")
            return false
        }
        
        // More sophisticated thumb detection using multiple criteria
        let horizontalDistance = abs(thumbTip.x - thumbCMC.x)
        let verticalDistance = abs(thumbTip.y - thumbCMC.y)
        
        // Thumb needs to be SIGNIFICANTLY extended (much higher threshold)
        // Both horizontally AND vertically from the base
        let isSignificantlyExtended = horizontalDistance > 0.08 && verticalDistance > 0.05
        
        // Additional check: thumb tip should be far from the IP joint too
        let tipToIPDistance = sqrt(pow(thumbTip.x - thumbIP.x, 2) + pow(thumbTip.y - thumbIP.y, 2))
        let isFullyExtended = tipToIPDistance > 0.06
        
        let isExtended = isSignificantlyExtended && isFullyExtended
        
        debugInfo.append("Thumb: \(isExtended ? "UP" : "down") (h:\(String(format: "%.3f", horizontalDistance)), v:\(String(format: "%.3f", verticalDistance)), full:\(isFullyExtended))")
        return isExtended
    }
    
    private func isIndexFingerExtended(observation: VNHumanHandPoseObservation, debugInfo: inout [String]) throws -> Bool {
        let tip = try observation.recognizedPoint(.indexTip)
        let pip = try observation.recognizedPoint(.indexPIP) // Use PIP instead of MCP for better accuracy
        
        guard tip.confidence > 0.6 && pip.confidence > 0.6 else {
            debugInfo.append("Index: low confidence")
            return false
        }
        
        // Check if tip is significantly above PIP joint
        let isExtended = tip.y > pip.y + 0.04 // Increased threshold to avoid false positives
        debugInfo.append("Index: \(isExtended ? "UP" : "down")")
        return isExtended
    }
    
    private func isMiddleFingerExtended(observation: VNHumanHandPoseObservation, debugInfo: inout [String]) throws -> Bool {
        let tip = try observation.recognizedPoint(.middleTip)
        let pip = try observation.recognizedPoint(.middlePIP)
        
        guard tip.confidence > 0.6 && pip.confidence > 0.6 else {
            debugInfo.append("Middle: low confidence")
            return false
        }
        
        let isExtended = tip.y > pip.y + 0.04
        debugInfo.append("Middle: \(isExtended ? "UP" : "down")")
        return isExtended
    }
    
    private func isRingFingerExtended(observation: VNHumanHandPoseObservation, debugInfo: inout [String]) throws -> Bool {
        let tip = try observation.recognizedPoint(.ringTip)
        let pip = try observation.recognizedPoint(.ringPIP)
        
        guard tip.confidence > 0.6 && pip.confidence > 0.6 else {
            debugInfo.append("Ring: low confidence")
            return false
        }
        
        let isExtended = tip.y > pip.y + 0.04
        debugInfo.append("Ring: \(isExtended ? "UP" : "down")")
        return isExtended
    }
    
    private func isPinkyExtended(observation: VNHumanHandPoseObservation, debugInfo: inout [String]) throws -> Bool {
        let tip = try observation.recognizedPoint(.littleTip)
        let pip = try observation.recognizedPoint(.littlePIP)
        
        guard tip.confidence > 0.6 && pip.confidence > 0.6 else {
            debugInfo.append("Pinky: low confidence")
            return false
        }
        
        let isExtended = tip.y > pip.y + 0.04
        debugInfo.append("Pinky: \(isExtended ? "UP" : "down")")
        return isExtended
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CountingGameViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Create Vision request handler from sample buffer
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .leftMirrored)
        
        do {
            // Perform hand pose detection
            try handler.perform([handPoseRequest])
            
            // Process results
            if let observation = handPoseRequest.results?.first {
                let detectedFingerCount = countExtendedFingers(from: observation)
                
                // Implement stability checking to avoid false positives
                if detectedFingerCount == lastFingerCount {
                    stableFrameCount += 1
                    
                    // Only update if we have enough stable frames
                    if stableFrameCount >= requiredStableFrames {
                        DispatchQueue.main.async {
                            self.currentFingerCount = detectedFingerCount
                            self.checkAnswer()
                        }
                    }
                } else {
                    // Reset stability counter on change
                    lastFingerCount = detectedFingerCount
                    stableFrameCount = 0
                }
            } else {
                // No hand detected - reset counter
                DispatchQueue.main.async {
                    if self.currentFingerCount != 0 {
                        self.currentFingerCount = 0
                    }
                }
            }
            
        } catch {
            print("❌ Hand pose detection error: \(error)")
        }
    }
} 