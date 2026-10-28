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
}

struct FertilizerRecord: Identifiable, Codable {
    var id = UUID()
    var name: String
    var bagWeightKg: Double
    var bagCount: Int
    var doseKgPerTree: Double
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

    // Keep legacy soil values editable while matching the new registration choices.
    static func registrationOptions(current: SoilType?) -> [SoilType] {
        let options: [SoilType] = [.mineral, .peat, .other]
        if let current, !options.contains(current) { return options + [current] }
        return options
    }

    var displayName: String {
        self == .other ? rawValue : "Tanah " + rawValue
    }
}
