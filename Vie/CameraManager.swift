////import AVFoundation
////import UIKit
////import CoreImage
////
////class CameraManager: NSObject, ObservableObject {
////    @Published var previewLayer: AVCaptureVideoPreviewLayer?
////    @Published var isPreciseMode = false
////    @Published var showPermissionAlert = false
////    @Published var detectedColor: String = "No color detected"
////    
////    private var session: AVCaptureSession?
////    private var colorCallback: ((String) -> Void)?
////    private var lastProcessedTime: TimeInterval = 0
////    private let minimumProcessingInterval: TimeInterval = 0.5
////    
////    override init() {
////        super.init()
////        print("CameraManager initializing...")
////        self.colorCallback = { [weak self] color in
////            print("Callback received color: \(color)")
////            self?.detectedColor = color
////        }
////        setupSession()
////        print("CameraManager initialized with callback")
////        
////        // Observe device orientation changes
////        NotificationCenter.default.addObserver(
////            self,
////            selector: #selector(handleDeviceOrientationChange),
////            name: UIDevice.orientationDidChangeNotification,
////            object: nil
////        )
////    }
////    
////    deinit {
////        NotificationCenter.default.removeObserver(self)
////    }
////    
////    @objc private func handleDeviceOrientationChange() {
////        guard let connection = previewLayer?.connection, connection.isVideoOrientationSupported else {
////            print("Preview layer connection does not support orientation changes")
////            return
////        }
////        
////        let currentOrientation = UIDevice.current.orientation
////        print("Device orientation changed: \(currentOrientation.rawValue)")
////        
////        // Update video orientation based on the current device orientation
////        switch currentOrientation {
////        case .portrait:
////            connection.videoOrientation = .portrait
////        case .landscapeLeft:
////            connection.videoOrientation = .landscapeRight // Camera orientation is reversed
////        case .landscapeRight:
////            connection.videoOrientation = .landscapeLeft // Camera orientation is reversed
////        case .portraitUpsideDown:
////            connection.videoOrientation = .portraitUpsideDown
////        default:
////            break // Ignore unknown or flat orientations
////        }
////        
////        // Update the preview layer's frame to fit the screen
////        DispatchQueue.main.async {
////            if let window = UIApplication.shared.windows.first {
////                self.previewLayer?.frame = window.bounds
////            }
////        }
////    }
////    
////    func togglePreciseMode() {
////        isPreciseMode.toggle()
////        print("Precise mode: \(isPreciseMode)")
////    }
////    
////    private func setupSession() {
////        let session = AVCaptureSession()
////        self.session = session
////        
////        // Configure the session
////        session.beginConfiguration()
////        
////        // Add video input
////        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
////              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
////            print("Failed to set up video input")
////            return
////        }
////        
////        if session.canAddInput(videoInput) {
////            session.addInput(videoInput)
////            print("Added video input")
////        }
////        
////        // Add video output
////        let videoOutput = AVCaptureVideoDataOutput()
////        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
////        if session.canAddOutput(videoOutput) {
////            session.addOutput(videoOutput)
////            print("Added video output")
////        }
////        
////        session.commitConfiguration()
////        print("Session configuration committed")
////        
////        // Create preview layer immediately
////        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
////        previewLayer.videoGravity = .resizeAspectFill
////        
////        DispatchQueue.main.async {
////            self.previewLayer = previewLayer
////            print("Preview layer created and assigned")
////        }
////    }
////    
////    func startSession() {
////        print("Starting camera session...")
////        guard let session = session else { return }
////        
////        DispatchQueue.global(qos: .userInitiated).async {
////            if !session.isRunning {
////                session.startRunning()
////                print("Camera session started running")
////            }
////        }
////    }
////    
////    func stopSession() {
////        print("Stopping camera session...")
////        session?.stopRunning()
////    }
////    
////    func startColorDetection(callback: @escaping (String) -> Void) {
////        print("Starting color detection")
////        self.colorCallback = callback
////    }
////}
////
////extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
////    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
////        let currentTime = CACurrentMediaTime()
////        guard currentTime - lastProcessedTime >= minimumProcessingInterval else { return }
////        lastProcessedTime = currentTime
////        
////        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
////        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
////        let context = CIContext()
////        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
////        let uiImage = UIImage(cgImage: cgImage)
////        
////        DispatchQueue.global(qos: .userInitiated).async {
////            let processedColor = self.processImage(uiImage)
////            DispatchQueue.main.async {
////                self.colorCallback?(processedColor)
////            }
////        }
////    }
////    
////    private func processImage(_ uiImage: UIImage) -> String {
////        guard let pixelData = uiImage.cgImage?.dataProvider?.data else {
////            return "Unknown Color"
////        }
////        
////        guard let data = CFDataGetBytePtr(pixelData) else {
////            return "Unknown Color"
////        }
////        
////        var red = Int(data[0])
////        var green = Int(data[1])
////        var blue = Int(data[2])
////        
////        if isPreciseMode {
////            print("Precise Mode: Processing center pixel color")
////        } else {
////            print("General Mode: Using full frame")
////        }
////        
////        let hex = String(format: "#%02X%02X%02X", red, green, blue)
////               print("RGB Values: R:\(red) G:\(green) B:\(blue)")
////       
////               do {
////                   let prediction = try ColorDetector.model.prediction(red: Int64(red), green: Int64(green), blue: Int64(blue))
////                   let databaseColor = ColorDatabase.findClosestHexColor(to: hex) ?? "Analyzing..."
////                   return "\(databaseColor) (\(prediction.label))"
////               } catch {
////                   print("ML Prediction error: \(error)")
////                   return "Unknown Color"
////               }
////           }
////       
////           private func averageRGB(from data: UnsafePointer<UInt8>, rect: CGRect, width: Int) -> (Int, Int, Int) {
////               var totalRed = 0, totalGreen = 0, totalBlue = 0
////               let pixelCount = Int(rect.width) * Int(rect.height)
////       
////               for y in Int(rect.origin.y)..<Int(rect.origin.y + rect.height) {
////                   for x in Int(rect.origin.x)..<Int(rect.origin.x + rect.width) {
////                       let pixelIndex = (y * width + x) * 4  // RGBA data
////                       totalRed += Int(data[pixelIndex])
////                       totalGreen += Int(data[pixelIndex + 1])
////                       totalBlue += Int(data[pixelIndex + 2])
////                   }
////               }
////       
////               return (totalRed / pixelCount, totalGreen / pixelCount, totalBlue / pixelCount)
////    }
////}
////
//
//
//
//
//import AVFoundation
//import UIKit
//import CoreImage
//
//class CameraManager: NSObject, ObservableObject {
//    @Published var previewLayer: AVCaptureVideoPreviewLayer?
//    @Published var isPreciseMode = false
//    @Published var showPermissionAlert = false
//    @Published var detectedColor: String = "No color detected"
//    
//    private var session: AVCaptureSession?
//    private var colorCallback: ((String) -> Void)?
//    private var lastProcessedTime: TimeInterval = 0
//    private let minimumProcessingInterval: TimeInterval = 0.5
//    
//    override init() {
//        super.init()
//        print("CameraManager initializing...")
//        self.colorCallback = { [weak self] color in
//            print("Callback received color: \(color)")
//            self?.detectedColor = color
//        }
//        setupSession()
//        print("CameraManager initialized with callback")
//    }
//    
//    func togglePreciseMode() {
//        isPreciseMode.toggle()
//        print("Precise mode: \(isPreciseMode)")
//    }
//    
//    private func setupSession() {
//        let session = AVCaptureSession()
//        self.session = session
//        
//        // Configure the session
//        session.beginConfiguration()
//        
//        // Add video input
//        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
//              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
//            print("Failed to set up video input")
//            return
//        }
//        
//        if session.canAddInput(videoInput) {
//            session.addInput(videoInput)
//            print("Added video input")
//        }
//        
//        // Add video output
//        let videoOutput = AVCaptureVideoDataOutput()
//        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
//        if session.canAddOutput(videoOutput) {
//            session.addOutput(videoOutput)
//            print("Added video output")
//        }
//        
//        session.commitConfiguration()
//        print("Session configuration committed")
//        
//        // Create preview layer immediately
//        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
//        previewLayer.videoGravity = .resizeAspectFill
//        
//        // Set the orientation of the preview layer
//        if let connection = previewLayer.connection {
//            connection.videoOrientation = .portrait
//        }
//        
//        DispatchQueue.main.async {
//            self.previewLayer = previewLayer
//            print("Preview layer created and assigned")
//        }
//    }
//    
//    func startSession() {
//        print("Starting camera session...")
//        guard let session = session else { return }
//        
//        DispatchQueue.global(qos: .userInitiated).async {
//            if !session.isRunning {
//                session.startRunning()
//                print("Camera session started running")
//            }
//        }
//    }
//    
//    func stopSession() {
//        print("Stopping camera session...")
//        session?.stopRunning()
//    }
//    
//    func startColorDetection(callback: @escaping (String) -> Void) {
//        print("Starting color detection")
//        self.colorCallback = callback
//    }
//}
//
//extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        let currentTime = CACurrentMediaTime()
//        guard currentTime - lastProcessedTime >= minimumProcessingInterval else { return }
//        lastProcessedTime = currentTime
//        
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
//        let context = CIContext()
//        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
//        let uiImage = UIImage(cgImage: cgImage)
//        
//        DispatchQueue.global(qos: .userInitiated).async {
//            let processedColor = self.processImage(uiImage)
//            DispatchQueue.main.async {
//                self.colorCallback?(processedColor)
//            }
//        }
//    }
//    
//    private func processImage(_ uiImage: UIImage) -> String {
//        guard let pixelData = uiImage.cgImage?.dataProvider?.data else {
//            return "Unknown Color"
//        }
//        
//        // Get a pointer to the raw data of the image (RGBA values)
//        guard let data = CFDataGetBytePtr(pixelData) else {
//            return "Unknown Color"
//        }
//        
//        var red = Int(data[0])
//        var green = Int(data[1])
//        var blue = Int(data[2])
//        
//        if isPreciseMode {
//            print("Precise Mode: Processing center pixel color")
//            
//            // Get color from a smaller center area, averaging RGB values
//            let centerX = uiImage.cgImage!.width / 2
//            let centerY = uiImage.cgImage!.height / 2
//            let squareSize = 10  // Reduced for more precision
//            
//            // Bounds check for sampling rectangle
//            let maxX = min(uiImage.cgImage!.width, centerX + squareSize / 2)
//            let maxY = min(uiImage.cgImage!.height, centerY + squareSize / 2)
//            
//            let samplingRect = CGRect(
//                x: max(0, centerX - squareSize / 2),
//                y: max(0, centerY - squareSize / 2),
//                width: min(squareSize, uiImage.cgImage!.width - centerX + squareSize / 2),
//                height: min(squareSize, uiImage.cgImage!.height - centerY + squareSize / 2)
//            )
//            
//            // Average RGB values over the rectangle
//            (red, green, blue) = averageRGB(from: data, rect: samplingRect, width: uiImage.cgImage!.width)
//        } else {
//            print("General Mode: Using full frame")
//        }
//        
//        let hex = String(format: "#%02X%02X%02X", red, green, blue)
//        print("RGB Values: R:\(red) G:\(green) B:\(blue)")
//        
//        do {
//            let prediction = try ColorDetector.model.prediction(red: Int64(red), green: Int64(green), blue: Int64(blue))
//            let databaseColor = ColorDatabase.findClosestHexColor(to: hex) ?? "Analyzing..."
//            return "\(databaseColor) (\(prediction.label))"
//        } catch {
//            print("ML Prediction error: \(error)")
//            return "Unknown Color"
//        }
//    }
//
//    private func averageRGB(from data: UnsafePointer<UInt8>, rect: CGRect, width: Int) -> (Int, Int, Int) {
//        var totalRed = 0, totalGreen = 0, totalBlue = 0
//        let pixelCount = Int(rect.width) * Int(rect.height)
//        
//        for y in Int(rect.origin.y)..<Int(rect.origin.y + rect.height) {
//            for x in Int(rect.origin.x)..<Int(rect.origin.x + rect.width) {
//                let pixelIndex = (y * width + x) * 4  // RGBA data
//                totalRed += Int(data[pixelIndex])
//                totalGreen += Int(data[pixelIndex + 1])
//                totalBlue += Int(data[pixelIndex + 2])
//            }
//        }
//        
//        return (totalRed / pixelCount, totalGreen / pixelCount, totalBlue / pixelCount)
//    }
//
//}
import AVFoundation
import UIKit
import CoreImage

