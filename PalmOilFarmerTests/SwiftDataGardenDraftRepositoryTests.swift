import Foundation
import SwiftData
import Testing
@testable import PalmOilFarmer

@MainActor
struct SwiftDataGardenDraftRepositoryTests {
    @Test func existingDraftFieldsSurviveRepositoryUpdateAndDiskReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "DraftPlantations.store")
        let id = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let fertilizer = FertilizerRecord(name: "Urea", bagWeightKg: 50, bagCount: 3, doseKgPerTree: 1.5)
        let points = [GardenCoordinate(latitude: 1, longitude: 104), GardenCoordinate(latitude: 1.1, longitude: 104)]

        do {
            let container = try diskContainer(at: url)
            let context = ModelContext(container)
            // Seed the existing persisted fields directly, independently of the new repository.
            let model = DraftPlantationRequest(
                id: id, name: "Sebelum", locationName: "Dumai", locationSubtitle: "Riau",
                latitude: 1, longitude: 104,
                boundaryData: try JSONEncoder().encode(points),
                plantingYear: 2016, plantingMonth: 5, soilTypeRawValue: SoilType.peat.rawValue,
                fertilizerData: try JSONEncoder().encode([fertilizer]),
                harvestData: try JSONEncoder().encode(HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 500)),
                farmerName: "Budi", farmerPhone: "+62 8123456789", farmerAddress: "Alamat",
                createdAt: createdAt, isBoundaryMapped: true
            )
            context.insert(model)
            try context.save()
        }

        do {
            let repository = SwiftDataGardenDraftRepository(modelContainer: try diskContainer(at: url))
            let snapshot = try repository.loadDrafts()
            let garden = try #require(snapshot.gardens.first)
            #expect(snapshot.locations.isEmpty)
            #expect(garden.id == id && garden.boundary.points == points)
            #expect(garden.fertilizerRecords?.first?.id == fertilizer.id)
            #expect(garden.plantingMonth == 5 && garden.soilType == .peat)
            #expect(garden.harvestRecord?.latestWeightKg == 500)
            let updated = Garden(
                id: garden.id, name: "Sesudah", locationName: garden.locationName,
                boundary: garden.boundary, plantingYear: garden.plantingYear, soilType: garden.soilType,
                plantingMonth: garden.plantingMonth, fertilizerRecords: garden.fertilizerRecords,
                harvestRecord: HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 750),
                createdAt: garden.createdAt
            )
            #expect(try repository.update(updated))
        }

        let context = ModelContext(try diskContainer(at: url))
        let saved = try #require(context.fetch(FetchDescriptor<DraftPlantationRequest>()).first)
        #expect(saved.id == id && saved.name == "Sesudah")
        #expect(saved.harvestRecord?.frequencyPerMonth == 3 && saved.harvestRecord?.latestWeightKg == 750)
        #expect(saved.createdAt == createdAt && saved.isBoundaryMapped)
        #expect(saved.locationName == "Dumai" && saved.locationSubtitle == "Riau")
        #expect(saved.latitude == 1 && saved.longitude == 104)
        #expect(saved.farmerName == "Budi" && saved.farmerPhone == "+62 8123456789" && saved.farmerAddress == "Alamat")
        #expect(saved.boundary.points == points && saved.fertilizerRecords.first?.id == fertilizer.id)
    }

    @Test func snapshotsKeepMappedAndUnmappedDraftsInCreationOrder() throws {
        let container = AppConfiguration.makeModelContainer(inMemory: true)
        let repository = SwiftDataGardenDraftRepository(modelContainer: container)
        let context = ModelContext(container)
        for (name, mapped, timestamp) in [("Lama", true, 1.0), ("Lokasi", false, 2.0), ("Baru", true, 3.0)] {
            context.insert(DraftPlantationRequest(
                name: name, locationName: name, createdAt: Date(timeIntervalSince1970: timestamp), isBoundaryMapped: mapped
            ))
        }
        try context.save()
        let snapshot = try repository.loadDrafts()
        #expect(snapshot.gardens.map(\.name) == ["Baru", "Lama"])
        #expect(snapshot.locations.map(\.name) == ["Lokasi"])
        #expect(try !repository.deleteDraft(id: UUID()))
        #expect(try repository.loadDrafts().gardens.count == 2)
    }

    private func diskContainer(at url: URL) throws -> ModelContainer {
        let schema = Schema([DraftPlantationRequest.self])
        let configuration = ModelConfiguration(schema: schema, url: url, allowsSave: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
