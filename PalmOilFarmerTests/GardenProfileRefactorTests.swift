import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenProfileRefactorTests {
    private var composition: FertilizerComposition {
        FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15, magnesium: 2)
    }

    @Test func customNPKRoundTripKeepsIdentityDoseAndAllNutrients() throws {
        let record = FertilizerRecord(name: "NPK", bagWeightKg: nil, bagCount: nil,
                                      doseKgPerTree: 0.5, composition: composition)
        let draft = FertilizerInputDraft(record: record)
        #expect(draft.kind == .npk)
        let saved = try #require(draft.record)
        #expect(saved.id == record.id && saved.doseKgPerTree == 0.5)
        #expect(saved.composition == composition)
        let decoded = try JSONDecoder().decode(FertilizerRecord.self, from: JSONEncoder().encode(saved))
        #expect(decoded.composition == composition && decoded.bagCount == nil)
    }

    @Test func partialZeroAndNonFiniteNPKCannotProduceRecords() {
        let invalid: [FertilizerComposition] = [
            FertilizerComposition(nitrogen: 15),
            FertilizerComposition(nitrogen: 0, phosphorus: 0, potassium: 0),
            FertilizerComposition(nitrogen: -1, phosphorus: 15, potassium: 15),
            FertilizerComposition(nitrogen: .nan, phosphorus: 15, potassium: 15),
            FertilizerComposition(nitrogen: 15, phosphorus: .infinity, potassium: 15),
            FertilizerComposition(nitrogen: 60, phosphorus: 30, potassium: 15),
            FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15, magnesium: 101)
        ]
        for value in invalid {
            var draft = FertilizerInputDraft()
            draft.kind = .npk
            draft.doseKgPerTree = 0.5
            draft.composition = value
            #expect(!value.isValid && draft.record == nil)
        }
    }

    @Test func omittedMagnesiumSavesAsZeroAndExplicitZeroNutrientIsAllowed() throws {
        var draft = FertilizerInputDraft()
        draft.kind = .npk
        draft.doseKgPerTree = 0.5
        draft.composition = FertilizerComposition(nitrogen: 15, phosphorus: 0, potassium: 15)
        #expect(try #require(draft.record).composition?.magnesium == 0)
    }

    @Test func decoratedNPKPrefersExistingStructuredComposition() throws {
        let old = FertilizerRecord(name: "NPK 16-16-16", bagWeightKg: 50, bagCount: 3,
                                   doseKgPerTree: 0.5, composition: composition)
        let saved = try #require(FertilizerInputDraft(record: old).record)
        #expect(saved.name == "NPK" && saved.composition == composition)
        #expect(saved.id == old.id && saved.bagCount == 3 && saved.bagWeightKg == 50)
    }

    @Test func legacyNameParsingRejectsMalformedTokensWithoutRenamingOrDataLoss() throws {
        for name in ["NPK Super", "NPK 15-x-15-15", "NPK 15--15-15", "NPK 120-15-15"] {
            let old = FertilizerRecord(name: name, bagWeightKg: 50, bagCount: 2, doseKgPerTree: 0.5)
            let saved = try #require(FertilizerInputDraft(record: old).record)
            #expect(saved.name == name && saved.id == old.id)
            #expect(saved.composition == nil && saved.bagCount == 2)
        }
        let branded = FertilizerRecord(name: "NPK Super", bagWeightKg: nil, bagCount: nil,
                                       doseKgPerTree: 0.5, composition: composition)
        #expect(try #require(FertilizerInputDraft(record: branded).record).composition == composition)
    }

    @Test func legacyNumericNameSupportsOptionalFourthNutrient() throws {
        let old = FertilizerRecord(name: "NPK 15-15-15-2", bagWeightKg: 50, bagCount: 2, doseKgPerTree: 0.5)
        let draft = FertilizerInputDraft(record: old)
        #expect(draft.kind == .npk)
        #expect(try #require(draft.record).composition == composition)
    }

    @Test func profileDraftRetainsCompositionWithAndWithoutBagData() throws {
        for hasBags in [false, true] {
            let old = FertilizerRecord(name: "NPK", bagWeightKg: hasBags ? 50 : nil,
                bagCount: hasBags ? 2 : nil, doseKgPerTree: 0.5, composition: composition)
            var draft = FertilizerInputDraft(record: old)
            draft.doseKgPerTree = 1
            let saved = try #require(draft.record)
            #expect(saved.id == old.id && saved.composition == composition && saved.doseKgPerTree == 1)
            draft.name = "Urea"
            #expect(try #require(draft.record).composition == nil)
        }
    }

    @Test func changingTypeHidesNutrientsWithoutDiscardingInProgressNPKInput() throws {
        var draft = FertilizerInputDraft()
        draft.kind = .npk
        draft.composition = composition
        draft.doseKgPerTree = 0.5
        draft.kind = .urea
        #expect(try #require(draft.record).composition == nil)
        draft.kind = .npk
        #expect(try #require(draft.record).composition == composition)
    }

    @Test func keyboardOrderUsesCurrentTypeAndCurrentRows() throws {
        let model = GardenProfileEditorViewModel(garden: profileGarden(), onSave: { _, _, _ in true }, onSaved: {})
        let first = try #require(model.fertilizers.first?.id)
        model.fertilizers[0].kind = .npk
        #expect(model.nextField(after: .monthlyHarvestWeight) == .fertilizerNutrient(first, .nitrogen))
        model.fertilizers[0].kind = .urea
        #expect(model.nextField(after: .monthlyHarvestWeight) == .fertilizerDose(first))
        model.addFertilizer()
        let second = try #require(model.fertilizers.last?.id)
        #expect(model.nextField(after: .fertilizerDose(first)) == .fertilizerDose(second))
        model.removeFertilizer(id: second)
        #expect(model.nextField(after: .fertilizerDose(first)) == nil)
        #expect(model.nextField(after: .fertilizerDose(second)) == nil)
    }

    @Test func summaryEditWaitsForDismissalAndRejectsStaleCallbacks() throws {
        let coordinator = GardenProfileCoordinator()
        coordinator.open(.summary)
        let summary = try #require(coordinator.sheet)
        coordinator.editProfile(from: summary)
        #expect(coordinator.sheet == nil && !coordinator.canDeleteNow)
        coordinator.sheetDidDismiss()
        #expect(coordinator.sheet?.kind == .profile)
        let editor = try #require(coordinator.sheet)
        coordinator.editProfile(from: summary)
        #expect(coordinator.isCurrent(editor))
    }

    @Test func reviewInformationTransitionIsCancelledWhenProfileCloses() throws {
        let coordinator = GardenProfileCoordinator()
        coordinator.open(.reviewInformation)
        let info = try #require(coordinator.sheet)
        coordinator.applyForReview(from: info, action: .request)
        coordinator.close()
        coordinator.sheetDidDismiss()
        #expect(coordinator.sheet == nil && coordinator.isFinished)
    }

    @Test func informationRoutesToExistingReviewStatusAfterDismissal() throws {
        let coordinator = GardenProfileCoordinator()
        coordinator.open(.reviewInformation)
        coordinator.applyForReview(from: try #require(coordinator.sheet), action: .status)
        #expect(!coordinator.showsReviewStatus)
        coordinator.sheetDidDismiss()
        #expect(coordinator.sheet == nil && coordinator.showsReviewStatus)
    }

    @Test func submittedReviewWinsOverEarlierPendingFetch() async {
        let repository = ControlledProfileReviewRepository()
        let presentation = GardenProfileReviewPresentation()
        var saved = PlantationReviewRequest(garden: profileGarden(),
            contact: ReviewContactDetails(name: "Petani", phone: "08123456789", address: "Riau"))
        saved.status = .submitted
        let pending = Task { await presentation.load(for: saved.garden.id, repository: repository) }
        await repository.waitForRequest(1)
        presentation.submitted(saved)
        var stale = saved
        stale.status = .scheduled
        repository.finish(1, with: .success(stale))
        await pending.value
        #expect(presentation.activeStatus == .submitted)
    }
}
