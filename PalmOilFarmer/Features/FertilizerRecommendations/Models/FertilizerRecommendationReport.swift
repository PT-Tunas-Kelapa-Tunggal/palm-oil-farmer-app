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
    var currentAvailable: Bool = true
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
    var choices: [FertilizerAllocationChoice]? = nil
    var id: String { title }
}

struct FertilizerAllocationChoice: Identifiable, Codable {
    let id: String
    let title: String
    let options: [FertilizerAllocationOption]
}

struct FertilizerAllocationOption: Identifiable, Codable {
    let id: String
    let name: String
    let priceDescription: String
    let total: String
    let dosage: String
    let isLowerCost: Bool
}

struct FertilizerAllocationArea: Identifiable, Codable {
    let id: String
    let mapImage: String?
    let periods: [FertilizerAllocationPeriod]
    var mapPoint: FertilizerMapPoint? = nil
    var boundary: GardenBoundary? = nil
    var navigationTarget: GardenCoordinate? = nil
}

struct FertilizerMapPoint: Codable {
    let x: Double
    let y: Double
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
    var singleFertilizerSummary: String? = nil
    var supplementalNutrientProjections: [NutrientProjection] = []
    var nutrientMapImageName: String? = nil
    var nutrientReferences: [NutrientReference] = []
    var rainfall: RainfallForecast? = nil
    var downloadURL: URL? = nil
    var nutrientChartTitle: String? = nil
    var nutrientChartEyebrow: String? = nil
    var nutrientChartCaption: String? = nil
    var currentNutrientLabel: String? = nil
    var targetNutrientLabel: String? = nil
    var nutrientRequirementLabel: String? = nil
}

