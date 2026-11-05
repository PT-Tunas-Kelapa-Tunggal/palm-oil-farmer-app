import Foundation
import CoreLocation
import Testing
import SwiftData
@testable import PalmOilFarmer

@MainActor
struct PalmOilFarmerTests {
    private func garden() -> Garden {
        Garden(id: UUID(), name: "Kebun uji", locationName: "Dumai",
               boundary: GardenBoundary(), plantingYear: 2016, soilType: .peat)
    }

    private func makeContainer() -> ModelContainer {
        AppConfiguration.makeModelContainer(inMemory: true)
    }

    @Test func storePersistsUpdatesAndDeletion() throws {
        let container = makeContainer()
        let store = makeTestGardenStore(in: container)
        var value = garden()
        #expect(store.gardens.isEmpty)
        #expect(store.add(value))
        value.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 420)
        #expect(store.update(value))
        let reloaded = makeTestGardenStore(in: container)
        #expect(reloaded.gardens.first?.id == value.id)
        #expect(reloaded.gardens.first?.harvestRecord?.latestWeightKg == 420)
        #expect(store.delete(value))
        #expect(makeTestGardenStore(in: container).gardens.isEmpty)
    }

    @Test func legacyGardenWithoutOptionalHistoryStillLoads() throws {
        let value = garden()
        let data = try JSONEncoder().encode([value])
        let decoded = try JSONDecoder().decode([Garden].self, from: data)
        #expect(decoded.first?.id == value.id)
        #expect(decoded.first?.plantingMonth == nil)
        #expect(decoded.first?.fertilizerRecords == nil)
        #expect(decoded.first?.harvestRecord == nil)
    }

    @Test func unknownGardenCannotBeUpdatedOrDeleted() throws {
        let container = makeContainer()
        let store = makeTestGardenStore(in: container)
        let existing = garden()
        #expect(store.add(existing))
        #expect(!store.update(garden()))
        #expect(!store.delete(garden()))
        #expect(store.gardens.map(\.id) == [existing.id])
    }

    @Test func fertilizerDraftRejectsInvalidNumbers() {
        var draft = FertilizerDraft()
        draft.name = "Urea"
        draft.bagWeightKg = 50
        draft.bagCount = 2
        draft.doseKgPerTree = 1
        #expect(draft.record?.id == draft.id)
        draft.name = "  Urea \n"
        #expect(draft.record?.name == "Urea")
        draft.doseKgPerTree = .infinity
        #expect(draft.record == nil)
        draft.doseKgPerTree = 1
        draft.bagCount = 0
        #expect(draft.record == nil)
        draft.bagCount = 2
        draft.name = "  "
        #expect(draft.record == nil)
    }

    @Test func boundaryRejectsCrossingsAndKeepsAreaIndependentOfWinding() {
        func point(_ latitude: Double, _ longitude: Double) -> GardenCoordinate {
            GardenCoordinate(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }
        let points = [point(0, 0), point(0, 0.001), point(0.001, 0.001), point(0.001, 0)]
        let boundary = GardenBoundary(points: points)
        #expect(boundary.isValid)
        #expect(abs(boundary.areaHectares - 1.2364) < 0.001)
        #expect(abs(boundary.areaHectares - GardenBoundary(points: points.reversed()).areaHectares) < 0.001)
        #expect(!GardenBoundary(points: [points[0], points[2], points[1], points[3]]).isValid)
        #expect(!GardenBoundary(points: Array(points.prefix(2))).isValid)
    }
}
