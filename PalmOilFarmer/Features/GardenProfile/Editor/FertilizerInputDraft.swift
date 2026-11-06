import Foundation

struct FertilizerInputDraft: Identifiable {
    let id: UUID
    var kind: FertilizerType
    var doseKgPerTree: Double?
    var composition: FertilizerComposition

    // Hidden by the current design, but retained when editing existing records.
    private var bagWeightKg: Double?
    private var bagCount: Int?

    var name: String {
        get { FertilizerCatalogue.storedName(for: kind) }
        set { kind = FertilizerCatalogue.kind(for: newValue) }
    }

    init(record: FertilizerRecord? = nil) {
        id = record?.id ?? UUID()
        doseKgPerTree = record?.doseKgPerTree
        bagWeightKg = record?.bagWeightKg
        bagCount = record?.bagCount
        composition = record?.composition ?? FertilizerComposition()
        let storedName = record?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        kind = FertilizerCatalogue.kind(for: storedName)

        // Only normalize a decorated NPK name when its composition is understood.
        // Unknown names remain selectable and are never replaced with an empty NPK.
        if storedName.hasPrefix("NPK "), let parsed = Self.legacyComposition(from: storedName) {
            kind = .npk
            composition = record?.composition ?? parsed
        }
    }

    var isEmpty: Bool {
        kind == .unselected && doseKgPerTree == nil && composition == FertilizerComposition()
    }

    var validationIssue: GardenProfileValidationIssue? {
        if kind == .unselected {
            return GardenProfileValidationIssue(field: .fertilizerType(id), message: "Pilih jenis pupuk.")
        }
        guard let doseKgPerTree, doseKgPerTree.isFinite, doseKgPerTree > 0 else {
            return GardenProfileValidationIssue(field: .fertilizerDose(id), message: "Isi dosis pupuk lebih dari nol.")
        }
        if kind == .npk {
            for (nutrient, value) in [
                (GardenProfileEditorField.Nutrient.nitrogen, composition.nitrogen),
                (.phosphorus, composition.phosphorus),
                (.potassium, composition.potassium)
            ] {
                guard let value, value.isFinite, (0...100).contains(value) else {
                    return GardenProfileValidationIssue(field: .fertilizerNutrient(id, nutrient),
                        message: "Isi persentase N, P, dan K masing-masing 0–100%.")
                }
            }
            guard composition.isValid else {
                return GardenProfileValidationIssue(field: .fertilizerNutrient(id, .magnesium),
                    message: "Komposisi NPK harus 0–100% per unsur, dengan total lebih dari 0% dan paling banyak 100%.")
            }
        }
        return nil
    }

    var record: FertilizerRecord? {
        guard validationIssue == nil, let doseKgPerTree else { return nil }
        var savedComposition: FertilizerComposition?
        if kind == .npk {
            savedComposition = composition
            savedComposition?.magnesium = composition.magnesium ?? 0
        } else if case .custom = kind, composition != FertilizerComposition() {
            // Preserve unfamiliar existing records without silently discarding data.
            savedComposition = composition
        }
        return FertilizerRecord(id: id, name: name, bagWeightKg: bagWeightKg, bagCount: bagCount,
                                doseKgPerTree: doseKgPerTree, composition: savedComposition)
    }

    private static func legacyComposition(from name: String) -> FertilizerComposition? {
        let parts = name.dropFirst(4).split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3 || parts.count == 4 else { return nil }
        let values = parts.compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard values.count == parts.count else { return nil }
        let result = FertilizerComposition(nitrogen: values[0], phosphorus: values[1],
            potassium: values[2], magnesium: values.count == 4 ? values[3] : nil)
        return result.isValid ? result : nil
    }
}
