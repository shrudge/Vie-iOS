import UIKit
import CoreImage
import Vision
import CoreML

class ColorDetector {
    static let model: Vie2model = {
        do {
            let config = MLModelConfiguration()
            return try Vie2model(configuration: config)
        } catch {
            fatalError("Couldn't create Vie2model: \(error)")
        }
    }()
    
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
        
        // Get RGB values
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        averageColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Convert to Int64 for model input
        let redInt = Int64(red * 255)
        let greenInt = Int64(green * 255)
        let blueInt = Int64(blue * 255)
        
        // Use CoreML model to predict color
        do {
            let prediction = try model.prediction(
                red: redInt,
                green: greenInt,
                blue: blueInt
            )
            completion(prediction.label)
        } catch {
            print("Prediction error: \(error)")
            completion("Error predicting color")
        }
        
    }
    
}


// Keep the UIImage extension for average color calculation
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

