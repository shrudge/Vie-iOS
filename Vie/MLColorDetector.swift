import CoreML

class MLColorDetector {
    static let shared = MLColorDetector()
    private let model: Vie2model
    
    private init() {
        do {
            let config = MLModelConfiguration()
            self.model = try Vie2model(configuration: config)
        } catch {
            fatalError("Failed to load ML model: \(error)")
        }
    }
    
    func detectColor(r: Int64, g: Int64, b: Int64) -> String {
        do {
            let prediction = try model.prediction(red: r, green: g, blue: b)
            return prediction.label
        } catch {
            print("Prediction error: \(error)")
            return "Unknown"
        }
    }
} 