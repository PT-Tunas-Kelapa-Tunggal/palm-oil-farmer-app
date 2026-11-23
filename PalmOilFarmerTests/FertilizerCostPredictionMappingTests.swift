import Testing
@testable import PalmOilFarmer

struct FertilizerCostPredictionMappingTests {
    private let payload = """
    {"payload": {
      "Dolomite": {"total_bags_needed": 13, "total_cost": 1300000, "total_kg": 650},
      "NPK-12-6-22-3": {"total_bags_needed": 28, "total_cost": 17640000, "total_kg": 1400},
      "NPK-13-6-27-4": {"total_bags_needed": 25, "total_cost": 13750000, "total_kg": 1250},
      "NPK-13-8-27-4": {"total_bags_needed": 25, "total_cost": 13750000, "total_kg": 1250},
      "NPK-15-15-15": {"total_bags_needed": 32, "total_cost": 23680000, "total_kg": 1600},
      "NPK-16-16-16": {"total_bags_needed": 26, "total_cost": 23140000, "total_kg": 1300},
      "Urea": {"total_bags_needed": 1, "total_cost": 500000, "total_kg": 50}
    }, "version": "1.0.0"}
    """

    @Test func estimateUsesCloudKitQuantitiesAndCosts() throws {
        let predictions = try JSONEnvelope<FertilizerCostPredictions>.decodeFromString(payload).get()
        let overview = try CloudKitFertilizerEstimationRepository.makeOverview(
            gardenId: "garden", gardenName: "Kebun", budget: 30_000_000,
            predictions: predictions, selectedID: "NPK-15-15-15"
        )

        #expect(overview.defaultNPKId == "NPK-13-6-27-4")
        #expect(overview.npkOptions.count == 5)
        #expect(overview.npkOptions.filter { $0.tag == "Paling hemat" }.count == 2)
        #expect(overview.fertilizers.first(where: { $0.id == "Dolomite" })?.weightKg == 650)
        #expect(overview.fertilizers.first(where: { $0.id == "Dolomite" })?.bagCount == 13)
        #expect(overview.fertilizers.first(where: { $0.id == "Dolomite" })?.totalPrice == 1_300_000)
        #expect(overview.fertilizers.first(where: { $0.id == "npk" })?.weightKg == 1_600)
        #expect(overview.fertilizers.first(where: { $0.id == "npk" })?.bagCount == 32)
        #expect(overview.fertilizers.first(where: { $0.id == "npk" })?.pricePerBag == 740_000)
        #expect(overview.fertilizers.first(where: { $0.id == "npk" })?.totalPrice == 23_680_000)
        #expect(overview.totalCost == 25_480_000)
    }

    @Test func changingNPKUsesThatCloudKitPrediction() throws {
        let predictions = try JSONEnvelope<FertilizerCostPredictions>.decodeFromString(payload).get()
        let overview = try CloudKitFertilizerEstimationRepository.makeOverview(
            gardenId: "garden", gardenName: "Kebun", budget: 30_000_000,
            predictions: predictions, selectedID: "NPK-12-6-22-3"
        )

        #expect(overview.fertilizers.first(where: { $0.id == "npk" })?.weightKg == 1_400)
        #expect(overview.fertilizers.first(where: { $0.id == "npk" })?.bagCount == 28)
        #expect(overview.fertilizers.first(where: { $0.id == "npk" })?.totalPrice == 17_640_000)
        #expect(overview.totalCost == 19_440_000)
    }
}
