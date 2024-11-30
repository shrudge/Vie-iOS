import UIKit

struct DominantColor {
    static func findDominantColor(in image: UIImage) -> String {
        guard let inputImage = CIImage(image: image) else { return "#000000" }
        
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                  y: inputImage.extent.origin.y,
                                  z: inputImage.extent.size.width,
                                  w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage",
                                  parameters: [kCIInputImageKey: inputImage,
                                             kCIInputExtentKey: extentVector]) else { return "#000000" }
        
        guard let outputImage = filter.outputImage else { return "#000000" }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: nil)
        
        let hex = String(format: "#%02x%02x%02x",
                        bitmap[0],
                        bitmap[1],
                        bitmap[2])
        
        return hex
    }
} 