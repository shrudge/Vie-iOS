import SwiftUI

struct ColorPickerView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    @Binding var showingPhotoPicker: Bool
    var onDismiss: () -> Void
    @State private var selectedColor: String = "No color detected"
    @State private var circlePosition: CGPoint = .zero
    @State private var isDragging = false
    
    private let circleSize: CGFloat = 40
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation Bar with Back and Done buttons
                HStack {
                    Button(action: {
                        // This will return to photo picker
                        presentationMode.wrappedValue.dismiss()
                        showingPhotoPicker = true
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                        onDismiss()
                    }
                    .padding()
                }
                
                // Image with movable circle
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: geometry.size.height * 0.7)
                        .onAppear {
                            // Set initial circle position to center
                            circlePosition = CGPoint(
                                x: geometry.size.width / 2,
                                y: geometry.size.height * 0.35
                            )
                            updateSelectedColor(at: circlePosition, in: image)
                        }
                    
                    // Movable circle
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: circleSize, height: circleSize)
                        .background(Circle().fill(Color.black.opacity(0.2)))
                        .position(circlePosition)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    circlePosition = value.location
                                    updateSelectedColor(at: value.location, in: image)
                                }
                        )
                }
                
                Spacer()
                
                // Color display at bottom
                Text(selectedColor)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .padding(.bottom)
            }
        }
        .background(Color.black)
//        .edgesIgnoringSafeArea(.all)
    }
    
    private func updateSelectedColor(at position: CGPoint, in image: UIImage) {
        // Convert position to image coordinates
        guard let cgImage = image.cgImage else { return }
        
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let scaledPosition = CGPoint(
            x: (position.x / UIScreen.main.bounds.width) * CGFloat(imageSize.width),
            y: (position.y / UIScreen.main.bounds.height) * CGFloat(imageSize.height)
        )
        
        // Reduced square size to 20
        let squareSize: Int = 20
        let cropRect = CGRect(
            x: Int(scaledPosition.x) - squareSize/2,
            y: Int(scaledPosition.y) - squareSize/2,
            width: squareSize,
            height: squareSize
        ).intersection(CGRect(origin: .zero, size: imageSize))
        
        if let croppedCGImage = cgImage.cropping(to: cropRect) {
            let croppedImage = UIImage(cgImage: croppedCGImage)
            let hex = DominantColor.findDominantColor(in: croppedImage)
            
            // Get color name from API
            let urlString = "https://www.thecolorapi.com/id?hex=\(hex.dropFirst())"
            guard let url = URL(string: urlString) else { return }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data else { return }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ColorAPIResponse.self, from: data)
                    
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
                    
                    DispatchQueue.main.async {
                        selectedColor = "\(response.name.value) (\(family))"
                    }
                } catch {
                    print("Error decoding color: \(error)")
                }
            }.resume()
        }
    }
} 





struct ColorPickerView_Previews: PreviewProvider {
    @State static private var showingPhotoPicker = false

    static var previews: some View {
        // Mock UIImage for preview purposes
        let mockImage = UIImage(systemName: "photo") ?? UIImage()

        ColorPickerView(
            image: mockImage,
            showingPhotoPicker: $showingPhotoPicker,
            onDismiss: {
                print("Dismissed")
            }
        )
    }
}

