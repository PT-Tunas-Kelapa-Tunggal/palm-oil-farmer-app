import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenProfileDesignTests {
    private func fill(_ model: GardenProfileEditorViewModel) {
        model.harvestFrequency = 3
        model.monthlyWeightKg = 420
        model.fertilizationFrequency = 4
        model.fertilizers[0].name = "NPK"
        model.fertilizers[0].doseKgPerTree = 0.5
        model.fertilizers[0].composition = FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15)
    }

    @Test func combinedFormSavesOnceAndPreservesLatestGardenDetails() throws {
        let garden = profileGarden()
        let source = ProfileSourceSpy(gardens: [garden])
        let profile = makeProfileTestViewModel(garden: garden, source: source)
        profile.open(.profile)
        let sheet = try #require(profile.sheet)
        let model = profile.makeProfileEditor(for: sheet)
        fill(model)
        model.addFertilizer() // An untouched extra card is ignored.
        var latest = garden
        latest = Garden(id: latest.id, name: "Nama terbaru", locationName: latest.locationName,
                        boundary: latest.boundary, plantingYear: latest.plantingYear, soilType: latest.soilType)
        source.gardens = [latest]
        #expect(model.save())
        #expect(model.save())
        #expect(source.updates.count == 1)
        let saved = try #require(source.gardens.first)
        #expect(saved.name == "Nama terbaru")
        #expect(saved.fertilizationFrequencyPerYear == 4)
        #expect(saved.profileUpdatedAt != nil)
        #expect(saved.harvestRecord?.monthlyWeightKg == 420)
        #expect(saved.harvestRecord?.latestWeightKg == 140)
        #expect(saved.fertilizerRecords?.count == 1)
        #expect(saved.fertilizerRecords?.first?.bagCount == nil)
        #expect(profile.sheet == nil)
    }

    @Test func partialOrInvalidNPKCannotWriteAndFailedPersistenceCanRetry() {
        var writes = 0
        var accepts = false
        let model = GardenProfileEditorViewModel(garden: profileGarden(), onSave: { _, _, _ in
            writes += 1
            return accepts
        }, onSaved: {})
        fill(model)
        model.fertilizers[0].composition.nitrogen = 90
        #expect(!model.save() && writes == 0)
        model.fertilizers[0].composition.nitrogen = 15
        model.addFertilizer()
        model.fertilizers[1].name = "Urea"
        #expect(!model.save() && writes == 0)
        model.removeFertilizer(id: model.fertilizers[1].id)
        #expect(!model.save() && writes == 1 && !model.hasSaved)
        accepts = true
        #expect(model.save() && writes == 2 && model.hasSaved)
    }

    @Test func dismissedAndWrongSessionsCannotSave() throws {
        let garden = profileGarden()
        let source = ProfileSourceSpy(gardens: [garden])
        let profile = makeProfileTestViewModel(garden: garden, source: source)
        profile.open(.profile)
        let sheet = try #require(profile.sheet)
        let old = profile.makeProfileEditor(for: sheet)
        fill(old)
        profile.closeSheet(sheet)
        #expect(!old.save() && source.updates.isEmpty)
        profile.sheetDidDismiss()
        profile.open(.details)
        let wrong = profile.makeProfileEditor(for: try #require(profile.sheet))
        fill(wrong)
        #expect(!wrong.save() && !old.save() && source.updates.isEmpty)
    }

    @Test func legacyRecordKeepsBagsAndConvertsPerHarvestWeightWithoutDataLoss() throws {
        var garden = profileGarden()
        garden.fertilizerRecords = [FertilizerRecord(name: "NPK 15-15-15", bagWeightKg: 50, bagCount: 6, doseKgPerTree: 0.5)]
        garden.harvestRecord = HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 140)
        let model = GardenProfileEditorViewModel(garden: garden, onSave: { harvest, _, records in
            #expect(harvest.latestWeightKg == 140 && harvest.averageMonthlyWeightKg == 420)
            #expect(records[0].bagWeightKg == 50 && records[0].bagCount == 6)
            #expect(records[0].composition?.label == "15-15-15")
            return true
        }, onSaved: {})
        #expect(model.monthlyWeightKg == 420)
        #expect(model.save())
        let data = try JSONEncoder().encode(garden)
        let decoded = try JSONDecoder().decode(Garden.self, from: data)
        #expect(decoded.fertilizationFrequencyPerYear == nil)
        #expect(decoded.profileUpdatedAt == nil)
        #expect(decoded.fertilizerRecords?.first?.composition == nil)
    }

    @Test func newProfileSurvivesSwiftDataAndReviewDTORoundTrip() throws {
        let container = AppConfiguration.makeModelContainer(inMemory: true)
        let store = makeTestGardenStore(in: container)
        let garden = profileGarden()
        #expect(store.add(garden))
        let profile = GardenProfileFactory(source: GardenProfileRepository(gardens: store), reviewRepository: ReviewRepositoryStub(),
            reviewRequestFactory: ReviewRequestFactory(submission: SubmitGardenReview(gateway: store)))
            .makeViewModel(garden: garden)
        profile.open(.profile)
        let model = profile.makeProfileEditor(for: try #require(profile.sheet))
        fill(model)
        #expect(model.save())
        let saved = try #require(makeTestGardenStore(in: container).gardens.first)
        #expect(saved.fertilizationFrequencyPerYear == 4)
        #expect(saved.profileUpdatedAt != nil)
        #expect(saved.harvestRecord?.averageMonthlyWeightKg == 420)
        #expect(saved.fertilizerRecords?.first?.composition?.nitrogen == 15)
        let request = PlantationReviewRequest(garden: saved,
            contact: ReviewContactDetails(name: "Petani", phone: "081234567890", address: "Dumai"))
        let mapper = PlantationDomainMapper()
        let restored = Garden(reviewRequest: try mapper.toDomain(from: mapper.toDTO(from: request)))
        #expect(restored.fertilizationFrequencyPerYear == 4)
        #expect(restored.harvestRecord?.averageMonthlyWeightKg == 420)
        #expect(restored.fertilizerRecords?.first?.composition?.potassium == 15)
        #expect(restored.fertilizerRecords?.first?.bagWeightKg == nil)
    }
}
