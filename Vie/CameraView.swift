import SwiftUI
import AVFoundation

struct CameraView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @State private var showPermissionAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                if let previewLayer = cameraManager.previewLayer {
                    CameraPreviewRepresentable(previewLayer: previewLayer)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Color.red
                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            print("Preview layer is nil")
                        }
                }
                

                
                // Controls
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            checkCameraPermission()
        }
        .alert("Camera Permission Required", isPresented: $showPermissionAlert) {
            Button("Go to Settings", action: openSettings)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please allow camera access in Settings to use this feature.")
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraManager.startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        cameraManager.startSession()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
    }
}

struct CameraPreviewRepresentable: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        print("Creating preview view")
        let view = UIView()
        view.backgroundColor = .black
        
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        print("Preview layer added to view hierarchy")
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        print("Updating preview view frame: \(uiView.frame)")
        DispatchQueue.main.async {
            previewLayer.frame = uiView.layer.bounds
            
            // Ensure the preview layer is in portrait mode
            if let connection = previewLayer.connection {
                connection.videoOrientation = .portrait // Set to portrait
            }
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(CameraManager())
} 
