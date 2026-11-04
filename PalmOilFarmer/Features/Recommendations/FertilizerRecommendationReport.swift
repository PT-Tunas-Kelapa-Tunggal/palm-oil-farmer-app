import Foundation
import CoreLocation

enum RecommendationTab: String, CaseIterable, Identifiable {
    case nutrients = "Kebutuhan pupuk"
    case allocation = "Alokasi pupuk"
    case rainfall = "Curah hujan"
    var id: String { rawValue }
}

struct NutrientProjection: Identifiable {
    let name: String
    /// Levels are fractions of the chart height.
    let current: Double
    let target: Double
    var status = ""
    var id: String { name }
}

struct FertilizerCostLine: Identifiable {
    let name: String
    let quantity: String
    let cost: String
    var id: String { name }
}

struct FertilizerAllocationLine: Identifiable {
    let name: String
    let total: String
    let dosage: String
    var id: String { name }
}

struct FertilizerAllocationPeriod: Identifiable {
    let title: String
    let dateRange: String
    let lines: [FertilizerAllocationLine]
    var id: String { title }
}

struct FertilizerAllocationArea: Identifiable {
    let id: String
    let mapImage: String?
    let periods: [FertilizerAllocationPeriod]
    /// The part of the garden this area covers, used for the area map and navigation.
    var zone: WaypointZone? = nil
}

struct RainfallDay: Identifiable {
    let weekday: String
    let millimeters: Double
    var id: String { weekday }
    var isHeavy: Bool { millimeters >= Self.heavyThreshold }
}

struct RainfallForecast {
    let dateRange: String
    let headline: String
    let days: [RainfallDay]
    let advice: AttributedString
}

/// Presentation data comes from a report; the UI does not calculate agronomic recommendations.
struct FertilizerRecommendationReport {
    let gardenName: String
    let locationName: String
    let boundary: GardenBoundary
    let outline: [CGPoint]
    let nutrients: [NutrientProjection]
    var nutrientNeed = 0.64
    var nutrientSummary = ""
    let costs: [FertilizerCostLine]
    let totalCost: String
    let areas: [FertilizerAllocationArea]
    var rainfall: RainfallForecast? = nil
}
