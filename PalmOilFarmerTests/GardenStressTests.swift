import Foundation
import CoreLocation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenStressTests {
    private func garden() -> Garden {
        Garden(id: UUID(), name: "Kebun", locationName: "Dumai",
               boundary: GardenBoundary(), plantingYear: 2016, soilType: .peat)
    }

    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func unreadableDataCannotBeOverwrittenAfterAlertDismissal() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appending(path: "gardens.json")
        let original = Data("damaged existing data".utf8)
        try original.write(to: file)
        let store = GardenStore(fileURL: file)
        store.errorMessage = nil
        #expect(!store.add(garden()))
        #expect(store.gardens.isEmpty)
        #expect(try Data(contentsOf: file) == original)
    }

    @Test func duplicateGardenIDIsRejected() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appending(path: "gardens.json")
        let store = GardenStore(fileURL: file)
        let value = garden()
        #expect(store.add(value))
        #expect(!store.add(value))
        #expect(store.gardens.count == 1)
        #expect(GardenStore(fileURL: file).gardens.count == 1)
    }

    @Test func invalidCoordinatesAreRejected() {
        let points = [
            GardenCoordinate(CLLocationCoordinate2D(latitude: 95, longitude: 0)),
            GardenCoordinate(CLLocationCoordinate2D(latitude: 95, longitude: 0.001)),
            GardenCoordinate(CLLocationCoordinate2D(latitude: 95.001, longitude: 0))
        ]
        #expect(!GardenBoundary(points: points).isValid)
    }

    @Test func failedEncodingPreservesSavedGarden() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appending(path: "gardens.json")
        let store = GardenStore(fileURL: file)
        var value = garden()
        #expect(store.add(value))
        let original = try Data(contentsOf: file)
        value.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: .infinity)
        #expect(!store.update(value))
        #expect(store.gardens.first?.harvestRecord == nil)
        #expect(try Data(contentsOf: file) == original)
    }

    @Test func failedDeletePreservesPublishedGarden() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appending(path: "gardens.json")
        let store = GardenStore(fileURL: file)
        let value = garden()
        #expect(store.add(value))
        // Move the temporary test file aside and block its destination with a directory.
        let backup = folder.appending(path: "backup.json")
        try FileManager.default.moveItem(at: file, to: backup)
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: true)
        #expect(!store.delete(value))
        #expect(store.gardens.first?.id == value.id)
        #expect(GardenStore(fileURL: backup).gardens.first?.id == value.id)
    }

    @Test func thousandGardensRoundTripWithoutLosingHistory() throws {
        let folder = try directory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let persistence = GardenPersistence(fileURL: folder.appending(path: "gardens.json"))
        let values = (0..<1_000).map { index in
            var value = garden()
            value.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: Double(index))
            return value
        }
        try persistence.save(values)
        let restored = try persistence.load()
        #expect(restored.map(\.id) == values.map(\.id))
        #expect(restored.map { $0.harvestRecord?.latestWeightKg } == values.map { $0.harvestRecord?.latestWeightKg })
    }
}
