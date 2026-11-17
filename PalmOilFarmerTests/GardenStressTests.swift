import Foundation
import CoreLocation
import Testing
import SwiftData
@testable import PalmOilFarmer

@MainActor
struct GardenStressTests {
    private func garden() -> Garden {
        Garden(id: UUID(), name: "Kebun", locationName: "Dumai",
               boundary: GardenBoundary(), plantingYear: 2016, soilType: .peat)
    }

    private func makeContainer() -> ModelContainer {
        AppConfiguration.makeModelContainer(inMemory: true)
    }

    @Test func duplicateGardenIDIsRejected() throws {
        let container = makeContainer()
        let store = makeTestGardenStore(in: container)
        let value = garden()
        #expect(store.add(value))
        #expect(!store.add(value))
        #expect(store.gardens.count == 1)
        #expect(makeTestGardenStore(in: container).gardens.count == 1)
    }

    @Test func invalidCoordinatesAreRejected() {
        let points = [
            GardenCoordinate(CLLocationCoordinate2D(latitude: 95, longitude: 0)),
            GardenCoordinate(CLLocationCoordinate2D(latitude: 95, longitude: 0.001)),
            GardenCoordinate(CLLocationCoordinate2D(latitude: 95.001, longitude: 0))
        ]
        #expect(!GardenBoundary(points: points).isValid)
    }

    @Test func thousandGardensRoundTripInSwiftData() throws {
        let container = makeContainer()
        let context = ModelContext(container)
        for index in 0..<1_000 {
            var value = garden()
            value.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: Double(index))
            let model = DraftPlantationRequest.from(garden: value)
            context.insert(model)
        }
        try context.save()

        let descriptor = FetchDescriptor<DraftPlantationRequest>()
        let restored = try context.fetch(descriptor)
        #expect(restored.count == 1_000)
    }
}
