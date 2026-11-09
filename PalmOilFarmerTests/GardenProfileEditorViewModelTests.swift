import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenProfileEditorViewModelTests {
    private func makeModel(garden: Garden? = nil, isActive: @escaping () -> Bool = { true },
                           onSave: @escaping (HarvestRecord, Int, [FertilizerRecord]) -> Bool = { _, _, _ in true },
                           onSaved: @escaping () -> Void = {}) -> GardenProfileEditorViewModel {
        let model = GardenProfileEditorViewModel(garden: garden ?? profileGarden(),
            isActive: isActive, onSave: onSave, onSaved: onSaved)
        model.monthlyWeightKg = 1500
        model.fertilizers[0].name = "Urea"
        model.fertilizers[0].doseKgPerTree = 1.5
        return model
    }

    @Test func existingRecordsKeepIdentityAndNewRowsStartEmpty() {
        var garden = profileGarden()
        let record = profileFertilizer()
        garden.fertilizerRecords = [record]
        let model = makeModel(garden: garden)
        model.addFertilizer()
        #expect(model.fertilizers.count == 2 && model.fertilizers[0].id == record.id)
        #expect(model.fertilizers[1].isEmpty)
        #expect(model.fertilizers[0].record?.bagCount == 2)
    }

    @Test func partialFertilizerRejectsWholeSaveAndCanBeCorrected() {
        var saves = 0
        let model = makeModel(onSave: { _, _, _ in saves += 1; return true })
        model.addFertilizer()
        model.fertilizers[1].name = "KCl"
        #expect(!model.save() && saves == 0)
        #expect(model.validationIssue?.field == .fertilizerDose(model.fertilizers[1].id))
        model.removeFertilizer(id: model.fertilizers[1].id)
        model.fertilizers[0].name = " Urea \n"
        #expect(model.save() && saves == 1)
    }

    @Test func removingAllFertilizersLeavesAnEmptyRowAndCannotEraseSavedProfile() {
        var saves = 0
        let model = makeModel(onSave: { _, _, _ in saves += 1; return true })
        model.removeFertilizer(id: model.fertilizers[0].id)
        #expect(model.fertilizers.count == 1 && model.fertilizers[0].isEmpty)
        #expect(!model.save() && saves == 0)
    }

    @Test func saveFailureRetainsInputsAndRetryFinishesOnce() {
        var accepts = false, saves = 0, finishes = 0
        let model = makeModel(onSave: { _, _, _ in saves += 1; return accepts },
                              onSaved: { finishes += 1 })
        let originalID = model.fertilizers[0].id
        #expect(!model.save() && !model.hasSaved && finishes == 0)
        #expect(model.errorMessage == "Data tidak dapat disimpan di perangkat. Coba lagi.")
        #expect(model.fertilizers[0].id == originalID && model.monthlyWeightKg == 1500)
        accepts = true
        #expect(model.save() && model.save())
        #expect(saves == 2 && finishes == 1)
    }

    @Test func inactiveEditorRejectsAddRemoveAndSave() {
        var active = true, saves = 0
        let model = makeModel(isActive: { active }, onSave: { _, _, _ in saves += 1; return true })
        let originalID = model.fertilizers[0].id
        active = false
        model.addFertilizer()
        model.removeFertilizer(id: originalID)
        #expect(model.fertilizers.count == 1 && model.fertilizers[0].id == originalID)
        #expect(!model.save() && saves == 0)
    }

    @Test func harvestWeightAndFrequencyValidationRejectInvalidValuesWithoutWriting() {
        var saves = 0
        let model = makeModel(onSave: { _, _, _ in saves += 1; return true })
        for weight in [0.0, -1, .infinity, .nan] {
            model.monthlyWeightKg = weight
            #expect(!model.save() && model.validationIssue?.field == .monthlyHarvestWeight)
        }
        model.monthlyWeightKg = 1500
        for frequency in [0, 32] {
            model.harvestFrequency = frequency
            #expect(!model.save() && model.validationIssue?.field == .harvestFrequency)
        }
        #expect(saves == 0)
    }

    @Test func fertilizationFrequencyUsesSameBoundsAsFormControl() {
        var saves = 0
        let model = makeModel(onSave: { _, _, _ in saves += 1; return true })
        for frequency in [0, 13] {
            model.fertilizationFrequency = frequency
            #expect(!model.save() && model.validationIssue?.field == .fertilizationFrequency)
        }
        #expect(saves == 0)
    }

    @Test func legacyHarvestLoadsMonthlyValueWithoutRoundingAwayCustomWeight() {
        var garden = profileGarden()
        garden.harvestRecord = HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 445)
        let model = GardenProfileEditorViewModel(garden: garden, onSave: { _, _, _ in true }, onSaved: {})
        #expect(model.harvestFrequency == 3 && model.monthlyWeightKg == 1335)
    }
}
