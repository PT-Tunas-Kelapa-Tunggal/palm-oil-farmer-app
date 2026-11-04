import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenHistoryViewModelTests {
    @Test func fertilizerDraftsPreserveIdentityAndOptionalEmptyRow() {
        let record = profileFertilizer()
        let model = FertilizerHistoryViewModel(records: [record], includesEmptyDraft: true, onSave: { _ in true }, onSaved: {})
        #expect(model.drafts.count == 2 && model.drafts[0].id == record.id && model.drafts[1].isEmpty)
        #expect(model.drafts[0].bagCount == 2 && model.drafts[0].doseKgPerTree == 1.5)
        let empty = FertilizerHistoryViewModel(records: [], onSave: { _ in true }, onSaved: {})
        #expect(empty.drafts.count == 1 && empty.drafts[0].isEmpty)
    }

    @Test func partialFertilizerRowRejectsWholeSaveInsteadOfDroppingIt() {
        var saved: [[FertilizerRecord]] = []
        let record = profileFertilizer()
        let model = FertilizerHistoryViewModel(records: [record], includesEmptyDraft: true,
            onSave: { saved.append($0); return true }, onSaved: {})
        model.drafts[1].name = "KCl"
        #expect(!model.save() && saved.isEmpty)
        #expect(model.errorMessage == "Lengkapi jenis pupuk, berat, jumlah karung, dan dosis dengan nilai lebih dari nol.")
        model.removeDraft(id: model.drafts[1].id)
        model.drafts[0].name = " Urea \n"
        #expect(model.save())
        #expect(saved.first?.first?.id == record.id && saved.first?.first?.name == "Urea")
    }

    @Test func allEmptyFertilizerRowsCanSaveAnEmptyHistory() {
        var savedCount: Int?
        let model = FertilizerHistoryViewModel(records: [], onSave: { savedCount = $0.count; return true }, onSaved: {})
        #expect(model.save() && savedCount == 0)
    }

    @Test func draftActionsAndKeyboardOrderUseCurrentRows() throws {
        let model = FertilizerHistoryViewModel(records: [profileFertilizer()], onSave: { _ in true }, onSaved: {})
        let first = model.drafts[0].id
        let second = try #require(model.addDraft())
        model.selectType("KCl", for: second)
        model.selectType("ZA", for: UUID())
        #expect(model.drafts[1].name == "KCl")
        #expect(model.nextField(after: FertilizerField(draftID: first, kind: .bagWeight)) == FertilizerField(draftID: first, kind: .bagCount))
        #expect(model.nextField(after: FertilizerField(draftID: first, kind: .dose)) == FertilizerField(draftID: second, kind: .bagWeight))
        #expect(model.nextField(after: FertilizerField(draftID: second, kind: .dose)) == nil)
        model.removeDraft(id: first)
        #expect(model.nextField(after: FertilizerField(draftID: first, kind: .dose)) == nil)
    }

    @Test func fertilizerSaveFailureRetainsDraftAndRetryFinishesOnce() {
        let record = profileFertilizer()
        var accepts = false, finishes = 0, calls = 0
        let model = FertilizerHistoryViewModel(records: [record],
            onSave: { _ in calls += 1; return accepts }, onSaved: { finishes += 1 })
        #expect(!model.save() && !model.hasSaved && finishes == 0)
        #expect(model.errorMessage == "Data tidak dapat disimpan di perangkat. Coba lagi.")
        #expect(model.drafts.first?.id == record.id)
        accepts = true
        #expect(model.save() && model.save())
        #expect(calls == 2 && finishes == 1)
    }

    @Test func cancelledEditorRejectsDraftActionsAndPersistence() {
        var active = true, saves = 0
        let model = FertilizerHistoryViewModel(records: [profileFertilizer()], isActive: { active },
            onSave: { _ in saves += 1; return true }, onSaved: {})
        let original = model.drafts[0]
        active = false
        #expect(model.addDraft() == nil)
        model.selectType("KCl", for: original.id)
        model.removeDraft(id: original.id)
        #expect(!model.save() && saves == 0 && model.drafts.first?.name == original.name)
    }

    @Test func harvestDefaultsClampingAndCustomWeightRemainCompatible() {
        let empty = HarvestHistoryViewModel(record: nil, onSave: { _ in true }, onSaved: {})
        #expect(empty.frequency == 2 && empty.weight == 450)
        let low = HarvestHistoryViewModel(record: HarvestRecord(frequencyPerMonth: 0, latestWeightKg: 445), onSave: { _ in true }, onSaved: {})
        #expect(low.frequency == 1 && low.weightOptions.contains(445) && low.weightOptions.contains(450))
        #expect(low.weightOptions == low.weightOptions.sorted())
        let high = HarvestHistoryViewModel(record: HarvestRecord(frequencyPerMonth: 99, latestWeightKg: 500), onSave: { _ in true }, onSaved: {})
        #expect(high.frequency == 31)
    }

    @Test func harvestValidationRejectsInvalidWeightsAndFrequencyWithoutWriting() {
        var calls = 0
        let model = HarvestHistoryViewModel(record: nil, onSave: { _ in calls += 1; return true }, onSaved: {})
        for weight in [0.0, -1, .infinity, .nan] {
            model.weight = weight
            #expect(!model.save() && model.showsError)
        }
        model.weight = 500
        for frequency in [0, 32] {
            model.frequency = frequency
            #expect(!model.save())
        }
        #expect(calls == 0)
    }

    @Test func harvestFailureRetryAndCancellationDoNotFinishEarlyOrDuplicateWrites() {
        var active = true, accepts = false, calls = 0, finishes = 0
        let model = HarvestHistoryViewModel(record: nil, isActive: { active },
            onSave: { _ in calls += 1; return accepts }, onSaved: { finishes += 1 })
        #expect(!model.save() && model.showsError && finishes == 0)
        active = false
        #expect(!model.save() && calls == 1)
        active = true
        accepts = true
        #expect(model.save() && model.save())
        #expect(calls == 2 && finishes == 1)
    }
}
