import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var detectedColor: String = "No color detected"
    @State private var preciseBoxPosition: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                if let previewLayer = cameraManager.previewLayer {
                    CameraPreviewRepresentable(previewLayer: previewLayer)
                        .ignoresSafeArea()
                        .onAppear {
                            preciseBoxPosition = CGPoint(
                                x: geometry.size.width / 2,
                                y: geometry.size.height / 2
                            )
                        }
                } else {
                    Color.black
                        .ignoresSafeArea()
                        .onAppear {
                            print("Preview layer is nil")
                        }
                }
                
                // Precise mode indicator
                if cameraManager.isPreciseMode {
                    PreciseModeIndicator()
                        .position(preciseBoxPosition)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    preciseBoxPosition = value.location
                                }
                        )
                }
                
                // Color display
                VStack {
                    Spacer()
                    Text(detectedColor)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .padding(.bottom)
                }
                
                // Precise mode toggle button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            cameraManager.isPreciseMode.toggle()
                            if cameraManager.isPreciseMode {
                                preciseBoxPosition = CGPoint(
                                    x: geometry.size.width / 2,
                                    y: geometry.size.height / 2
                                )
                            }
                        }) {
                            Image(systemName: cameraManager.isPreciseMode ? "xmark" : "scope")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(.ultraThinMaterial))
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            print("CameraView appeared")
            cameraManager.startColorDetection { color in
                detectedColor = color
            }
        }
        .alert("Camera Access Required", isPresented: $cameraManager.showPermissionAlert) {
            Button("Open Settings", action: openSettings)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please grant camera access in Settings to use this feature.")
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct CameraPreviewRepresentable: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        print("Creating preview view")
        let view = UIView(frame: UIScreen.main.bounds)
        
        // Configure the preview layer
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        
        // Add preview layer to view's layer hierarchy
        view.layer.addSublayer(previewLayer)
        
        print("Preview layer added to view hierarchy")
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        print("Updating preview view frame")
        DispatchQueue.main.async {
            previewLayer.frame = uiView.bounds
        }
    }
}

#Preview {
    CameraView()
} 
