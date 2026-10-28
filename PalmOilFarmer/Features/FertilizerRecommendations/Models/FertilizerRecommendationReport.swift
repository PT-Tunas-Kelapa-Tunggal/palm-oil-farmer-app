import Foundation

enum RecommendationTab: String, CaseIterable, Identifiable, Codable {
    case nutrients = "Proyeksi hara"
    case allocation = "Alokasi pupuk"
    case rainfall = "Curah hujan"
    var id: String { rawValue }
}

struct NutrientProjection: Identifiable, Codable {
    let name: String
    let current: Double
    let target: Double
    var requirement: Double = 0.5
    var status: String? = nil
    var id: String { name }
}

struct FertilizerCostLine: Identifiable, Codable {
    let name: String
    let quantity: String
    let cost: String
    var id: String { name }
}

struct FertilizerAllocationLine: Identifiable, Codable {
    let name: String
    let total: String
    let dosage: String
    var id: String { name }
}

struct FertilizerAllocationPeriod: Identifiable, Codable {
    let title: String
    let dateRange: String
    let lines: [FertilizerAllocationLine]
    var id: String { title }
}

struct FertilizerAllocationArea: Identifiable, Codable {
    let id: String
    let mapImage: String?
    let periods: [FertilizerAllocationPeriod]
    var boundary: GardenBoundary? = nil
    var navigationTarget: GardenCoordinate? = nil
}

/// Presentation data comes from a report; the UI does not calculate agronomic recommendations.
struct FertilizerRecommendationReport: Codable {
    let gardenName: String
    let locationName: String
    let boundary: GardenBoundary
    let outline: [CGPoint]
    let nutrients: [NutrientProjection]
    let costs: [FertilizerCostLine]
    let totalCost: String
    let areas: [FertilizerAllocationArea]
    var nutrientSummary: String? = nil
    var nutrientReferences: [NutrientReference] = []
    var rainfall: RainfallForecast? = nil
    var downloadURL: URL? = nil
}

