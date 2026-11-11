import Foundation

extension FertilizerRecord {
    static func validated(
        id: UUID,
        name: String,
        bagWeightKg: Double,
        bagCount: Int,
        doseKgPerTree: Double
    ) -> FertilizerRecord? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              bagWeightKg.isFinite, bagWeightKg > 0,
              bagCount > 0,
              doseKgPerTree.isFinite, doseKgPerTree > 0 else { return nil }
        return FertilizerRecord(id: id, name: trimmedName, bagWeightKg: bagWeightKg,
                                bagCount: bagCount, doseKgPerTree: doseKgPerTree)
    }
}

extension HarvestRecord {
    static let frequencyRange = 1...31

    static func validated(frequencyPerMonth: Int, latestWeightKg: Double) -> HarvestRecord? {
        guard frequencyRange.contains(frequencyPerMonth),
              latestWeightKg.isFinite, latestWeightKg > 0 else { return nil }
        return HarvestRecord(frequencyPerMonth: frequencyPerMonth, latestWeightKg: latestWeightKg)
    }
}

enum GardenProfileValidation {
    static let fertilizationFrequencyRange = 1...12
}
