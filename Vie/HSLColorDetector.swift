//import UIKit
//
//struct HSLColorDetector {
//    static let colorRanges: [(name: String, hueRange: [(Int, Int)], saturationMin: Int, saturationMax: Int, lightnessMin: Int, lightnessMax: Int)] = [
//        ("Red", [(0, 20), (340, 360)], 20, 100, 20, 100),
//        ("Orange", [(20, 50)], 30, 100, 20, 100),
//        ("Yellow", [(50, 70)], 30, 100, 20, 100),
//        ("Green", [(70, 170)], 30, 100, 20, 100),
//        ("Blue", [(170, 260)], 30, 100, 20, 100),
//        ("Purple", [(260, 320)], 30, 100, 20, 100),
//        ("Pink", [(320, 340)], 30, 100, 30, 100),
//        ("Gray", [(0, 360)], 0, 15, 20, 80),
//        ("Black", [(0, 360)], 0, 100, 0, 20),
//        ("White", [(0, 360)], 0, 100, 80, 100),
//        ("Brown", [(20, 50)], 20, 100, 10, 50)
//    ]
//    
//    static func getColorNameFromHSL(hex: String) -> String {
//        let (h, s, l) = hexToHSL(hex: hex)
//        
//        for color in colorRanges {
//            for (hueMin, hueMax) in color.hueRange {
//                if hueMin <= h && h <= hueMax &&
//                    color.saturationMin <= s && s <= color.saturationMax &&
//                    color.lightnessMin <= l && l <= color.lightnessMax {
//                    return color.name
//                }
//            }
//        }
//        
//        return "Unknown Color"
//    }
//    
//    private static func hexToHSL(hex: String) -> (Int, Int, Int) {
//        let (r, g, b) = hexToRGB(hex)
//        
//        let rf = Double(r) / 255.0
//        let gf = Double(g) / 255.0
//        let bf = Double(b) / 255.0
//        
//        let maxVal = max(rf, gf, bf)
//        let minVal = min(rf, gf, bf)
//        let delta = maxVal - minVal
//        
//        var h: Double = 0
//        var s: Double = 0
//        let l = (maxVal + minVal) / 2.0
//        
//        if delta != 0 {
//            s = l > 0.5 ? delta / (2.0 - maxVal - minVal) : delta / (maxVal + minVal)
//            
//            if maxVal == rf {
//                h = (gf - bf) / delta + (gf < bf ? 6 : 0)
//            } else if maxVal == gf {
//                h = (bf - rf) / delta + 2
//            } else {
//                h = (rf - gf) / delta + 4
//            }
//            
//            h /= 6
//        }
//        
//        return (Int(h * 360), Int(s * 100), Int(l * 100))
//    }
//    
//    private static func hexToRGB(_ hex: String) -> (Int, Int, Int) {
//        let scanner = Scanner(string: hex)
//        scanner.scanLocation = 1 // Skip the '#'
//        var hexNumber: UInt64 = 0
//        scanner.scanHexInt64(&hexNumber)
//        
//        let r = Int((hexNumber & 0xFF0000) >> 16)
//        let g = Int((hexNumber & 0x00FF00) >> 8)
//        let b = Int(hexNumber & 0x0000FF)
//        
//        return (r, g, b)
//    }
//} 
