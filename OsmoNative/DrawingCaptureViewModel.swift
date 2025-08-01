import SwiftUI
import AVFoundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Processing Mode Enum
enum ImageProcessingMode {
    case raw              // No processing, just crop
    case enhanced         // Light enhancement while preserving color
    case drawing          // Optimized for pen/pencil drawings
    case adaptive         // Smart processing based on image analysis
}

@Observable
class DrawingCaptureViewModel: NSObject {
    let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var captureCompletionHandler: ((UIImage) -> Void)?
    
    var showingPermissionAlert = false
    var processingMode: ImageProcessingMode = .enhanced // Default to enhanced mode
    
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
        guard let ciImage = CIImage(image: image) else { 
            print("❌ Failed to create CIImage from UIImage")
            return nil 
        }
        
        print("🔄 Processing image with mode: \(processingMode)")
        let context = CIContext()
        
        // Process based on selected mode
        let processedImage: CIImage
        
        switch processingMode {
        case .raw:
            // No processing, just use original
            processedImage = ciImage
            
        case .enhanced:
            // Light enhancement while preserving color and detail
            processedImage = ciImage
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputSaturationKey: 1.1,     // Slightly boost saturation
                    kCIInputContrastKey: 1.3,       // Gentle contrast boost
                    kCIInputBrightnessKey: 0.1      // Slight brightness increase
                ])
                .applyingFilter("CISharpenLuminance", parameters: [
                    kCIInputSharpnessKey: 0.5       // Light sharpening
                ])
            
        case .drawing:
            // Optimized for pen/pencil drawings - more aggressive but still preserves some color
            processedImage = ciImage
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputSaturationKey: 0.3,     // Reduce but don't eliminate color
                    kCIInputContrastKey: 1.8,       // High contrast for line clarity
                    kCIInputBrightnessKey: 0.15     // Modest brightness boost
                ])
                .applyingFilter("CISharpenLuminance", parameters: [
                    kCIInputSharpnessKey: 1.0       // More aggressive sharpening
                ])
            
        case .adaptive:
            // Smart processing based on image brightness analysis
            processedImage = adaptiveProcessing(for: ciImage)
        }
        
        // Smart cropping - find the optimal region
        let croppedImage = smartCrop(image: processedImage, context: context)
        
        guard let cgImage = context.createCGImage(croppedImage, from: croppedImage.extent) else {
            print("❌ Failed to create CGImage from processed CIImage")
            return image
        }
        
        print("✅ Successfully processed image")
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Smart Processing Methods
    
    private func adaptiveProcessing(for ciImage: CIImage) -> CIImage {
        // Analyze image brightness to determine optimal processing
        let brightnessFilter = CIFilter(name: "CIAreaAverage")!
        brightnessFilter.setValue(ciImage, forKey: kCIInputImageKey)
        brightnessFilter.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
        
        guard let outputImage = brightnessFilter.outputImage else {
            print("⚠️ Brightness analysis failed, using enhanced mode")
            return ciImage.applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 1.3,
                kCIInputBrightnessKey: 0.1
            ])
        }
        
        // Extract brightness value (simplified approach)
        let context = CIContext()
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        let brightness = Float(bitmap[0]) / 255.0
        print("📊 Image brightness: \(brightness)")
        
        // Adjust processing based on brightness
        if brightness < 0.3 {
            // Dark image - boost brightness more
            print("🌑 Dark image detected - boosting brightness")
            return ciImage.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 1.2,
                kCIInputContrastKey: 1.5,
                kCIInputBrightnessKey: 0.3
            ])
        } else if brightness > 0.7 {
            // Bright image - reduce brightness, increase contrast
            print("☀️ Bright image detected - reducing brightness")
            return ciImage.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.9,
                kCIInputContrastKey: 1.4,
                kCIInputBrightnessKey: -0.1
            ])
        } else {
            // Well-lit image - standard enhancement
            print("💡 Well-lit image - standard enhancement")
            return ciImage.applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 1.1,
                kCIInputContrastKey: 1.3,
                kCIInputBrightnessKey: 0.1
            ])
        }
    }
    
    private func smartCrop(image: CIImage, context: CIContext) -> CIImage {
        let originalSize = image.extent
        
        // Calculate crop size as percentage of image (more flexible than fixed 600px)
        let cropPercentage: CGFloat = 0.7  // Use 70% of the smaller dimension
        let smallerDimension = min(originalSize.width, originalSize.height)
        let cropSize = smallerDimension * cropPercentage
        
        // Center the crop region
        let cropRect = CGRect(
            x: (originalSize.width - cropSize) / 2,
            y: (originalSize.height - cropSize) / 2,
            width: cropSize,
            height: cropSize
        )
        
        print("📐 Cropping to rect: \(cropRect) from original: \(originalSize)")
        
        return image.cropped(to: cropRect)
    }
    
    // MARK: - Public Interface Methods
    
    /// Sets the processing mode for captured images
    func setProcessingMode(_ mode: ImageProcessingMode) {
        print("🔧 Switching processing mode to: \(mode)")
        processingMode = mode
    }
    
    /// Returns an unprocessed, cropped version of the image for comparison
    func getUnprocessedImage(from image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let context = CIContext()
        let croppedImage = smartCrop(image: ciImage, context: context)
        
        guard let cgImage = context.createCGImage(croppedImage, from: croppedImage.extent) else {
            return image
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