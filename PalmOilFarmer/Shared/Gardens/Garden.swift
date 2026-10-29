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
    /// Raw analysis JSON. Production can populate this from the synced CloudKit result asset/string.
    var analysisResultJSON: String? = nil

    /// Derived from fertilizer history so edits cannot leave a stale nutrient total.
    var fertilizerNutrientSummary: GardenFertilizerNutrientSummary {
        let breakdowns = (fertilizerRecords ?? []).compactMap { record -> FertilizerNutrientBreakdown? in
            guard let perBag = record.elementalNutrientsPerBag,
                  let totalPurchased = record.totalElementalNutrientsPurchased else { return nil }
            return FertilizerNutrientBreakdown(id: record.id, name: record.name,
                                               perBag: perBag, totalPurchased: totalPurchased)
        }
        let zero = ElementalNutrientAmounts(nitrogenKg: 0, phosphorusKg: 0, potassiumKg: 0, magnesiumKg: 0)
        let total = breakdowns.reduce(zero) { $0 + $1.totalPurchased }
        return GardenFertilizerNutrientSummary(fertilizers: breakdowns, totalPurchased: total)
    }
}

struct FertilizerRecord: Identifiable, Codable {
    var id = UUID()
    var name: String
    var bagWeightKg: Double
    var bagCount: Int
    var doseKgPerTree: Double
    var npkComposition: NPKComposition? = nil

    var elementalNutrientsPerBag: ElementalNutrientAmounts? {
        npkComposition?.elementalAmounts(forBagWeightKg: bagWeightKg)
    }

    var totalElementalNutrientsPurchased: ElementalNutrientAmounts? {
        elementalNutrientsPerBag?.multiplied(by: Double(bagCount))
    }
}

struct NPKComposition: Codable, Equatable {
    var nitrogenPercent: Double
    var phosphatePercent: Double
    var potashPercent: Double
    var magnesiumPercent: Double? = nil

    /// Converts label percentages (N, P₂O₅, K₂O and MgO) to elemental kilograms.
    func elementalAmounts(forBagWeightKg bagWeightKg: Double) -> ElementalNutrientAmounts {
        let factor = bagWeightKg / 100
        return ElementalNutrientAmounts(
            nitrogenKg: nitrogenPercent * factor,
            phosphorusKg: phosphatePercent * factor * 0.4364,
            potassiumKg: potashPercent * factor * 0.8302,
            magnesiumKg: (magnesiumPercent ?? 0) * factor * 0.6030
        )
    }
}

struct ElementalNutrientAmounts: Codable, Equatable {
    var nitrogenKg: Double
    var phosphorusKg: Double
    var potassiumKg: Double
    var magnesiumKg: Double

    func multiplied(by factor: Double) -> ElementalNutrientAmounts {
        ElementalNutrientAmounts(
            nitrogenKg: nitrogenKg * factor,
            phosphorusKg: phosphorusKg * factor,
            potassiumKg: potassiumKg * factor,
            magnesiumKg: magnesiumKg * factor
        )
    }

    static func + (lhs: ElementalNutrientAmounts, rhs: ElementalNutrientAmounts) -> ElementalNutrientAmounts {
        ElementalNutrientAmounts(
            nitrogenKg: lhs.nitrogenKg + rhs.nitrogenKg,
            phosphorusKg: lhs.phosphorusKg + rhs.phosphorusKg,
            potassiumKg: lhs.potassiumKg + rhs.potassiumKg,
            magnesiumKg: lhs.magnesiumKg + rhs.magnesiumKg
        )
    }
}

struct GardenFertilizerNutrientSummary: Equatable {
    let fertilizers: [FertilizerNutrientBreakdown]
    let totalPurchased: ElementalNutrientAmounts
}

struct FertilizerNutrientBreakdown: Identifiable, Equatable {
    let id: UUID
    let name: String
    let perBag: ElementalNutrientAmounts
    let totalPurchased: ElementalNutrientAmounts
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
