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
        profile.coordinator.open(.profile)
        let editor = profile.makeProfileEditor(try #require(profile.coordinator.sheet))
        editor.fertilizers[0].name = "Urea"
        editor.fertilizers[0].doseKgPerTree = 1.5
        editor.harvestFrequency = 3
        editor.monthlyWeightKg = 2250
        editor.fertilizationFrequency = 2
        let recordID = editor.fertilizers[0].id
        #expect(editor.save())
        #expect(profile.viewModel.isComplete && profile.coordinator.sheet == nil)
        let reopened = makeTestGardenStore(in: app.modelContainer)
        #expect(reopened.gardens.first?.fertilizerRecords?.first?.id == recordID)
        #expect(reopened.gardens.first?.harvestRecord?.latestWeightKg == 750)
        #expect(app.gardenListViewModel.presentation(showsFilter: true).gardens.first?.stage == .readyForReview)
        profile.coordinator.sheetDidDismiss()
        profile.coordinator.open(.profile)
        let empty = profile.makeProfileEditor(try #require(profile.coordinator.sheet))
        empty.removeFertilizer(id: recordID)
        #expect(!empty.save() && profile.viewModel.isComplete)
        #expect(makeTestGardenStore(in: app.modelContainer).gardens.first?.fertilizerRecords?.first?.id == recordID)
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
        editor.name = "Nama baru"
        editor.plantingYear = 2018
        editor.plantingMonth = 9
        #expect(editor.save())
        let restored = try #require(makeTestGardenStore(in: app.modelContainer).gardens.first)
        #expect(restored.name == "Nama baru" && restored.plantingYear == 2018 && restored.plantingMonth == 9)
        #expect(restored.fertilizerRecords?.first?.id == fertilizer.id && restored.harvestRecord?.latestWeightKg == 900)
        #expect(restored.createdAt == garden.createdAt && restored.boundary.points == garden.boundary.points)
    }

    @Test func cancelledOrWrongEditorSessionCannotWriteToSharedStore() throws {
        let garden = profileGarden()
        let source = ProfileSourceSpy(gardens: [garden])
        let profile = makeProfileTestFlow(garden: garden, source: source)
        profile.coordinator.open(.profile)
        let first = try #require(profile.coordinator.sheet)
        let old = profile.makeProfileEditor(first)
        old.monthlyWeightKg = 1000
        old.fertilizers[0].name = "Urea"
        old.fertilizers[0].doseKgPerTree = 1
        profile.coordinator.closeSheet(first)
        #expect(!old.save() && source.updates.isEmpty)
        profile.coordinator.sheetDidDismiss()
        profile.coordinator.open(.details)
        let current = try #require(profile.coordinator.sheet)
        let wrong = profile.makeProfileEditor(current)
        wrong.monthlyWeightKg = 1000
        wrong.fertilizers[0].name = "Urea"
        wrong.fertilizers[0].doseKgPerTree = 1
        #expect(!wrong.save() && !old.save() && source.updates.isEmpty)
        profile.coordinator.close()
        #expect(!profile.makeProfileEditor(current).save() && source.updates.isEmpty)
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
