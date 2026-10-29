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
            if FertilizerCatalogue.isKnownFertilizer(record?.name ?? "") {
                name = record?.name ?? ""
            } else {
                name = composition.magnesiumPercent == nil ? FertilizerCatalogue.customNPK : FertilizerCatalogue.customNPKMg
            }
        } else {
            name = record?.name ?? ""
        }
        bagWeightKg = record?.bagWeightKg
        bagCount = record?.bagCount
        doseKgPerTree = record?.doseKgPerTree
        let composition = record?.npkComposition ?? FertilizerCatalogue.presetCompositions[record?.name ?? ""]
        nitrogenPercent = composition?.nitrogenPercent
        phosphatePercent = composition?.phosphatePercent
        potashPercent = composition?.potashPercent
        magnesiumPercent = composition?.magnesiumPercent
    }

    var isEmpty: Bool {
        name.isEmpty && bagWeightKg == nil && bagCount == nil && doseKgPerTree == nil
            && nitrogenPercent == nil && phosphatePercent == nil && potashPercent == nil && magnesiumPercent == nil
    }

    var usesCustomNPKComposition: Bool {
        name == FertilizerCatalogue.customNPK || name == FertilizerCatalogue.customNPKMg
    }

    var hasKnownNPKComposition: Bool {
        usesCustomNPKComposition || FertilizerCatalogue.presetCompositions[name] != nil
    }

    var requiresMagnesiumComposition: Bool { name == FertilizerCatalogue.customNPKMg }

    mutating func selectFertilizerType(_ name: String) {
        self.name = name
        if name == FertilizerCatalogue.customNPK || name == FertilizerCatalogue.customNPKMg {
            nitrogenPercent = nil
            phosphatePercent = nil
            potashPercent = nil
            magnesiumPercent = nil
        } else if let composition = FertilizerCatalogue.presetCompositions[name] {
            nitrogenPercent = composition.nitrogenPercent
            phosphatePercent = composition.phosphatePercent
            potashPercent = composition.potashPercent
            magnesiumPercent = composition.magnesiumPercent
        } else {
            nitrogenPercent = nil
            phosphatePercent = nil
            potashPercent = nil
            magnesiumPercent = nil
        }
    }

    var elementalNutrientsPerBag: ElementalNutrientAmounts? {
        guard hasKnownNPKComposition,
              let bagWeightKg, bagWeightKg.isFinite, bagWeightKg > 0,
              let composition = enteredComposition else { return nil }
        return composition.elementalAmounts(forBagWeightKg: bagWeightKg)
    }

    private var enteredComposition: NPKComposition? {
        if let preset = FertilizerCatalogue.presetCompositions[name] { return preset }
        guard usesCustomNPKComposition, hasValidNPKComposition,
              let nitrogenPercent, let phosphatePercent, let potashPercent else { return nil }
        return NPKComposition(nitrogenPercent: nitrogenPercent, phosphatePercent: phosphatePercent,
                              potashPercent: potashPercent, magnesiumPercent: magnesiumPercent)
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
            guard let enteredComposition else { return nil }
            composition = enteredComposition
            recordName = displayName
        } else if let preset = FertilizerCatalogue.presetCompositions[trimmedName] {
            composition = preset
            recordName = trimmedName
        } else if FertilizerCatalogue.supplementalNutrients[trimmedName] != nil {
            composition = nil
            recordName = trimmedName
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

    enum SupplementalNutrient {
        case nitrogen
        case magnesium
    }

    static let supplementalNutrients: [String: SupplementalNutrient] = [
        "Urea": .nitrogen,
        "ZA": .nitrogen,
        "Dolomit": .magnesium,
        "Kieserit": .magnesium
    ]

    static let pulseCheckProductIDs: [(name: String, id: String)] = [
        ("Urea", "urea_N_expensive"),
        ("ZA", "ZA_N_cheaper"),
        ("Dolomit", "dolomite_Mg_cheaper"),
        ("Kieserit", "kieserite_Mg_expensive")
    ]

    static func isKnownFertilizer(_ name: String) -> Bool {
        presetCompositions[name] != nil || supplementalNutrients[name] != nil
    }

    static let presetCompositions: [String: NPKComposition] = [
        "NPK 13-6-27-4+0.65B": NPKComposition(nitrogenPercent: 13, phosphatePercent: 6, potashPercent: 27, magnesiumPercent: 4),
        "NPK 12-6-22-3+TE": NPKComposition(nitrogenPercent: 12, phosphatePercent: 6, potashPercent: 22, magnesiumPercent: 3),
        "NPK 15-15-6-4": NPKComposition(nitrogenPercent: 15, phosphatePercent: 15, potashPercent: 6, magnesiumPercent: 4),
        "NPK 12-12-17-2+TE": NPKComposition(nitrogenPercent: 12, phosphatePercent: 12, potashPercent: 17, magnesiumPercent: 2),
        "NPK 13-8-27-4+0.5B": NPKComposition(nitrogenPercent: 13, phosphatePercent: 8, potashPercent: 27, magnesiumPercent: 4)
    ]

    static let names = [
        "Urea", "ZA", "SP-36", "TSP", "KCl",
        "NPK 13-6-27-4+0.65B", "NPK 12-6-22-3+TE", "NPK 15-15-6-4",
        "NPK 12-12-17-2+TE", "NPK 13-8-27-4+0.5B",
        customNPK, customNPKMg, unknownNPK,
        "Dolomit", "Kieserit", "Borat", "Pupuk Organik", "Lainnya"
    ]
}

