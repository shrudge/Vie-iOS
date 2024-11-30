import Foundation

struct ColorFamily {
    let name: String
    let colors: [ColorData]
}

struct ColorFamilies {
    static let families = [
        "Aqua",
        "Beige",
        "Black",
        "Blue",
        "Brown",
        "Chartreuse",
        "Fuchsia",
        "Gold",
        "Gray",
        "Green",
        "Lilac",
        "Lime",
        "Maroon",
        "Navy",
        "Ochre",
        "Olive",
        "Orange",
        "Pink",
        "Purple",
        "Red",
        "Silver",
        "Teal",
        "Turquoise",
        "Violet",
        "White",
        "Yellow"
    ]
    
    static func categorizeColor(_ color: ColorData) -> String {
        let hsl = color.hsl
        let rgb = color.rgb
        
        // Improved categorization logic using both HSL and RGB values
        
        // Check for grayscale colors first
        if hsl.s < 0.12 {
            if hsl.l < 0.15 { return "Black" }
            if hsl.l > 0.85 { return "White" }
            return "Gray"
        }
        
        // Use HSL for main color categorization
        let hue = hsl.h
        let sat = hsl.s
        let light = hsl.l
        
        // Special cases for certain colors
        if light < 0.15 { return "Black" }
        if light > 0.85 && sat < 0.15 { return "White" }
        
        // Beige detection
        if (hue >= 20 && hue <= 50) && sat <= 0.35 && light > 0.75 {
            return "Beige"
        }
        
        // Gold detection
        if (hue >= 35 && hue <= 45) && sat >= 0.75 && light >= 0.4 && light <= 0.6 {
            return "Gold"
        }
        
        // Main color wheel categorization
        switch hue {
        case 0..<15, 345..<360:
            return light < 0.4 ? "Maroon" : "Red"
            
        case 15..<45:
            if light < 0.4 { return "Brown" }
            if sat > 0.8 { return "Orange" }
            return "Ochre"
            
        case 45..<70:
            return "Yellow"
            
        case 70..<80:
            return "Chartreuse"
            
        case 80..<150:
            if light < 0.3 { return "Olive" }
            return "Green"
            
        case 150..<180:
            return "Teal"
            
        case 180..<200:
            return "Aqua"
            
        case 200..<220:
            return "Turquoise"
            
        case 220..<240:
            if light < 0.3 { return "Navy" }
            return "Blue"
            
        case 240..<260:
            return "Purple"
            
        case 260..<280:
            return "Violet"
            
        case 280..<290:
            return light > 0.8 ? "Lilac" : "Purple"
            
        case 290..<327:
            if sat > 0.7 && light > 0.6 { return "Fuchsia" }
            return "Purple"
            
        case 327..<345:
            return "Pink"
            
        default:
            return "Other"
        }
    }
    
    private static func rgbToHSV(r: Int, g: Int, b: Int) -> (hue: Double, saturation: Double, value: Double) {
        let rf = Double(r) / 255.0
        let gf = Double(g) / 255.0
        let bf = Double(b) / 255.0
        
        let cmax = max(rf, gf, bf)
        let cmin = min(rf, gf, bf)
        let delta = cmax - cmin
        
        // Calculate hue
        var hue: Double = 0
        if delta != 0 {
            if cmax == rf {
                hue = 60 * (((gf - bf) / delta).truncatingRemainder(dividingBy: 6))
            } else if cmax == gf {
                hue = 60 * (((bf - rf) / delta) + 2)
            } else {
                hue = 60 * (((rf - gf) / delta) + 4)
            }
        }
        if hue < 0 { hue += 360 }
        
        // Calculate saturation
        let saturation = cmax == 0 ? 0 : delta / cmax
        
        // Value is simply the maximum component
        let value = cmax
        
        return (hue, saturation, value)
    }
} 