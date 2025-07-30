import SwiftUI
import AVFoundation

// CountingGame SwiftUI View with camera preview and game interface
// Uses modern SwiftUI patterns with @Observable ViewModel
struct CountingGameView: View {
    // Using @State with @Observable pattern for modern SwiftUI state management
    @State private var viewModel = CountingGameViewModel()
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Game Header
                gameHeader
                
                // Camera Preview with Overlay
                cameraPreviewSection
                
                // Game Controls
                gameControls
                
                // Debug Panel
                debugPanel
            }
            .padding()
            
            // Success/Error Feedback Overlay
            feedbackOverlay
        }
        .onAppear {
            // Start camera session when view appears
            viewModel.startSession()
            print("📹 CountingGameView appeared - starting camera session")
        }
        .onDisappear {
            // Stop camera session to save battery when view disappears
            viewModel.stopSession()
            print("⏹️ CountingGameView disappeared - stopping camera session")
        }
    }
    
    // MARK: - View Components
    
    private var gameHeader: some View {
        VStack(spacing: 8) {
            Text("Finger Counting Game")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                // Score display
                VStack {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                // Round display
                VStack {
                    Text("Round")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.round)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var cameraPreviewSection: some View {
        ZStack {
            // Camera Preview
            CameraPreview(viewModel: viewModel)
                .frame(height: 300)
                .background(Color.black.opacity(0.1))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.gameActive ? Color.blue : Color.gray, lineWidth: 3)
                )
            
            // Game Message Overlay
            VStack {
                Spacer()
                
                Text(viewModel.gameMessage)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.black.opacity(0.7))
                    )
                    .padding(.bottom, 20)
            }
            
            // Target Number Display
            VStack {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Target")
                            .font(.caption)
                            .foregroundColor(.white)
                        Text("\(viewModel.targetNumber)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.orange)
                                    .shadow(radius: 5)
                            )
                    }
                    .padding(.trailing, 15)
                    .padding(.top, 15)
                }
                
                Spacer()
            }
            
            // Current Finger Count Display
            VStack {
                HStack {
                    VStack(spacing: 4) {
                        Text("Detected")
                            .font(.caption)
                            .foregroundColor(.white)
                        Text("\(viewModel.currentFingerCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(fingerCountColor)
                                    .shadow(radius: 5)
                            )
                    }
                    .padding(.leading, 15)
                    .padding(.top, 15)
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
    
    private var gameControls: some View {
        HStack(spacing: 20) {
            // Start New Game Button
            Button(action: {
                viewModel.startNewGame()
                print("🎯 New game started")
            }) {
                Text("New Game")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.green)
                            .shadow(radius: 3)
                    )
            }
            
            // Next Round Button (only show during success)
            if viewModel.showSuccess {
                Button(action: {
                    viewModel.round += 1
                    viewModel.showSuccess = false
                    viewModel.startNewRound()
                    print("➡️ Manual next round triggered")
                }) {
                    Text("Next Round")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue)
                                .shadow(radius: 3)
                        )
                }
            }
        }
    }
    
    private var debugPanel: some View {
        VStack(spacing: 8) {
            Text("Game Status")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                // Game Active Status
                VStack {
                    Text("🎮")
                        .font(.title2)
                    Text(viewModel.gameActive ? "ACTIVE" : "PAUSED")
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundColor(viewModel.gameActive ? .green : .gray)
                
                // Target vs Detected
                VStack {
                    Text("🎯")
                        .font(.title2)
                    Text("\(viewModel.targetNumber) vs \(viewModel.currentFingerCount)")
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundColor(viewModel.currentFingerCount == viewModel.targetNumber ? .green : .orange)
                
                // Success Status
                VStack {
                    Text("✅")
                        .font(.title2)
                    Text(viewModel.showSuccess ? "SUCCESS" : "WAITING")
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundColor(viewModel.showSuccess ? .green : .gray)
                
                // Error Status
                VStack {
                    Text("❌")
                        .font(.title2)
                    Text(viewModel.showError ? "ERROR" : "OK")
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundColor(viewModel.showError ? .red : .gray)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var feedbackOverlay: some View {
        Group {
            if viewModel.showSuccess {
                successFeedback
            } else if viewModel.showError {
                errorFeedback
            }
        }
    }
    
    private var successFeedback: some View {
        VStack(spacing: 15) {
            Text("🎉")
                .font(.system(size: 60))
            Text("Perfect!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.green)
            Text("+10 Points")
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 10)
        )
        .scaleEffect(viewModel.showSuccess ? 1.0 : 0.8)
        .opacity(viewModel.showSuccess ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.showSuccess)
    }
    
    private var errorFeedback: some View {
        VStack(spacing: 10) {
            Text("❌")
                .font(.system(size: 40))
            Text("Try Again!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.red)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(radius: 5)
        )
        .scaleEffect(viewModel.showError ? 1.0 : 0.8)
        .opacity(viewModel.showError ? 1.0 : 0.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showError)
    }
    
    // MARK: - Computed Properties
    
    private var fingerCountColor: Color {
        if viewModel.currentFingerCount == viewModel.targetNumber && viewModel.currentFingerCount > 0 {
            return .green
        } else if viewModel.currentFingerCount > 0 {
            return .red
        } else {
            return .gray
        }
    }
}

// MARK: - Camera Preview UIViewRepresentable
struct CameraPreview: UIViewRepresentable {
    let viewModel: CountingGameViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        // Add preview layer if available
        if let previewLayer = viewModel.previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            
            // Store reference for frame updates
            context.coordinator.previewLayer = previewLayer
            print("📹 Camera preview layer added to view")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview layer frame when view size changes
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// Preview provider for Xcode canvas
struct CountingGameView_Previews: PreviewProvider {
    static var previews: some View {
        CountingGameView()
    }
} 