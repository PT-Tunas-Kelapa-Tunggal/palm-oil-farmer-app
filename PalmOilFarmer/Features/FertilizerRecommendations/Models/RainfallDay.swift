import Foundation

struct RainfallDay: Identifiable, Codable {
    let id: String
    let weekday: String
    let symbol: String
    let precipitationMillimeters: Double
    let isHeavy: Bool
    let spreadStatus: String
}
