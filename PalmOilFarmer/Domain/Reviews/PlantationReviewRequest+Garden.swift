import Foundation

extension PlantationReviewRequest {
    /// Captures the garden and contact snapshot used by both submission entry points.
    init(garden: Garden, contact: ReviewContactDetails) {
        let boundaryPoints = garden.boundary.points.map {
            CoordinatePoint(latitude: $0.latitude, longitude: $0.longitude)
        }
        let usages = (garden.fertilizerRecords ?? []).map {
            FertilizerUsage(id: $0.id, name: $0.name, bagWeightKg: $0.bagWeightKg,
                            bagCount: $0.bagCount, doseKgPerTree: $0.doseKgPerTree, composition: $0.composition)
        }
        let harvest = garden.harvestRecord.map {
            HarvestYield(frequencyPerMonth: $0.frequencyPerMonth, latestWeightKg: $0.latestWeightKg, averageMonthlyWeightKg: $0.averageMonthlyWeightKg)
        }
        self.init(
            farmer: FarmerContact(name: contact.name, phone: contact.phone, address: contact.address),
            garden: GardenSummary(id: garden.id, name: garden.name, locationName: garden.locationName,
                                  areaHectares: garden.boundary.areaHectares),
            boundary: boundaryPoints,
            agronomy: AgronomicProfile(
                plantingYear: garden.plantingYear,
                plantingMonth: garden.plantingMonth,
                soilType: garden.soilType.rawValue,
                fertilizerRecords: usages,
                harvestRecord: harvest,
                fertilizationFrequencyPerYear: garden.fertilizationFrequencyPerYear
            )
        )
    }
}
