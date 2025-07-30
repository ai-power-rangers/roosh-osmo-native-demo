import SwiftUI
import AVFoundation
import Vision
import SpriteKit

struct DrawingCaptureView: View {
    @State private var viewModel = DrawingCaptureViewModel()
    @State private var showingGameView = false
    @State private var capturedImage: UIImage?
    @State private var isCapturing = false
    
    var body: some View {
        ZStack {
            if showingGameView, let image = capturedImage {
                // Game view with the captured drawing
                DrawingGameView(capturedImage: image)
                    .ignoresSafeArea()
                    .overlay(alignment: .topTrailing) {
                        Button(action: {
                            showingGameView = false
                            capturedImage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .padding()
                    }
            } else {
                // Camera capture view
                CameraPreviewView(session: viewModel.captureSession)
                    .ignoresSafeArea()
                    .overlay(alignment: .center) {
                        // Drawing area guide
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 300, height: 300)
                            .overlay(
                                Text("Draw inside this area")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(10)
                                    .offset(y: -180)
                            )
                    }
                    .overlay(alignment: .bottom) {
                        captureButton
                    }
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .alert("Camera Access Required", isPresented: $viewModel.showingPermissionAlert) {
            Button("OK") { }
        } message: {
            Text("Please enable camera access in Settings to capture drawings.")
        }
    }
    
    private var captureButton: some View {
        Button(action: captureDrawing) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 70, height: 70)
                
                if isCapturing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(isCapturing)
        .padding(.bottom, 30)
    }
    
    private func captureDrawing() {
        isCapturing = true
        
        viewModel.capturePhoto { image in
            if let processedImage = viewModel.processDrawing(from: image) {
                capturedImage = processedImage
                showingGameView = true
            }
            isCapturing = false
        }
    }
}

// Camera preview using UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

// Game view wrapper for SpriteKit
struct DrawingGameView: View {
    let capturedImage: UIImage
    @State private var scene: DrawingGameScene?
    
    var body: some View {
        ZStack {
            if let scene = scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
                ProgressView("Loading game...")
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            setupScene()
        }
    }
    
    private func setupScene() {
        let newScene = DrawingGameScene(size: UIScreen.main.bounds.size)
        newScene.scaleMode = .resizeFill
        newScene.backgroundColor = .systemBlue
        
        // Add the captured drawing to the scene after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            newScene.addDrawing(capturedImage)
        }
        
        scene = newScene
    }
}

struct DrawingCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        DrawingCaptureView()
    }
}