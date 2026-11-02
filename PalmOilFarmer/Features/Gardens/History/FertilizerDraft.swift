import Foundation

struct FertilizerDraft: Identifiable {
    let id: UUID
    var name: String
    var bagWeightKg: Double?
    var bagCount: Int?
    var doseKgPerTree: Double?
    var composition = FertilizerComposition()

    var isNPK: Bool { name.trimmingCharacters(in: .whitespaces).uppercased().hasPrefix("NPK") }

    init(record: FertilizerRecord? = nil) {
        id = record?.id ?? UUID()
        name = record?.name ?? ""
        bagWeightKg = record?.bagWeightKg
        bagCount = record?.bagCount
        doseKgPerTree = record?.doseKgPerTree
        composition = record?.composition ?? FertilizerComposition.fromLabel(name)
    }

    var isEmpty: Bool {
        name.isEmpty && bagWeightKg == nil && bagCount == nil && doseKgPerTree == nil
    }

    var record: FertilizerRecord? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              let doseKgPerTree, doseKgPerTree.isFinite, doseKgPerTree > 0 else { return nil }
        if let bagWeightKg, !bagWeightKg.isFinite || bagWeightKg <= 0 { return nil }
        if let bagCount, bagCount <= 0 { return nil }
        if isNPK && !composition.isValid { return nil }
        var savedComposition = composition
        savedComposition.magnesium = composition.magnesium ?? 0
        return FertilizerRecord(id: id, name: trimmedName, bagWeightKg: bagWeightKg,
                                bagCount: bagCount, doseKgPerTree: doseKgPerTree,
                                composition: isNPK ? savedComposition : nil)
    }
}

enum FertilizerCatalogue {
    static let names = ["Urea", "ZA", "SP-36", "TSP", "KCl", "NPK", "Dolomit",
                        "Kieserit", "Borat", "Pupuk Organik", "Lainnya"]
}

