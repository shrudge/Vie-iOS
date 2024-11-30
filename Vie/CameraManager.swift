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
        setupSession()
    }
    
    private func setupSession() {
        checkPermission { [weak self] granted in
            if granted {
                self?.configureSession()
            } else {
                DispatchQueue.main.async {
                    self?.showPermissionAlert = true
                }
            }
        }
    }
    
    private func checkPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        default:
            completion(false)
        }
    }
    
    private func configureSession() {
        let session = AVCaptureSession()
        self.session = session
        
        // Configure the session
        session.beginConfiguration()
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            print("Failed to set up video input")
            return
        }
        session.addInput(videoInput)
        print("Added video input")
        
        // Add video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            print("Added video output")
        }
        
        session.commitConfiguration()
        print("Session configuration committed")
        
        // Create and set preview layer on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.connection?.videoOrientation = .portrait
            self.previewLayer = previewLayer
            print("Preview layer created and assigned")
            
            // Start the session
            DispatchQueue.global(qos: .userInitiated).async {
                if !session.isRunning {
                    session.startRunning()
                    print("Camera session started running")
                }
            }
        }
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session?.startRunning()
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session?.stopRunning()
        }
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
        
        // Different color detection based on mode
        let hex: String
        if isPreciseMode {
            // Get color only from center square area (100x100 pixels)
            let centerX = cgImage.width / 2
            let centerY = cgImage.height / 2
            let squareSize: Int = 100
            
            let cropRect = CGRect(
                x: centerX - squareSize/2,
                y: centerY - squareSize/2,
                width: squareSize,
                height: squareSize
            )
            
            if let croppedCGImage = cgImage.cropping(to: cropRect) {
                let croppedImage = UIImage(cgImage: croppedCGImage)
                hex = DominantColor.findDominantColor(in: croppedImage)
            } else {
                hex = DominantColor.findDominantColor(in: uiImage)
            }
        } else {
            // Use entire frame for dominant color
            hex = DominantColor.findDominantColor(in: uiImage)
        }
        
//        print("Detected color hex: \(hex)")
        
        // Rest of your color API and callback code...
        let urlString = "https://www.thecolorapi.com/id?hex=\(hex.dropFirst())"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let callback = self?.colorCallback else { return }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ColorAPIResponse.self, from: data)
//                print("API Response: \(response.name.value)")
                
                let rgb = RGB(r: response.rgb.r, g: response.rgb.g, b: response.rgb.b)
                let hsl = HSL(h: Double(response.hsl.h), s: Double(response.hsl.s)/100.0, l: Double(response.hsl.l)/100.0)
                
                let colorData = ColorData(
                    name: response.name.value,
                    hex: hex,
                    rgb: rgb,
                    hsl: hsl,
                    cmyk: CMYK(c: 0, m: 0, y: 0, k: 0)
                )
                
                let family = ColorFamilies.categorizeColor(colorData)
//                print("Color family: \(family)")
                
                DispatchQueue.main.async {
                    callback("\(response.name.value) (\(family))")
                }
            } catch {
                print("Error decoding color: \(error)")
            }
        }.resume()
    }
} 
