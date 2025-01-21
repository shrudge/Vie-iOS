struct ColorAPIResponse: Codable {
    let name: ColorName
    let hex: HexValue
    
    struct ColorName: Codable {
        let value: String
    }
    
    struct HexValue: Codable {
        let value: String
    }
} 