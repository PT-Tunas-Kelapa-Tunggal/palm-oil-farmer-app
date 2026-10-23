import Foundation

enum RecommendationTab: String, CaseIterable, Identifiable {
    case nutrients = "Proyeksi hara"
    case allocation = "Alokasi pupuk"
    case rainfall = "Curah hujan"
    var id: String { rawValue }
}

struct NutrientProjection: Identifiable {
    let name: String
    let current: Double
    let target: Double
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
}

/// Presentation data comes from a report; the UI does not calculate agronomic recommendations.
struct FertilizerRecommendationReport {
    let gardenName: String
    let locationName: String
    let boundary: GardenBoundary
    let outline: [CGPoint]
    let nutrients: [NutrientProjection]
    let costs: [FertilizerCostLine]
    let totalCost: String
    let areas: [FertilizerAllocationArea]
}

