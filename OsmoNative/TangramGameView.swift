import SwiftUI
import SpriteKit
import Combine

// MARK: - Tangram Game View
struct TangramGameView: View {
    // Using @State with @Observable pattern for modern SwiftUI state management
    @State private var viewModel = TangramGameViewModel()
    @State private var scene: TangramGameScene?
    
    var body: some View {
        ZStack {
            // Enhanced background with multiple gradient layers
            backgroundGradient
            
            VStack(spacing: 0) {
                // Enhanced Game Header
                modernGameHeader
                
                // SpriteKit Game Scene with enhanced styling
                if let scene = scene {
                    SpriteView(scene: scene)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.95))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 16)
                        .onAppear {
                            // Connect scene to view model
                            scene.gameDelegate = viewModel
                            print("🎯 TangramGameScene connected to ViewModel")
                        }
                } else {
                    // Enhanced loading state
                    modernLoadingView
                }
                
                // Enhanced Game Status Panel
                modernGameStatusPanel
                    .padding(.bottom, 80) // Add bottom padding to avoid tab bar
            }
            
            // Enhanced Success/Error Feedback Overlay
            enhancedFeedbackOverlay
        }
        .onAppear {
            setupScene()
            print("🎯 TangramGameView appeared - initializing game")
        }
        .onReceive(NotificationCenter.default.publisher(for: .tangramLevelAdvanced)) { _ in
            // Handle level advancement - setup new template and reset pieces
            scene?.setupTemplate(viewModel.currentTemplate)
            scene?.resetAllPieces()
            print("🔄 Scene updated for new level: \(viewModel.currentLevel)")
        }
    }
    
    // MARK: - Enhanced View Components
    
    private var backgroundGradient: some View {
        ZStack {
            // Primary gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.95, blue: 0.98),
                    Color(red: 1.0, green: 0.98, blue: 0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Secondary accent overlay
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.02),
                    Color.clear
                ]),
                center: .topTrailing,
                startRadius: 100,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }
    
    private var modernGameHeader: some View {
        VStack(spacing: 12) {
            // Title with gradient text effect
            Text("Tangram Puzzle")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            HStack(spacing: 24) {
                // Enhanced level display
                modernStatCard(
                    title: "Level",
                    value: "\(viewModel.currentLevel)",
                    color: .orange,
                    icon: "trophy.fill"
                )
                
                // Enhanced target display
                modernStatCard(
                    title: "Find",
                    value: viewModel.currentTemplate.name,
                    color: .blue,
                    icon: "target"
                )
                
                // Enhanced reset button
                modernActionButton()
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private func modernStatCard(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func modernActionButton() -> some View {
        Button(action: {
            viewModel.resetPuzzle()
            scene?.resetAllPieces()
            print("🔄 Puzzle reset triggered")
        }) {
            VStack(spacing: 6) {
                Image(systemName: "arrow.clockwise")
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text("Reset")
                    .font(.caption)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.purple.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
            )
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.placedPieces)
    }
    
    private var modernLoadingView: some View {
        VStack(spacing: 20) {
            // Enhanced loading animation
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: true)
            }
            
            VStack(spacing: 8) {
                Text("Loading Tangram...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Preparing puzzle pieces...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
    }
    
    private var modernGameStatusPanel: some View {
        VStack(spacing: 12) {
            if viewModel.placedPieces > 0 {
                // Enhanced success indicator
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Perfect Match!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }
                .scaleEffect(1.1)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.placedPieces)
            } else {
                // Enhanced progress indicator
                VStack(spacing: 8) {
                    Text("Drag the matching piece to the target")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    ProgressView(value: 0.0, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                        .padding(.horizontal, 20)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
    
    private var enhancedFeedbackOverlay: some View {
        Group {
            if viewModel.showSuccess {
                enhancedSuccessFeedback
            }
        }
    }
    
    private var enhancedSuccessFeedback: some View {
        VStack(spacing: 20) {
            // Animated celebration icon
            Text("🎉")
                .font(.system(size: 80))
                .scaleEffect(viewModel.showSuccess ? 1.2 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1), value: viewModel.showSuccess)
            
            VStack(spacing: 12) {
                Text("Puzzle Complete!")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Fantastic work!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
            
            // Enhanced countdown with progress ring
            if viewModel.autoResetCountdown > 0 {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.2), lineWidth: 4)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.autoResetCountdown) / 5.0)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1.0), value: viewModel.autoResetCountdown)
                        
                        Text("\(viewModel.autoResetCountdown)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Next puzzle loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .scaleEffect(viewModel.showSuccess ? 1.0 : 0.8)
        .opacity(viewModel.showSuccess ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: viewModel.showSuccess)
    }
    
    // MARK: - Setup
    
    private func setupScene() {
        // Create SpriteKit scene for tangram game
        let newScene = TangramGameScene(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.7))
        newScene.scaleMode = .resizeFill
        newScene.backgroundColor = UIColor.clear // Make transparent for our custom background
        
        // Store initial template to set up after scene is ready
        newScene.initialTemplate = viewModel.currentTemplate
        
        scene = newScene
        print("🎯 TangramGameScene created and configured")
    }
}

// Preview provider for Xcode canvas
struct TangramGameView_Previews: PreviewProvider {
    static var previews: some View {
        TangramGameView()
    }
} 