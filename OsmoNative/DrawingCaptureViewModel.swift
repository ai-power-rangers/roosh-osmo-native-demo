import SwiftUI
import AVFoundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

@Observable
class DrawingCaptureViewModel: NSObject {
    let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var captureCompletionHandler: ((UIImage) -> Void)?
    
    var showingPermissionAlert = false
    
    override init() {
        super.init()
        checkCameraPermission()
    }
    
    func startSession() {
        guard !captureSession.isRunning else { return }
        
        Task {
            await MainActor.run {
                captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        
        captureSession.stopRunning()
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupCaptureSession()
                } else {
                    DispatchQueue.main.async {
                        self?.showingPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showingPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        
        // Use front camera for capturing drawings
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        captureSession.sessionPreset = .photo
        captureSession.commitConfiguration()
    }
    
    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        captureCompletionHandler = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func processDrawing(from image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let context = CIContext()
        
        // Apply filters to isolate the drawing
        let processedImage = ciImage
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.0,  // Convert to grayscale
                kCIInputContrastKey: 2.0,     // Increase contrast
                kCIInputBrightnessKey: 0.2    // Adjust brightness
            ])
        
        // Apply threshold to create binary image
        let thresholdFilter = CIFilter(name: "CIColorThreshold")!
        thresholdFilter.setValue(processedImage, forKey: kCIInputImageKey)
        thresholdFilter.setValue(0.4, forKey: "inputThreshold")
        
        guard let outputImage = thresholdFilter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        // Extract the drawing area (center 300x300 region)
        let drawingRect = CGRect(
            x: (cgImage.width - 600) / 2,
            y: (cgImage.height - 600) / 2,
            width: 600,
            height: 600
        )
        
        if let croppedCGImage = cgImage.cropping(to: drawingRect) {
            return UIImage(cgImage: croppedCGImage)
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension DrawingCaptureViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        // Flip the image horizontally since front camera creates mirrored images
        let flippedImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)
        
        DispatchQueue.main.async { [weak self] in
            self?.captureCompletionHandler?(flippedImage)
            self?.captureCompletionHandler = nil
        }
    }
}