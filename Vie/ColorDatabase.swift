import Foundation

struct RGB: Codable {
    let r: Int
    let g: Int
    let b: Int
}

struct HSL: Codable {
    let h: Double
    let s: Double
    let l: Double
}

struct CMYK: Codable {
    let c: Double
    let m: Double
    let y: Double
    let k: Double
}

struct ColorData: Codable {
    let name: String
    let hex: String
    let rgb: RGB
    let hsl: HSL
    let cmyk: CMYK
}

struct ColorDatabase {
    static var colors: [ColorData] = []
    
    static func loadColors(from jsonFile: String) {
        if let url = Bundle.main.url(forResource: jsonFile, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                colors = try JSONDecoder().decode([ColorData].self, from: data)
            } catch {
                print("Error loading colors: \(error)")
            }
        }
    }
    
    static func findClosestColor(to hex: String) -> ColorData? {
        let inputRGB = hexToRGB(hex)
        return colors.min { color1, color2 in
            colorDistance(from: inputRGB, to: color1.rgb) < colorDistance(from: inputRGB, to: color2.rgb)
        }
    }
    
    private static func hexToRGB(_ hex: String) -> RGB {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgbValue)
        
        return RGB(
            r: Int((rgbValue & 0xFF0000) >> 16),
            g: Int((rgbValue & 0x00FF00) >> 8),
            b: Int(rgbValue & 0x0000FF)
        )
    }
    
    private static func colorDistance(from rgb1: RGB, to rgb2: RGB) -> Double {
        let rMean = Double(rgb1.r + rgb2.r) / 2.0
        let r = Double(rgb1.r - rgb2.r)
        let g = Double(rgb1.g - rgb2.g)
        let b = Double(rgb1.b - rgb2.b)
        
        let weightR = 2.0 + rMean/256.0
        let weightG = 4.0
        let weightB = 2.0 + (255.0-rMean)/256.0
        
        return sqrt(weightR*r*r + weightG*g*g + weightB*b*b)
    }
    
    static func getColorsByFamily() -> [String: [ColorData]] {
        var familyGroups: [String: [ColorData]] = [:]
        
        for color in colors {
            let family = ColorFamilies.categorizeColor(color)
            if familyGroups[family] == nil {
                familyGroups[family] = []
            }
            familyGroups[family]?.append(color)
        }
        
        return familyGroups
    }
} 