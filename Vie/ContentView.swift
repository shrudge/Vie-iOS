//
//  ContentView.swift
//  Vie
//
//  Created by Meet Balani on 30/11/24.
//

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
        NavigationView {
            ZStack {
                // Camera View
                if !showingColorPicker {  // Only show camera when color picker is not active
                    CameraView()
                        .environmentObject(cameraManager)
                }
                
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingPhotoPicker = true
                    }) {
                        Image(systemName: "photo.on.rectangle")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(image: $selectedImage)
            }   
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    analyzeImage(image)
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
    
    private func analyzeImage(_ image: UIImage) {
        let hex = DominantColor.findDominantColor(in: image)
        if let colorData = ColorDatabase.findClosestColor(to: hex) {
            detectedColor = "\(colorData.name)"
            showToastMessage("Color detected: \(colorData.name)")
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
