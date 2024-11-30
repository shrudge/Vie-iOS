import UIKit

struct BasicColor {
    let name: String
    let rgb: (r: Int, g: Int, b: Int)
    
    func colorDistance(to color: BasicColor) -> Double {
        let dr = Double(self.rgb.r - color.rgb.r)
        let dg = Double(self.rgb.g - color.rgb.g)
        let db = Double(self.rgb.b - color.rgb.b)
        return sqrt(dr * dr + dg * dg + db * db)
    }
}

struct BasicColors {
    static let colors: [BasicColor] = [
        BasicColor(name: "Black", rgb: (0, 0, 0)),
        BasicColor(name: "White", rgb: (255, 255, 255)),
        BasicColor(name: "Red", rgb: (255, 0, 0)),
        BasicColor(name: "Green", rgb: (0, 255, 0)),
        BasicColor(name: "Blue", rgb: (0, 0, 255)),
        BasicColor(name: "Yellow", rgb: (255, 255, 0)),
        BasicColor(name: "Orange", rgb: (255, 165, 0)),
        BasicColor(name: "Purple", rgb: (128, 0, 128)),
        BasicColor(name: "Brown", rgb: (139, 69, 19)),
        BasicColor(name: "Pink", rgb: (255, 192, 203)),
        BasicColor(name: "Gray", rgb: (169, 169, 169)),
    ]
    
    static func getClosestColor(fromHex hex: String) -> String {
        let r, g, b: Int
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 1 // Skip the '#'
        var hexNumber: UInt64 = 0
        if scanner.scanHexInt64(&hexNumber) {
            r = Int((hexNumber & 0xFF0000) >> 16)
            g = Int((hexNumber & 0x00FF00) >> 8)
            b = Int(hexNumber & 0x0000FF)
        } else {
            return "Unknown"
        }
        
        let inputColor = BasicColor(name: "Input", rgb: (r, g, b))
        
        let closestColor = colors.min { a, b in
            inputColor.colorDistance(to: a) < inputColor.colorDistance(to: b)
        }
        
        return closestColor?.name ?? "Unknown"
    }
} 