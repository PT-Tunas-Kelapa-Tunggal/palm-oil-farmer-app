import Foundation
import Observation

@MainActor
@Observable
final class FertilizerHistoryViewModel {
    var drafts: [FertilizerDraft]
    var errorMessage: String?
    private(set) var hasSaved = false
    private let isActive: () -> Bool
    private let onSave: ([FertilizerRecord]) -> Bool
    private let onSaved: () -> Void

    init(records: [FertilizerRecord], includesEmptyDraft: Bool = false,
         isActive: @escaping () -> Bool = { true }, onSave: @escaping ([FertilizerRecord]) -> Bool,
         onSaved: @escaping () -> Void) {
        var initialDrafts = records.map { FertilizerDraft(record: $0) }
        if initialDrafts.isEmpty || includesEmptyDraft { initialDrafts.append(FertilizerDraft()) }
        drafts = initialDrafts
        self.isActive = isActive
        self.onSave = onSave
        self.onSaved = onSaved
    }

    func addDraft() -> UUID? {
        guard isActive(), !hasSaved else { return nil }
        let draft = FertilizerDraft()
        drafts.append(draft)
        return draft.id
    }

    func removeDraft(id: UUID) {
        guard isActive(), !hasSaved else { return }
        drafts.removeAll { $0.id == id }
    }

    func selectType(_ name: String, for id: UUID) {
        guard isActive(), !hasSaved, let index = drafts.firstIndex(where: { $0.id == id }) else { return }
        drafts[index].name = name
    }

    func nextField(after field: FertilizerField?) -> FertilizerField? {
        let order = drafts.flatMap { draft in FertilizerField.Kind.allCases.map { FertilizerField(draftID: draft.id, kind: $0) } }
        guard let field, let index = order.firstIndex(of: field), index + 1 < order.count else { return nil }
        return order[index + 1]
    }

    @discardableResult
    func save() -> Bool {
        guard !hasSaved else { return true }
        guard isActive() else { return false }
        let filled = drafts.filter { !$0.isEmpty }
        let records = filled.compactMap(\.record)
        guard records.count == filled.count else {
            errorMessage = "Lengkapi jenis pupuk, berat, jumlah karung, dan dosis dengan nilai lebih dari nol."
            return false
        }
        guard onSave(records) else {
            errorMessage = "Data tidak dapat disimpan di perangkat. Coba lagi."
            return false
        }
        hasSaved = true
        onSaved()
        return true
    }
}

@MainActor
@Observable
final class HarvestHistoryViewModel {
    var frequency: Int
    var weight: Double
    var showsError = false
    private(set) var hasSaved = false
    private let isActive: () -> Bool
    private let onSave: (HarvestRecord) -> Bool
    private let onSaved: () -> Void

    init(record: HarvestRecord?, isActive: @escaping () -> Bool = { true },
         onSave: @escaping (HarvestRecord) -> Bool, onSaved: @escaping () -> Void) {
        frequency = min(max(record?.frequencyPerMonth ?? 2, HarvestRecord.frequencyRange.lowerBound),
                        HarvestRecord.frequencyRange.upperBound)
        weight = record?.latestWeightKg ?? 450
        self.isActive = isActive
        self.onSave = onSave
        self.onSaved = onSaved
    }

    var weightOptions: [Double] {
        Array(Set(stride(from: 50.0, through: 5000.0, by: 50) + [weight])).sorted()
    }

    @discardableResult
    func save() -> Bool {
        guard !hasSaved else { return true }
        guard isActive() else { return false }
        guard let record = HarvestRecord.validated(frequencyPerMonth: frequency, latestWeightKg: weight) else {
            showsError = true
            return false
        }
        guard onSave(record) else { showsError = true; return false }
        hasSaved = true
        onSaved()
        return true
    }
}