class CameraManager: NSObject, ObservableObject {
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var isPreciseMode = false
    @Published var showPermissionAlert = false
    @Published var detectedColor: String = "No color detected"
    
    private var session: AVCaptureSession?
    private var colorCallback: ((String) -> Void)?
    private var lastProcessedTime: TimeInterval = 0
    private let minimumProcessingInterval: TimeInterval = 0.5
    
    override init() {
        super.init()
        print("CameraManager initializing...")
        self.colorCallback = { [weak self] color in
            print("Callback received color: \(color)")
            self?.detectedColor = color
        }
        setupSession()
        print("CameraManager initialized with callback")
        
        // Observe device orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleDeviceOrientationChange() {
        guard let connection = previewLayer?.connection, connection.isVideoOrientationSupported else {
            print("Preview layer connection does not support orientation changes")
            return
        }
        
        let currentOrientation = UIDevice.current.orientation
        print("Device orientation changed: \(currentOrientation.rawValue)")
        
        // Update video orientation based on the current device orientation
        switch currentOrientation {
        case .portrait:
            connection.videoOrientation = .portrait
        case .landscapeLeft:
            connection.videoOrientation = .landscapeRight // Camera orientation is reversed
        case .landscapeRight:
            connection.videoOrientation = .landscapeLeft // Camera orientation is reversed
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        default:
            break // Ignore unknown or flat orientations
        }
        
        // Update the preview layer's frame to fit the screen
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first {
                self.previewLayer?.frame = window.bounds
            }
        }
    }
    
    func togglePreciseMode() {
        isPreciseMode.toggle()
        print("Precise mode: \(isPreciseMode)")
    }
    
    private func setupSession() {
        let session = AVCaptureSession()
        self.session = session
        
        // Configure the session
        session.beginConfiguration()
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("Failed to set up video input")
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
            print("Added video input")
        }
        
        // Add video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            print("Added video output")
        }
        
        session.commitConfiguration()
        print("Session configuration committed")
        
        // Create preview layer immediately
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        DispatchQueue.main.async {
            self.previewLayer = previewLayer
            print("Preview layer created and assigned")
        }
    }
    
    func startSession() {
        print("Starting camera session...")
        guard let session = session else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if !session.isRunning {
                session.startRunning()
                print("Camera session started running")
            }
        }
    }
    
    func stopSession() {
        print("Stopping camera session...")
        session?.stopRunning()
    }
    
    func startColorDetection(callback: @escaping (String) -> Void) {
        print("Starting color detection")
        self.colorCallback = callback
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastProcessedTime >= minimumProcessingInterval else { return }
        lastProcessedTime = currentTime
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let processedColor = self.processImage(uiImage)
            DispatchQueue.main.async {
                self.colorCallback?(processedColor)
            }
        }
    }
    
    private func processImage(_ uiImage: UIImage) -> String {
        guard let pixelData = uiImage.cgImage?.dataProvider?.data else {
            return "Unknown Color"
        }
        
        // Get a pointer to the raw data of the image (RGBA values)
        guard let data = CFDataGetBytePtr(pixelData) else {
            return "Unknown Color"
        }
        
        var red = Int(data[0])
        var green = Int(data[1])
        var blue = Int(data[2])
        
        if isPreciseMode {
            print("Precise Mode: Processing center pixel color")
            
            // Get color from a smaller center area, averaging RGB values
            let centerX = uiImage.cgImage!.width / 2
            let centerY = uiImage.cgImage!.height / 2
            let squareSize = 10  // Reduced for more precision
            
            // Bounds check for sampling rectangle
            let maxX = min(uiImage.cgImage!.width, centerX + squareSize / 2)
            let maxY = min(uiImage.cgImage!.height, centerY + squareSize / 2)
            
            let samplingRect = CGRect(
                x: max(0, centerX - squareSize / 2),
                y: max(0, centerY - squareSize / 2),
                width: min(squareSize, uiImage.cgImage!.width - centerX + squareSize / 2),
                height: min(squareSize, uiImage.cgImage!.height - centerY + squareSize / 2)
            )
            
            // Average RGB values over the rectangle
            (red, green, blue) = averageRGB(from: data, rect: samplingRect, width: uiImage.cgImage!.width)
        } else {
            print("General Mode: Using full frame")
        }
        
        let hex = String(format: "#%02X%02X%02X", red, green, blue)
        print("RGB Values: R:\(red) G:\(green) B:\(blue)")
        
        do {
            let prediction = try ColorDetector.model.prediction(red: Int64(red), green: Int64(green), blue: Int64(blue))
            let databaseColor = ColorDatabase.findClosestHexColor(to: hex) ?? "Analyzing..."
            return "\(databaseColor) (\(prediction.label))"
        } catch {
            print("ML Prediction error: \(error)")
            return "Unknown Color"
        }
    }

    private func averageRGB(from data: UnsafePointer<UInt8>, rect: CGRect, width: Int) -> (Int, Int, Int) {
        var totalRed = 0, totalGreen = 0, totalBlue = 0
        let pixelCount = Int(rect.width) * Int(rect.height)
        
        for y in Int(rect.origin.y)..<Int(rect.origin.y + rect.height) {
            for x in Int(rect.origin.x)..<Int(rect.origin.x + rect.width) {
                let pixelIndex = (y * width + x) * 4  // RGBA data
                totalRed += Int(data[pixelIndex])
                totalGreen += Int(data[pixelIndex + 1])
                totalBlue += Int(data[pixelIndex + 2])
            }
        }
        
        return (totalRed / pixelCount, totalGreen / pixelCount, totalBlue / pixelCount)
    }

}
