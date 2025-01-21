import SwiftUI
import CoreML

struct ColorPickerView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    @Binding var showingPhotoPicker: Bool
    var onDismiss: () -> Void
    @State private var selectedColor: String = "Move to detect the color"
    @State private var mlPrediction: String = ""
    @State private var circlePosition: CGPoint = .zero
    @State private var imageFrame: CGRect = .zero // Store the actual frame of the image

    private let circleSize: CGFloat = 40
    @State private var model: Vie2model?

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation Bar with Back and Done buttons
                HStack {
                    Button(action: {
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
                let mlPredictionText = mlPrediction.isEmpty ? mlPrediction : "(\(mlPrediction))"
                Text("\(selectedColor) \(mlPredictionText)")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .padding(.bottom)

                // Image with movable circle
                ZStack {
                    Color.clear // Background to ensure the ZStack takes up full width
                    
                    GeometryReader { imageGeometry in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: geometry.size.width, // Ensure the image stays within the container width
                                height: geometry.size.height * 0.7,
                                alignment: .center
                            )
                            .onAppear {
                                DispatchQueue.main.async {
                                    // Calculate the frame of the image relative to the parent view
                                    let containerWidth = geometry.size.width
                                    let containerHeight = geometry.size.height * 0.7

                                    let imageSize = image.size
                                    let imageAspect = imageSize.width / imageSize.height
                                    let containerAspect = containerWidth / containerHeight

                                    // Determine actual rendered size of the image
                                    let renderedWidth: CGFloat
                                    let renderedHeight: CGFloat

                                    if imageAspect > containerAspect {
                                        // Image is wider than container
                                        renderedWidth = containerWidth
                                        renderedHeight = renderedWidth / imageAspect
                                    } else {
                                        // Image is taller than container
                                        renderedHeight = containerHeight
                                        renderedWidth = renderedHeight * imageAspect
                                    }

                                    // Center the image within the container
                                    let xOffset = (containerWidth - renderedWidth) / 2
                                    let yOffset = (containerHeight - renderedHeight) / 2

                                    imageFrame = CGRect(
                                        x: xOffset,
                                        y: yOffset,
                                        width: renderedWidth,
                                        height: renderedHeight
                                    )

                                    // Initialize circlePosition to the center of the image
                                    circlePosition = CGPoint(
                                        x: imageFrame.midX,
                                        y: imageFrame.midY
                                    )
                                }
                            }
                            .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35) // Center the image within the ZStack
                    }
                    .background(Color.clear) // Ensure no interference with frame calculation

                    // Movable circle
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: circleSize, height: circleSize)
                        .background(Circle().fill(Color.black.opacity(0.2)))
                        .position(circlePosition)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Restrict circle to stay within the image frame
                                    let clampedX = min(max(value.location.x, imageFrame.minX), imageFrame.maxX)
                                    let clampedY = min(max(value.location.y, imageFrame.minY), imageFrame.maxY)
                                    circlePosition = CGPoint(x: clampedX, y: clampedY)
                                    updateSelectedColor(at: circlePosition, in: image)
                                }
                        )
                }
                .frame(maxHeight: geometry.size.height * 0.7) // Set max height for image container

                Spacer()
            }.background(
                ZStack {
                    Color.black
                    .ignoresSafeArea()
                    Color.clear.background(.ultraThinMaterial)
                }
            )
        }
        .background(Color.black)
    }

    private func updateSelectedColor(at position: CGPoint, in image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let scaledPosition = CGPoint(
            x: (position.x - imageFrame.minX) / imageFrame.width * imageSize.width,
            y: (position.y - imageFrame.minY) / imageFrame.height * imageSize.height
        )

        let squareSize: Int = 10
        let cropRect = CGRect(
            x: Int(scaledPosition.x) - squareSize / 2,
            y: Int(scaledPosition.y) - squareSize / 2,
            width: squareSize,
            height: squareSize
        ).intersection(CGRect(origin: .zero, size: imageSize))

        if let croppedCGImage = cgImage.cropping(to: cropRect) {
            let croppedImage = UIImage(cgImage: croppedCGImage)
            let hex = DominantColor.findDominantColor(in: croppedImage)

            if let colorName = ColorDatabase.findClosestHexColor(to: hex) {
                DispatchQueue.main.async {
                    self.selectedColor = colorName

                    let rgb = ColorDatabase.hexToRGB(hex)
                    self.mlPrediction = MLColorDetector.shared.detectColor(
                        r: Int64(rgb.r),
                        g: Int64(rgb.g),
                        b: Int64(rgb.b)
                    )
                }
            }
        }
    }
}

struct ColorPickerView_Previews: PreviewProvider {
    @State static private var showingPhotoPicker = false

    static var previews: some View {
        // Mock UIImage for preview purposes
        let mockImage = UIImage(named: "IMG_5307") ?? UIImage()

        ColorPickerView(
            image: mockImage,
            showingPhotoPicker: $showingPhotoPicker,
            onDismiss: {
                print("Dismissed")
            }
        )
    }
}
