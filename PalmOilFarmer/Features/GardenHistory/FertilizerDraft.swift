import Foundation

struct FertilizerDraft: Identifiable {
    let id: UUID
    var name: String
    var bagWeightKg: Double?
    var bagCount: Int?
    var doseKgPerTree: Double?
    var nitrogenPercent: Double?
    var phosphatePercent: Double?
    var potashPercent: Double?
    var magnesiumPercent: Double?

    init(record: FertilizerRecord? = nil) {
        id = record?.id ?? UUID()
        if let composition = record?.npkComposition {
            name = composition.magnesiumPercent == nil ? FertilizerCatalogue.customNPK : FertilizerCatalogue.customNPKMg
        } else {
            name = record?.name ?? ""
        }
        bagWeightKg = record?.bagWeightKg
        bagCount = record?.bagCount
        doseKgPerTree = record?.doseKgPerTree
        nitrogenPercent = record?.npkComposition?.nitrogenPercent
        phosphatePercent = record?.npkComposition?.phosphatePercent
        potashPercent = record?.npkComposition?.potashPercent
        magnesiumPercent = record?.npkComposition?.magnesiumPercent
    }

    var isEmpty: Bool {
        name.isEmpty && bagWeightKg == nil && bagCount == nil && doseKgPerTree == nil
            && nitrogenPercent == nil && phosphatePercent == nil && potashPercent == nil && magnesiumPercent == nil
    }

    var usesCustomNPKComposition: Bool {
        name == FertilizerCatalogue.customNPK || name == FertilizerCatalogue.customNPKMg
    }

    var requiresMagnesiumComposition: Bool { name == FertilizerCatalogue.customNPKMg }

    mutating func selectFertilizerType(_ name: String) {
        self.name = name
        guard name == FertilizerCatalogue.customNPK || name == FertilizerCatalogue.customNPKMg else { return }
        nitrogenPercent = nil
        phosphatePercent = nil
        potashPercent = nil
        magnesiumPercent = nil
    }

    var displayName: String {
        guard usesCustomNPKComposition,
              let nitrogenPercent, let phosphatePercent, let potashPercent else { return name }
        let values = [nitrogenPercent, phosphatePercent, potashPercent]
        let formula = values.map { $0.formatted(.number.precision(.fractionLength(0...2))) }
        if requiresMagnesiumComposition, let magnesiumPercent {
            return "NPKMg " + (formula + [magnesiumPercent.formatted(.number.precision(.fractionLength(0...2)))]).joined(separator: "-")
        }
        return "NPK " + formula.joined(separator: "-")
    }

    var hasValidNPKComposition: Bool {
        guard usesCustomNPKComposition,
              let nitrogenPercent, let phosphatePercent, let potashPercent,
              [nitrogenPercent, phosphatePercent, potashPercent].allSatisfy({ (0...100).contains($0) }) else {
            return false
        }
        if requiresMagnesiumComposition {
            guard let magnesiumPercent, (0...100).contains(magnesiumPercent) else { return false }
        } else if let magnesiumPercent, !(0...100).contains(magnesiumPercent) {
            return false
        }
        return true
    }

    var record: FertilizerRecord? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              let bagWeightKg, bagWeightKg.isFinite, bagWeightKg > 0,
              let bagCount, bagCount > 0,
              let doseKgPerTree, doseKgPerTree.isFinite, doseKgPerTree > 0 else { return nil }
        if usesCustomNPKComposition && !hasValidNPKComposition { return nil }
        let composition: NPKComposition?
        let recordName: String
        if usesCustomNPKComposition {
            guard let nitrogenPercent, let phosphatePercent, let potashPercent else { return nil }
            composition = NPKComposition(nitrogenPercent: nitrogenPercent, phosphatePercent: phosphatePercent,
                                         potashPercent: potashPercent, magnesiumPercent: magnesiumPercent)
            recordName = displayName
        } else {
            composition = nil
            recordName = trimmedName
        }
        return FertilizerRecord(id: id, name: recordName, bagWeightKg: bagWeightKg,
                                bagCount: bagCount, doseKgPerTree: doseKgPerTree,
                                npkComposition: composition)
    }
}

enum FertilizerCatalogue {
    static let customNPK = "NPK · isi komposisi sendiri"
    static let customNPKMg = "NPKMg · isi komposisi sendiri"
    static let unknownNPK = "NPK · komposisi tidak diketahui"

    static let names = [
        "Urea", "ZA", "SP-36", "TSP", "KCl",
        "NPK 13-6-27-4+0.65B", "NPK 12-6-22-3+TE", "NPK 15-15-6-4",
        "NPK 12-12-17-2+TE", "NPK 13-8-27-4+0.5B",
        customNPK, customNPKMg, unknownNPK,
        "Dolomit", "Kieserit", "Borat", "Pupuk Organik", "Lainnya"
    ]
}

