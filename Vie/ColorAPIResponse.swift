struct ColorAPIResponse: Codable {
    let name: ColorName
    let hex: HexValue
    let rgb: RGBValue
    let hsl: HSLValue
    var family: String?
    
    struct ColorName: Codable {
        let value: String
        let closestNamedHex: String?
        let exact: Bool?
        let distance: Int?
    }
    
    struct HexValue: Codable {
        let value: String
        let clean: String
    }
    
    struct RGBValue: Codable {
        let r: Int
        let g: Int
        let b: Int
        let value: String
    }
    
    struct HSLValue: Codable {
        let h: Int
        let s: Int
        let l: Int
        let value: String
    }
    
    mutating func determineColorFamily() {
        let rgbColor = RGB(r: rgb.r, g: rgb.g, b: rgb.b)
        let hslColor = HSL(h: Double(hsl.h), s: Double(hsl.s)/100.0, l: Double(hsl.l)/100.0)
        let colorData = ColorData(
            name: name.value,
            hex: hex.value,
            rgb: rgbColor,
            hsl: hslColor,
            cmyk: CMYK(c: 0, m: 0, y: 0, k: 0)
        )
        self.family = ColorFamilies.categorizeColor(colorData)
    }
} 