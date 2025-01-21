import Foundation

struct ColorDatabase {
    static var colorMap: [String: ColorData] = [:]
    
    static func loadColors(from jsonFile: String) {
        if let url = Bundle.main.url(forResource: jsonFile, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let colorsWrapper = try JSONDecoder().decode(ColorsWrapper.self, from: data)
                colorMap = Dictionary(uniqueKeysWithValues: colorsWrapper.colors.map { color in
                    (color.hex, color)
                })
                print("Loaded \(colorMap.count) colors")
            } catch {
                print("Error loading colors: \(error)")
            }
        }
    }
    
    static func findClosestHexColor(to inputHex: String) -> String? {
        print("Finding closest color for hex: \(inputHex)")
        var closestColor: String? = nil
        var minDistance: Double = Double.infinity
        
        let inputRGB = hexToRGB(inputHex)
        
        for (_, color) in colorMap {
            let colorRGB = hexToRGB(color.hex)
            let distance = colorDistance(from: inputRGB, to: colorRGB)
            
            if distance < minDistance {
                minDistance = distance
                closestColor = color.name
                print("New closest color: \(color.name) with distance: \(distance)")
            }
        }
        
        return closestColor
    }
    
    private static func colorDistance(from rgb1: (r: Int, g: Int, b: Int), to rgb2: (r: Int, g: Int, b: Int)) -> Double {
        let rMean = Double(rgb1.r + rgb2.r) / 2.0
        let r = Double(rgb1.r - rgb2.r)
        let g = Double(rgb1.g - rgb2.g)
        let b = Double(rgb1.b - rgb2.b)
        
        let weightR = 2.0 + rMean/256.0
        let weightG = 4.0
        let weightB = 2.0 + (255.0-rMean)/256.0
        
        return sqrt(weightR*r*r + weightG*g*g + weightB*b*b)
    }
    
    static func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        return (
            r: Int((rgb & 0xFF0000) >> 16),
            g: Int((rgb & 0x00FF00) >> 8),
            b: Int(rgb & 0x0000FF)
        )
    }
} 

