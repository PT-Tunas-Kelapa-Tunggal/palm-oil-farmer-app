import Foundation

struct Garden: Identifiable, Codable {
    let id: UUID
    let name: String
    let locationName: String
    let boundary: GardenBoundary
    let plantingYear: Int
    let soilType: SoilType
    var plantingMonth: Int? = nil
    var fertilizerRecords: [FertilizerRecord]? = nil
    var harvestRecord: HarvestRecord? = nil
    var review: GardenReview? = nil
    /// When the garden was registered. Gardens saved before this field have none.
    var createdAt: Date? = nil
    var fertilizationFrequencyPerYear: Int? = nil
}

struct FertilizerRecord: Identifiable, Codable {
    var id = UUID()
    var name: String
    var bagWeightKg: Double? = nil
    var bagCount: Int? = nil
    var doseKgPerTree: Double
    var composition: FertilizerComposition? = nil
}

struct HarvestRecord: Codable {
    var frequencyPerMonth: Int
    var latestWeightKg: Double
}

enum SoilType: String, CaseIterable, Identifiable, Codable {
    case mineral = "Mineral"
    case peat = "Gambut"
    case wetland = "Rawa"
    case sand = "Pasir"
    case rock = "Batu"
    case other = "Lainnya"

    var id: String { rawValue }

    var displayName: String {
        self == .other ? rawValue : "Tanah " + rawValue
    }
}
