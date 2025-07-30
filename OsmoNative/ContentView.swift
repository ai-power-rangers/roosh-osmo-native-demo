import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Emoji Expression Tab
            EmojiExpressionView()
                .tabItem {
                    Image(systemName: "face.smiling")
                    Text("Emoji")
                }
            
            // Counting Game Tab
            CountingGameView()
                .tabItem {
                    Image(systemName: "hand.raised")
                    Text("Counting")
                }
            
            // Drawing Capture Tab
            DrawingCaptureView()
                .tabItem {
                    Image(systemName: "pencil.and.outline")
                    Text("Draw")
                }
        }
        .onAppear {
            print("🚀 TabView ContentView appeared")
        }
    }
}

// MARK: - Emoji Expression View
struct EmojiExpressionView: View {
    // Using @State with @Observable pattern for modern SwiftUI state management
    @State private var viewModel = CameraViewModel()

    var body: some View {
        VStack(spacing: 20) {
            // Title with dynamic feedback based on facial expressions
            Text(expressionTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isSmiling)

            // SpriteKit emoji that matches facial expressions
            EmojiSpriteView(viewModel: .constant(viewModel))
                .frame(width: 300, height: 300)
                .background(Color.black.opacity(0.05))
                .cornerRadius(20)
                .shadow(radius: 10)
            
            // Facial expression debug panel
            expressionDebugPanel
        }
        .onAppear {
            // Start ARKit face tracking when view appears
            viewModel.startSession()
            print("🚀 EmojiExpressionView appeared - ARKit session starting")
        }
        .onDisappear {
            // Stop ARKit session to save battery when view disappears
            viewModel.stopSession()
            print("⏹️ EmojiExpressionView disappeared - ARKit session stopped")
        }
    }
    
    // MARK: - Computed Properties
    
    // Dynamic title based on facial expressions
    private var expressionTitle: String {
        if viewModel.isSmiling && viewModel.mouthOpenness > 0.3 {
            return "Wow! Big Smile! 😄"
        } else if viewModel.isSmiling {
            return "Great Smile! 😊"
        } else if viewModel.isBlinking {
            return "Blink Detected! 😉"
        } else if viewModel.eyebrowPosition > 0.5 {
            return "Surprised Look! 😮"
        } else if viewModel.eyebrowPosition < -0.3 {
            return "Focused Expression 🤔"
        } else if viewModel.mouthOpenness > 0.4 {
            return "Mouth Open! 😲"
        } else {
            return "Show Me Your Expression!"
        }
    }
    
    // Debug panel showing facial expression data
    private var expressionDebugPanel: some View {
        VStack(spacing: 8) {
            Text("Expression Data")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                // Smile intensity
                VStack {
                    Text("😊")
                        .font(.title2)
                    Text("\(Int(viewModel.smileIntensity * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundColor(viewModel.isSmiling ? .green : .secondary)
                
                // Blink status
                VStack {
                    Text("👁️")
                        .font(.title2)
                    Text(viewModel.isBlinking ? "BLINK" : "OPEN")
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundColor(viewModel.isBlinking ? .blue : .secondary)
                
                // Eyebrow position
                VStack {
                    Text("🤨")
                        .font(.title2)
                    Text("\(Int(viewModel.eyebrowPosition * 100))")
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundColor(abs(viewModel.eyebrowPosition) > 0.3 ? .orange : .secondary)
                
                // Mouth openness
                VStack {
                    Text("😮")
                        .font(.title2)
                    Text("\(Int(viewModel.mouthOpenness * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundColor(viewModel.mouthOpenness > 0.3 ? .red : .secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

// Preview provider for Xcode canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
