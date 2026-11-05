import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenProfilePersistenceTests {
    private func dependencies(repository: (any FarmerReviewRepository)? = nil) -> AppDependencies {
        AppDependencies(modelContainer: AppConfiguration.makeModelContainer(inMemory: true),
            reviewRepository: repository ?? ReviewRepositoryStub(), registrationServices: makeTestRegistrationServices,
            mappingAuthorization: makeTestMappingAuthorization)
    }

    @Test func profileHistoryFlowPersistsAndChangesHomeReadinessWithoutASecondCache() throws {
        let app = dependencies()
        let garden = profileGarden()
        #expect(app.gardenStore.add(garden))
        let profile = app.profileFactory.makeFlow(garden: garden)
        profile.coordinator.open(.fertilizer)
        let fertilizerSheet = try #require(profile.coordinator.sheet)
        let fertilizer = profile.makeFertilizerEditor(fertilizerSheet)
        fertilizer.viewModel.drafts[0].name = "Urea"
        fertilizer.viewModel.drafts[0].bagWeightKg = 50
        fertilizer.viewModel.drafts[0].bagCount = 2
        fertilizer.viewModel.drafts[0].doseKgPerTree = 1.5
        let recordID = fertilizer.viewModel.drafts[0].id
        #expect(fertilizer.viewModel.save())
        #expect(!profile.viewModel.isComplete && profile.coordinator.sheet == nil)
        profile.coordinator.sheetDidDismiss()
        profile.coordinator.open(.harvest)
        let harvest = profile.makeHarvestEditor(try #require(profile.coordinator.sheet))
        harvest.viewModel.frequency = 3
        harvest.viewModel.weight = 750
        #expect(harvest.viewModel.save())
        #expect(profile.viewModel.isComplete)
        let reopened = makeTestGardenStore(in: app.modelContainer)
        #expect(reopened.gardens.first?.fertilizerRecords?.first?.id == recordID)
        #expect(reopened.gardens.first?.harvestRecord?.latestWeightKg == 750)
        #expect(app.gardenListViewModel.presentation(showsFilter: true).gardens.first?.stage == .readyForReview)
        profile.coordinator.sheetDidDismiss()
        profile.coordinator.open(.fertilizer)
        let empty = profile.makeFertilizerEditor(try #require(profile.coordinator.sheet))
        empty.viewModel.removeDraft(id: recordID)
        #expect(empty.viewModel.save() && !profile.viewModel.isComplete)
        #expect(makeTestGardenStore(in: app.modelContainer).gardens.first?.fertilizerRecords == nil)
    }

    @Test func detailsEditorPreservesHistoryChangedAfterOpeningAndPersistsItsOwnFields() throws {
        let app = dependencies()
        let garden = profileGarden()
        #expect(app.gardenStore.add(garden))
        let profile = app.profileFactory.makeFlow(garden: garden)
        profile.coordinator.open(.details)
        let editor = profile.makeDetailsEditor(try #require(profile.coordinator.sheet))
        var latest = garden
        let fertilizer = profileFertilizer()
        latest.fertilizerRecords = [fertilizer]
        latest.harvestRecord = HarvestRecord(frequencyPerMonth: 4, latestWeightKg: 900)
        #expect(app.gardenStore.update(latest))
        editor.viewModel.name = "Nama baru"
        editor.viewModel.plantingYear = 2018
        editor.viewModel.plantingMonth = 9
        #expect(editor.viewModel.save())
        let restored = try #require(makeTestGardenStore(in: app.modelContainer).gardens.first)
        #expect(restored.name == "Nama baru" && restored.plantingYear == 2018 && restored.plantingMonth == 9)
        #expect(restored.fertilizerRecords?.first?.id == fertilizer.id && restored.harvestRecord?.latestWeightKg == 900)
        #expect(restored.createdAt == garden.createdAt && restored.boundary.points == garden.boundary.points)
    }

    @Test func cancelledOrWrongEditorSessionCannotWriteToSharedStore() throws {
        let garden = profileGarden()
        let source = ProfileSourceSpy(gardens: [garden])
        let profile = makeProfileTestFlow(garden: garden, source: source)
        profile.coordinator.open(.harvest)
        let first = try #require(profile.coordinator.sheet)
        let old = profile.makeHarvestEditor(first)
        old.coordinator.close()
        #expect(!old.viewModel.save() && source.updates.isEmpty)
        profile.coordinator.sheet = nil
        profile.coordinator.sheetDidDismiss()
        profile.coordinator.open(.fertilizer)
        let current = try #require(profile.coordinator.sheet)
        let wrong = profile.makeHarvestEditor(current)
        #expect(!wrong.viewModel.save() && !old.viewModel.save() && source.updates.isEmpty)
        profile.coordinator.close()
        #expect(!profile.makeFertilizerEditor(current).viewModel.save() && source.updates.isEmpty)
    }

    @Test func submittedHistoryEditsAndDeleteRetainExistingInMemoryOnlyPolicy() async throws {
        var garden = profileGarden()
        garden.fertilizerRecords = [profileFertilizer()]
        garden.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 500)
        let request = PlantationReviewRequest(garden: garden,
            contact: ReviewContactDetails(name: "Budi", phone: "08123456789", address: "Riau"))
        let app = dependencies(repository: ReviewRepositoryStub(requests: [request]))
        await app.gardenStore.refreshRemote()
        let remote = try #require(app.gardenStore.gardens.first)
        let profile = app.profileFactory.makeFlow(garden: remote)
        #expect(profile.viewModel.saveHarvest(HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 800)))
        #expect(profile.viewModel.garden.harvestRecord?.latestWeightKg == 800)
        #expect(makeTestGardenStore(in: app.modelContainer).gardens.isEmpty)
        await app.gardenStore.refreshRemote()
        #expect(profile.viewModel.garden.harvestRecord?.latestWeightKg == 500)
        #expect(profile.viewModel.delete() && app.gardenStore.gardens.isEmpty)
        await app.gardenStore.refreshRemote()
        #expect(app.gardenStore.gardens.first?.id == garden.id)
    }

    @Test func deleteUsesMainStoreRemovesOnlySelectedGardenAndClosesProfile() throws {
        let app = dependencies()
        let garden = profileGarden(), other = profileGarden()
        #expect(app.gardenStore.add(garden) && app.gardenStore.add(other))
        let profile = app.profileFactory.makeFlow(garden: garden)
        #expect(profile.viewModel.delete() && profile.coordinator.isFinished)
        #expect(app.gardenStore.gardens.map(\.id) == [other.id])
        #expect(makeTestGardenStore(in: app.modelContainer).gardens.map(\.id) == [other.id])
        #expect(app.gardenListViewModel.presentation(showsFilter: true).items.map(\.id) == [other.id])
    }
}
