import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var showingPhotoPicker = false
    @State private var selectedImage: UIImage?
    @State private var detectedColor: String = "No color detected"
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showingColorPicker = false
    @StateObject private var cameraManager = CameraManager()
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                //            ZStack {
                // Camera View
                if !showingColorPicker {  // Only show camera when color picker is not active
                    CameraView()
                        .environmentObject(cameraManager)
                }
                
                // Toast View
                if showToast {
                    ToastView(message: toastMessage)
                        .transition(.move(edge: .top))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showToast = false
                                }
                            }
                        }
                }
                
                if cameraManager.isPreciseMode {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
                // Bottom-left Photo Frame Button
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            showingPhotoPicker.toggle()
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding(.leading, 30)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            cameraManager.togglePreciseMode()
                        }) {
                            Image(systemName: cameraManager.isPreciseMode ? "viewfinder.circle.fill" : "viewfinder.circle")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding(.trailing, 30)
                        }
                    }
                }
                             // Centered Detected Color VStack
                VStack {
                    Text(cameraManager.detectedColor)
                        .foregroundColor(.white)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(18)
                        .padding(.top, 40) // Add padding to avoid the notch area
                        .padding(.horizontal, 16) // Add horizontal padding
                    Spacer()
                }
                
                Spacer() // Center-aligns VStack
                //                }
                //            }
                    .sheet(isPresented: $showingPhotoPicker) {
                        PhotoPicker(image: $selectedImage)
                    }
                    .onChange(of: selectedImage) { newImage in
                        if let image = newImage {
                            //                    analyzeImage(image)
                            showingColorPicker = true
                            cameraManager.stopSession() // Stop camera when showing color picker
                        }
                    }
                    .fullScreenCover(isPresented: $showingColorPicker) {
                        if let image = selectedImage {
                            ColorPickerView(image: image, showingPhotoPicker: $showingPhotoPicker, onDismiss: {
                                cameraManager.startSession() // Resume camera when "Done" is pressed
                            })
                        }
                    }
            }
        }
    }
    

    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation {
            showToast = true
        }
    }
}

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding(.top)
    }
}

#Preview {
    ContentView()
}
