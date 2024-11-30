import UIKit
import CoreImage
import Vision

class ColorDetector {
    static func detectDominantColor(in image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("Unable to process image")
            return
        }
        
        // Create CIImage for processing
        let ciImage = CIImage(cgImage: cgImage)
        
        // Create a small square area in the center of the image
        let extent = ciImage.extent
        let centerSquare = CGRect(
            x: extent.midX - 50,
            y: extent.midY - 50,
            width: 100,
            height: 100
        )
        
        // Create context and process image
        let context = CIContext()
        guard let centerPixels = context.createCGImage(ciImage, from: centerSquare) else {
            completion("Unable to process image")
            return
        }
        
        // Create UIImage from center pixels
        let centerImage = UIImage(cgImage: centerPixels)
        
        // Get average color
        guard let averageColor = centerImage.averageColor else {
            completion("Unable to determine color")
            return
        }
        
        // Get color name
        let colorName = nameForColor(averageColor)
        completion(colorName)
    }
    
    static func nameForColor(_ color: UIColor) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let threshold: CGFloat = 0.4
        
        if max(red, green, blue) < threshold {
            return "Black"
        }
        
        if min(red, green, blue) > 0.8 {
            return "White"
        }
        
        if red > threshold && green < threshold && blue < threshold {
            return "Red"
        }
        
        if green > threshold && red < threshold && blue < threshold {
            return "Green"
        }
        
        if blue > threshold && red < threshold && green < threshold {
            return "Blue"
        }
        
        if red > threshold && green > threshold && blue < threshold {
            return "Yellow"
        }
        
        if red > threshold && blue > threshold && green < threshold {
            return "Purple"
        }
        
        if green > threshold && blue > threshold && red < threshold {
            return "Cyan"
        }
        
        if red > threshold && green > threshold * 0.7 && blue < threshold {
            return "Orange"
        }
        
        if red > threshold * 0.7 && green < threshold && blue > threshold {
            return "Pink"
        }
        
        if red > threshold * 0.5 && green > threshold * 0.3 && blue < threshold {
            return "Brown"
        }
        
        if red > threshold * 0.5 && green > threshold * 0.5 && blue > threshold * 0.5 {
            return "Grey"
        }
        
        return "Unknown"
    }
}

// Add extension for UIImage to calculate average color
extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                  y: inputImage.extent.origin.y,
                                  z: inputImage.extent.size.width,
                                  w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage",
                                  parameters: [kCIInputImageKey: inputImage,
                                             kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255,
                      green: CGFloat(bitmap[1]) / 255,
                      blue: CGFloat(bitmap[2]) / 255,
                      alpha: CGFloat(bitmap[3]) / 255)
    }
} 