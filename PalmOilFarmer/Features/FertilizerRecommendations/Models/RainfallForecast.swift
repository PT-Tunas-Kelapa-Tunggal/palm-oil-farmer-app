import Foundation

struct RainfallForecast: Codable {
    let dateRange: String
    let headline: String
    let days: [RainfallDay]
    let summary: String
    let heavyThresholdMillimeters: Double
}
