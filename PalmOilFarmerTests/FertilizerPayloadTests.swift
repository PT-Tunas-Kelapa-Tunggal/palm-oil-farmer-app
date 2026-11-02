import CloudKit
import Foundation
import SwiftData
import Testing
@testable import PalmOilFarmer

@MainActor
struct FertilizerPayloadTests {
    private let composition = FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15, magnesium: 0)

    private func garden() -> Garden {
        Garden(id: UUID(), name: "Kebun uji", locationName: "Bintan",
               boundary: GardenBoundary(), plantingYear: 2012, soilType: .mineral)
    }

    private func request() -> PlantationReviewRequest {
        PlantationReviewRequest(
            farmer: FarmerContact(name: "Petani", phone: "08123456789", address: "Bintan"),
            garden: GardenSummary(id: UUID(), name: "Kebun uji", locationName: "Bintan", areaHectares: 2.3),
            boundary: [CoordinatePoint(latitude: 1, longitude: 104)],
            agronomy: AgronomicProfile(
                plantingYear: 2012, soilType: "Mineral",
                fertilizerRecords: [
                    FertilizerUsage(name: "NPK", doseKgPerTree: 0.5, composition: composition),
                    FertilizerUsage(name: "Dolomit", doseKgPerTree: 0.75)
                ],
                fertilizationFrequencyPerYear: 3
            )
        )
    }

    @Test func newDraftCanSaveWithoutBagValues() throws {
        var draft = FertilizerDraft()
        draft.name = "NPK"
        draft.doseKgPerTree = 0.5
        draft.composition = FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15)
        let record = try #require(draft.record)
        #expect(record.bagWeightKg == nil)
        #expect(record.bagCount == nil)
        #expect(record.composition == composition)
        #expect(record.doseKgPerTree == 0.5)

        draft.composition.potassium = nil
        #expect(draft.record == nil)
        draft.name = "Dolomit"
        #expect(draft.record?.composition == nil)
        draft.doseKgPerTree = 0
        #expect(draft.record == nil)
    }

    @Test func localPersistenceKeepsFrequencyCompositionAndUpdates() throws {
        let container = AppConfiguration.makeModelContainer(inMemory: true)
        let store = GardenStore(modelContainer: container)
        var value = garden()
        value.fertilizerRecords = [FertilizerRecord(name: "NPK", doseKgPerTree: 0.5, composition: composition)]
        value.fertilizationFrequencyPerYear = 3
        #expect(store.add(value))
        var reloaded = try #require(GardenStore(modelContainer: container).gardens.first)
        #expect(reloaded.fertilizationFrequencyPerYear == 3)
        #expect(reloaded.fertilizerRecords?.first?.composition == composition)
        #expect(reloaded.fertilizerRecords?.first?.bagCount == nil)

        reloaded.fertilizationFrequencyPerYear = 4
        reloaded.fertilizerRecords?[0].composition?.magnesium = 2
        #expect(store.update(reloaded))
        let updated = try #require(GardenStore(modelContainer: container).gardens.first)
        #expect(updated.fertilizationFrequencyPerYear == 4)
        #expect(updated.fertilizerRecords?.first?.composition?.magnesium == 2)
    }

    @Test func newPayloadUsesCurrentFormAndSurvivesCloudKitRecordRoundTrip() throws {
        let mapper = PlantationDomainMapper()
        let original = request()
        let dto = try mapper.toDTO(from: original)
        let json = try #require(JSONSerialization.jsonObject(with: Data(dto.agronomicJSON.utf8)) as? [String: Any])
        #expect(json["fertilizationFrequencyPerYear"] as? Int == 3)
        let fertilizers = try #require(json["fertilizers"] as? [[String: Any]])
        #expect(fertilizers.count == 2)
        #expect(fertilizers.allSatisfy { $0["bagKg"] == nil && $0["bags"] == nil })
        let npk = try #require(fertilizers[0]["composition"] as? [String: Any])
        #expect(npk["nitrogen"] as? Double == 15)
        #expect(npk["phosphorus"] as? Double == 15)
        #expect(npk["potassium"] as? Double == 15)
        #expect(npk["magnesium"] as? Double == 0)
        #expect(fertilizers[1]["composition"] == nil)

        let cloudRecord = PlantationRecordCKAdapter.toCKRecord(from: dto)
        let returnedDTO = try PlantationRecordCKAdapter.toDTO(from: cloudRecord)
        let returnedRequest = try mapper.toDomain(from: returnedDTO)
        let returnedGarden = mapper.toGarden(from: returnedRequest)
        #expect(returnedGarden.fertilizationFrequencyPerYear == 3)
        #expect(returnedGarden.fertilizerRecords?.first?.composition == composition)
        #expect(returnedGarden.fertilizerRecords?.first?.bagWeightKg == nil)
        #expect(returnedGarden.fertilizerRecords?.last?.doseKgPerTree == 0.75)
        #expect(returnedGarden.fertilizerRecords?.first?.id == original.agronomy.fertilizerRecords.first?.id)
    }

    @Test func legacyPayloadWithoutNewKeysStillDecodesAndRetainsBagData() throws {
        let legacy = """
        {"year":2012,"soil":"Mineral","fertilizers":[{"id":"\(UUID().uuidString)","name":"Urea","bagKg":50,"bags":6,"dosePerTree":0.5}]}
        """
        let mapper = PlantationDomainMapper()
        let dto = PlantationScanRequestRecordDTO(
            recordName: UUID().uuidString, farmerName: "Petani", farmerPhone: "08123456789",
            farmerAddress: "Bintan", gardenID: UUID().uuidString, gardenName: "Lama",
            locationName: "Bintan", areaHectares: 2.3, boundaryJSON: "[]", agronomicJSON: legacy,
            statusCode: 0, submittedAt: .now
        )
        let domain = try mapper.toDomain(from: dto)
        let value = mapper.toGarden(from: domain)
        #expect(value.fertilizationFrequencyPerYear == nil)
        #expect(value.fertilizerRecords?.first?.composition == nil)
        #expect(value.fertilizerRecords?.first?.bagWeightKg == 50)
        #expect(value.fertilizerRecords?.first?.bagCount == 6)
        let encodedAgain = try mapper.toDTO(from: domain)
        let decodedAgain = try mapper.toDomain(from: encodedAgain)
        #expect(decodedAgain.agronomy.fertilizerRecords.first?.bagCount == 6)
    }

    @Test func legacyDeviceDetailsMigrateWithoutOverwritingSyncedValues() throws {
        let suite = "FertilizerMigrationTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacyStore = LocalFertilizerFormStore(defaults: defaults)
        var value = garden()
        let record = FertilizerRecord(name: "NPK", bagWeightKg: 50, bagCount: 6, doseKgPerTree: 0.5)
        value.fertilizerRecords = [record]
        try legacyStore.save(FertilizerFormDetails(frequencyPerYear: 3, compositions: [record.id: composition]),
                             gardenID: value.id)
        let migrated = legacyStore.applyingLegacyDetails(to: value)
        #expect(migrated.fertilizationFrequencyPerYear == 3)
        #expect(migrated.fertilizerRecords?.first?.composition == composition)
        #expect(migrated.fertilizerRecords?.first?.bagCount == 6)

        var synced = migrated
        synced.fertilizationFrequencyPerYear = 4
        synced.fertilizerRecords?[0].composition?.nitrogen = 12
        let notOverwritten = legacyStore.applyingLegacyDetails(to: synced)
        #expect(notOverwritten.fertilizationFrequencyPerYear == 4)
        #expect(notOverwritten.fertilizerRecords?.first?.composition?.nitrogen == 12)

        synced.fertilizerRecords?[0].name = "Urea"
        synced.fertilizerRecords?[0].composition = nil
        #expect(legacyStore.applyingLegacyDetails(to: synced).fertilizerRecords?.first?.composition == nil)
    }

    @Test func legacyLocalFertilizerJSONStillLoads() throws {
        let id = UUID()
        let json = """
        [{"id":"\(id.uuidString)","name":"Urea","bagWeightKg":50,"bagCount":6,"doseKgPerTree":0.5}]
        """
        let records = try JSONDecoder().decode([FertilizerRecord].self, from: Data(json.utf8))
        #expect(records.first?.id == id)
        #expect(records.first?.composition == nil)
        #expect(records.first?.bagWeightKg == 50)
        #expect(records.first?.bagCount == 6)
    }
}
