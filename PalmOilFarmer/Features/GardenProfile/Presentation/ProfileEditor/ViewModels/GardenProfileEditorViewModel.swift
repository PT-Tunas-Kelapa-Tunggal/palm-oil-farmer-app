import Foundation
import Observation

/// A single draft and a single persistence call keep harvest and fertilizer edits atomic.
@MainActor
@Observable
final class GardenProfileEditorViewModel {
    var harvestFrequency: Int
    var monthlyWeightKg: Double?
    var fertilizationFrequency: Int
    var fertilizers: [FertilizerInputDraft]
    var validationIssue: GardenProfileValidationIssue?

    var errorMessage: String? { validationIssue?.message }

    private(set) var hasSaved = false
    private let isActive: () -> Bool
    private let onSave: (HarvestRecord, Int, [FertilizerRecord]) -> Bool
    private let onSaved: () -> Void

    init(garden: Garden, isActive: @escaping () -> Bool = { true },
         onSave: @escaping (HarvestRecord, Int, [FertilizerRecord]) -> Bool,
         onSaved: @escaping () -> Void) {
        harvestFrequency = garden.harvestRecord?.frequencyPerMonth ?? 2
        monthlyWeightKg = garden.harvestRecord?.monthlyWeightKg
        fertilizationFrequency = garden.fertilizationFrequencyPerYear ?? 2
        let initialFertilizers = (garden.fertilizerRecords ?? []).map { FertilizerInputDraft(record: $0) }
        fertilizers = initialFertilizers.isEmpty ? [FertilizerInputDraft()] : initialFertilizers
        self.isActive = isActive
        self.onSave = onSave
        self.onSaved = onSaved
    }

    func addFertilizer() {
        guard isActive(), !hasSaved else { return }
        fertilizers.append(FertilizerInputDraft())
    }

    func removeFertilizer(id: UUID) {
        guard isActive(), !hasSaved else { return }
        fertilizers.removeAll { $0.id == id }
        if fertilizers.isEmpty { fertilizers = [FertilizerInputDraft()] }
    }

    func nextField(after field: GardenProfileEditorField?) -> GardenProfileEditorField? {
        let fields: [GardenProfileEditorField] = [.monthlyHarvestWeight] + fertilizers.flatMap { draft in
            let nutrients: [GardenProfileEditorField] = draft.kind == .npk
                ? GardenProfileEditorField.Nutrient.allCases.map { .fertilizerNutrient(draft.id, $0) } : []
            return nutrients + [.fertilizerDose(draft.id)]
        }
        guard let field, let index = fields.firstIndex(of: field), fields.indices.contains(index + 1) else { return nil }
        return fields[index + 1]
    }

    @discardableResult
    func save() -> Bool {
        guard !hasSaved else { return true }
        guard isActive() else { return false }
        validationIssue = nil
        guard HarvestRecord.frequencyRange.contains(harvestFrequency) else {
            validationIssue = GardenProfileValidationIssue(field: .harvestFrequency, message: "Isi frekuensi panen yang valid.")
            return false
        }
        guard let monthlyWeightKg, monthlyWeightKg.isFinite, monthlyWeightKg > 0 else {
            validationIssue = GardenProfileValidationIssue(field: .monthlyHarvestWeight, message: "Isi berat panen bulanan lebih dari nol.")
            return false
        }
        guard GardenProfileValidation.fertilizationFrequencyRange.contains(fertilizationFrequency) else {
            validationIssue = GardenProfileValidationIssue(field: .fertilizationFrequency, message: "Isi frekuensi pemupukan yang valid.")
            return false
        }
        let filled = fertilizers.filter { !$0.isEmpty }
        guard !filled.isEmpty else {
            validationIssue = GardenProfileValidationIssue(field: fertilizers.first.map { .fertilizerType($0.id) },
                message: "Isi setidaknya satu jenis pupuk dan dosisnya.")
            return false
        }
        if let issue = filled.compactMap(\.validationIssue).first {
            validationIssue = issue
            return false
        }
        let records = filled.compactMap(\.record)
        guard records.count == filled.count else { return false }
        // Keep the existing per-harvest field meaningful for older review consumers.
        let harvest = HarvestRecord(frequencyPerMonth: harvestFrequency,
                                    latestWeightKg: monthlyWeightKg / Double(harvestFrequency),
                                    averageMonthlyWeightKg: monthlyWeightKg)
        guard onSave(harvest, fertilizationFrequency, records) else {
            validationIssue = GardenProfileValidationIssue(field: nil, message: "Data tidak dapat disimpan di perangkat. Coba lagi.")
            return false
        }
        hasSaved = true
        onSaved()
        return true
    }
}
