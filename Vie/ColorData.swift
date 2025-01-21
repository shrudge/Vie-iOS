import Foundation

struct ColorData: Codable {
    let name: String
    let hex: String
}

struct ColorsWrapper: Codable {
    let colors: [ColorData]
} 
