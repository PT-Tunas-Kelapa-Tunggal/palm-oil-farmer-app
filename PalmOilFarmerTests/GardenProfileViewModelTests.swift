import Foundation
import Observation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenProfileViewModelTests {
    @Test func profileReadsLatestSourceWithoutKeepingAnotherGardenCache() {
        let garden = profileGarden()
        let source = ProfileSourceSpy(gardens: [garden])
        let model = GardenProfileViewModel(garden: garden, source: source, onDeleted: {})
        #expect(!model.isComplete && model.fertilizers.isEmpty)
        var latest = garden
        latest.fertilizerRecords = [profileFertilizer()]
        latest.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 700)
        source.gardens = [latest]
        #expect(model.isComplete && model.garden.harvestRecord?.latestWeightKg == 700)
    }

    @Test func historyWritesMergeWithLatestGardenAndFailedSaveDoesNotPublishDraft() {
        let garden = profileGarden()
        let source = ProfileSourceSpy(gardens: [garden])
        let model = GardenProfileViewModel(garden: garden, source: source, onDeleted: {})
        let fertilizer = profileFertilizer()
        #expect(model.saveFertilizers([fertilizer]))
        #expect(model.saveHarvest(HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 750)))
        #expect(model.garden.fertilizerRecords?.first?.id == fertilizer.id && model.isComplete)
        source.acceptsUpdates = false
        #expect(!model.saveFertilizers([]))
        #expect(model.garden.fertilizerRecords?.first?.id == fertilizer.id)
        #expect(model.garden.createdAt == garden.createdAt && model.garden.boundary.points == garden.boundary.points)
    }

    @Test func detailsSavePreservesHistoryAndReviewUpdatedWhileEditorWasOpen() {
        let original = profileGarden()
        let source = ProfileSourceSpy(gardens: [original])
        let model = GardenProfileViewModel(garden: original, source: source, onDeleted: {})
        let edited = Garden(id: original.id, name: "Baru", locationName: "Snapshot lama", boundary: GardenBoundary(),
                            plantingYear: 2018, soilType: .mineral, plantingMonth: 8)
        var latest = original
        let fertilizer = profileFertilizer()
        latest.fertilizerRecords = [fertilizer]
        latest.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 900)
        latest.review = GardenReview(contact: ReviewContactDetails(name: "Budi", phone: "08123456789", address: "Riau"))
        source.gardens = [latest]
        #expect(model.saveDetails(edited))
        #expect(model.garden.name == "Baru" && model.garden.plantingYear == 2018 && model.garden.plantingMonth == 8)
        #expect(model.garden.fertilizerRecords?.first?.id == fertilizer.id && model.garden.harvestRecord?.latestWeightKg == 900)
        #expect(model.garden.review?.status == .submitted && model.garden.createdAt == original.createdAt)
        #expect(model.garden.locationName == original.locationName && model.garden.boundary.points == original.boundary.points)
    }

    @Test func missingInactiveOrWrongGardenCannotBeResurrectedByEditor() {
        let garden = profileGarden()
        let source = ProfileSourceSpy(gardens: [garden])
        var active = true
        let model = GardenProfileViewModel(garden: garden, source: source, isActive: { active }, onDeleted: {})
        #expect(!model.saveDetails(profileGarden()))
        active = false
        #expect(!model.saveFertilizers([profileFertilizer()]) && !model.saveHarvest(HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 500)))
        active = true
        source.gardens = []
        #expect(!model.isAvailable && !model.saveDetails(garden) && !model.delete())
        #expect(source.updates.isEmpty && source.deletedIDs.isEmpty)
    }

    @Test func deleteFailureCanRetryAndSuccessfulDeletionFinishesOnce() {
        let garden = profileGarden()
        let source = ProfileSourceSpy(gardens: [garden])
        source.acceptsDeletion = false
        var finishes = 0
        let model = GardenProfileViewModel(garden: garden, source: source, onDeleted: { finishes += 1 })
        #expect(!model.delete() && model.showsDeleteError && finishes == 0 && model.isAvailable)
        source.acceptsDeletion = true
        #expect(model.delete() && model.delete())
        #expect(finishes == 1 && source.deletedIDs == [garden.id, garden.id] && !model.isAvailable)
    }

    @Test func reviewUpdatesUseLatestGardenAndRetainCurrentHistory() {
        var garden = profileGarden()
        garden.review = GardenReview(contact: ReviewContactDetails(name: "A", phone: "08123456789", address: "B"))
        let source = ProfileSourceSpy(gardens: [garden])
        let model = GardenProfileViewModel(garden: garden, source: source, onDeleted: {})
        let fertilizer = profileFertilizer()
        source.gardens[0].fertilizerRecords = [fertilizer]
        model.updateReview { $0.advance() }
        model.updateReview { $0.resultsDownloaded = true }
        #expect(model.garden.review?.status == .scheduled && model.garden.review?.resultsDownloaded == true)
        #expect(model.fertilizers.first?.id == fertilizer.id)
    }

    @Test func sharedSourceMutationInvalidatesObservedProfile() async {
        let garden = profileGarden()
        let source = ProfileSourceSpy(gardens: [garden])
        let model = GardenProfileViewModel(garden: garden, source: source, onDeleted: {})
        await confirmation("Shared data changes invalidate the profile") { changed in
            withObservationTracking { _ = model.isComplete } onChange: { changed() }
            source.gardens[0].fertilizerRecords = [profileFertilizer()]
        }
        #expect(model.fertilizers.count == 1)
    }
}
