import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenDetailsViewModelTests {
    @Test func requiredFieldsPreventPersistenceAndKeepExistingValidationMessage() {
        var saves = 0, finishes = 0
        let model = GardenDetailsViewModel(locationName: "Dumai", boundary: GardenBoundary(),
            onSave: { _ in saves += 1; return true }, onSaved: { finishes += 1 })
        #expect(model.plantingMonth == 10 && model.plantingYear == nil && model.soilType == nil)
        for step in 0...2 {
            if step == 1 { model.name = "Kebun" }
            if step == 2 { model.plantingYear = 2016 }
            #expect(!model.save() && model.showsSaveError)
        }
        #expect(model.errorMessage == "Lengkapi nama kebun, tahun tanam, dan jenis tanah terlebih dahulu.")
        #expect(saves == 0 && finishes == 0)
    }

    @Test func newGardenUsesTrimmedDetailsAndOriginalCreationPayload() throws {
        let id = UUID(), date = Date(timeIntervalSince1970: 1_700_000_000)
        let boundary = GardenBoundary(points: mappingPoints())
        var saved: Garden?
        var finishes = 0
        let model = GardenDetailsViewModel(locationName: "Dumai", boundary: boundary,
            makeID: { id }, now: { date }, onSave: { saved = $0; return true }, onSaved: { finishes += 1 })
        completeDetails(model)
        model.name = "  Kebun A \n"
        model.plantingMonth = 5
        #expect(model.save())
        let garden = try #require(saved)
        #expect(garden.id == id && garden.createdAt == date && garden.name == "Kebun A")
        #expect(garden.locationName == "Dumai" && garden.boundary.points == boundary.points)
        #expect(garden.plantingYear == 2016 && garden.plantingMonth == 5 && garden.soilType == .peat)
        #expect(garden.fertilizerRecords == nil && garden.harvestRecord == nil && garden.review == nil)
        #expect(finishes == 1 && model.hasSaved && !model.showsSaveError)
    }

    @Test func failedSaveRetainsFormAndRetryDoesNotFinishEarly() {
        var acceptsSave = false
        var saves = 0, finishes = 0
        let model = GardenDetailsViewModel(locationName: "Dumai", boundary: GardenBoundary(points: mappingPoints()),
            onSave: { _ in saves += 1; return acceptsSave }, onSaved: { finishes += 1 })
        completeDetails(model)
        #expect(!model.save() && model.showsSaveError && !model.hasSaved)
        #expect(model.errorMessage == "Data tidak dapat disimpan di perangkat. Coba lagi.")
        #expect(model.name == "Belakang rumah" && model.plantingYear == 2016 && finishes == 0)
        acceptsSave = true
        #expect(model.save() && !model.showsSaveError && model.hasSaved)
        #expect(saves == 2 && finishes == 1)
    }

    @Test func repeatedSuccessfulSaveDoesNotCreateSecondGardenOrNavigation() {
        var saves = 0, finishes = 0
        let model = GardenDetailsViewModel(locationName: "Dumai", boundary: GardenBoundary(points: mappingPoints()),
            onSave: { _ in saves += 1; return true }, onSaved: { finishes += 1 })
        completeDetails(model)
        #expect(model.save())
        #expect(model.save())
        #expect(saves == 1 && finishes == 1)
    }

    @Test func editingPreservesIdentityLocationBoundaryHistoryReviewAndCreationDate() throws {
        let date = Date(timeIntervalSince1970: 1_000)
        let fertilizer = FertilizerRecord(name: "Urea", bagWeightKg: 50, bagCount: 2, doseKgPerTree: 1.5)
        let review = GardenReview(status: .scheduled, contact: ReviewContactDetails(name: "Budi", phone: "08123456789", address: "Riau"),
                                  stageDates: [date, date.addingTimeInterval(60)], resultsDownloaded: true)
        let original = Garden(id: UUID(), name: "Lama", locationName: "Dumai", boundary: GardenBoundary(points: mappingPoints()),
            plantingYear: 2016, soilType: .peat, plantingMonth: 4, fertilizerRecords: [fertilizer],
            harvestRecord: HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 500), review: review, createdAt: date)
        var saved: Garden?
        let model = GardenDetailsViewModel(locationName: original.locationName, boundary: original.boundary, editing: original,
            onSave: { saved = $0; return true }, onSaved: {})
        #expect(model.isEditing && model.name == "Lama" && model.plantingMonth == 4)
        model.name = " Baru "
        model.plantingYear = 2018
        model.soilType = .mineral
        model.plantingMonth = 8
        #expect(model.save())
        let value = try #require(saved)
        #expect(value.id == original.id && value.createdAt == date && value.locationName == original.locationName)
        #expect(value.name == "Baru" && value.plantingYear == 2018 && value.soilType == .mineral && value.plantingMonth == 8)
        #expect(value.boundary.points == original.boundary.points)
        #expect(value.fertilizerRecords?.first?.id == fertilizer.id && value.harvestRecord?.latestWeightKg == 500)
        #expect(value.review?.status == .scheduled && value.review?.stageDates == review.stageDates)
        #expect(value.review?.resultsDownloaded == true && value.review?.contact.phone == "08123456789")
        #expect(original.name == "Lama" && original.plantingMonth == 4)
    }

    @Test func legacyMonthFallbackAndMissingCreationDateRemainCompatible() {
        for storedMonth in [nil, 0, 13, 12] as [Int?] {
            let original = Garden(id: UUID(), name: "Lama", locationName: "Dumai", boundary: GardenBoundary(),
                                  plantingYear: 1800, soilType: .other, plantingMonth: storedMonth)
            var saved: Garden?
            let model = GardenDetailsViewModel(locationName: original.locationName, boundary: original.boundary, editing: original,
                onSave: { saved = $0; return true }, onSaved: {})
            #expect(model.plantingMonth == (storedMonth == 12 ? 12 : 10))
            #expect(model.save())
            #expect(saved?.id == original.id && saved?.createdAt == nil && saved?.plantingYear == 1800)
        }
    }
}
