import Foundation
import Testing
@testable import PalmOilFarmer

struct FertilizerFormDetailsTests {
    @Test func validatesCompositionIncludingZeroMagnesium() {
        #expect(FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15).isValid)
        #expect(!FertilizerComposition(nitrogen: -1, phosphorus: 15, potassium: 15).isValid)
        #expect(!FertilizerComposition(nitrogen: 60, phosphorus: 30, potassium: 20).isValid)
        #expect(!FertilizerComposition(nitrogen: .infinity, phosphorus: 15, potassium: 15).isValid)
        #expect(!FertilizerComposition(nitrogen: 15, potassium: 15).isValid)
    }

    @Test func readsOnlyExplicitNPKGradesFromLegacyNames() {
        #expect(FertilizerComposition.fromLabel("NPK 15-15-15")
            == FertilizerComposition(nitrogen: 15, phosphorus: 15, potassium: 15))
        #expect(FertilizerComposition.fromLabel("NPK") == FertilizerComposition())
        #expect(FertilizerComposition.fromLabel("SP-36") == FertilizerComposition())
    }

    @Test func localDetailsRoundTripAndRemainIsolatedBetweenGardens() throws {
        let suite = "FertilizerFormDetailsTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LocalFertilizerFormStore(defaults: defaults)
        let gardenID = UUID()
        let recordID = UUID()
        let composition = FertilizerComposition(nitrogen: 12, phosphorus: 12, potassium: 17, magnesium: 2)
        let details = FertilizerFormDetails(frequencyPerYear: 3, compositions: [recordID: composition])
        try store.save(details, gardenID: gardenID)

        let reopenedStore = LocalFertilizerFormStore(defaults: defaults)
        #expect(reopenedStore.load(gardenID: gardenID) == details)
        #expect(reopenedStore.load(gardenID: UUID()) == FertilizerFormDetails())
        #expect(reopenedStore.load(gardenID: gardenID).compositions[recordID] == composition)

        try reopenedStore.save(FertilizerFormDetails(), gardenID: gardenID)
        #expect(reopenedStore.load(gardenID: gardenID).compositions.isEmpty)
    }
}
