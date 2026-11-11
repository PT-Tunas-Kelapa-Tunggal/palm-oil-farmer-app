import Foundation

extension Garden {
    init(reviewRequest request: PlantationReviewRequest) {
        let boundaryCoords = request.boundary.map {
            GardenCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        }
        let boundary = GardenBoundary(points: boundaryCoords)

        let fertilizers = request.agronomy.fertilizerRecords.map {
            FertilizerRecord(
                id: $0.id,
                name: $0.name,
                bagWeightKg: $0.bagWeightKg,
                bagCount: $0.bagCount,
                doseKgPerTree: $0.doseKgPerTree, composition: $0.composition
            )
        }

        let harvest = request.agronomy.harvestRecord.map {
            HarvestRecord(
                frequencyPerMonth: $0.frequencyPerMonth,
                latestWeightKg: $0.latestWeightKg, averageMonthlyWeightKg: $0.averageMonthlyWeightKg
            )
        }

        var stageDates: [Date] = [request.timeline.submittedAt]
        if let scheduled = request.timeline.scheduledFor { stageDates.append(scheduled) }
        if let inReview = request.timeline.inReviewAt { stageDates.append(inReview) }
        if let completed = request.timeline.completedAt { stageDates.append(completed) }

        let contact = ReviewContactDetails(
            name: request.farmer.name,
            phone: request.farmer.phone,
            address: request.farmer.address
        )

        let review = GardenReview(
            status: request.status,
            contact: contact,
            stageDates: stageDates,
            resultsDownloaded: request.status == .completed
        )

        self.init(
            id: request.garden.id,
            name: request.garden.name,
            locationName: request.garden.locationName,
            boundary: boundary,
            plantingYear: request.agronomy.plantingYear,
            soilType: SoilType(rawValue: request.agronomy.soilType) ?? .mineral,
            plantingMonth: request.agronomy.plantingMonth,
            fertilizerRecords: fertilizers.isEmpty ? nil : fertilizers,
            harvestRecord: harvest,
            review: review,
            createdAt: request.timeline.submittedAt,
            fertilizationFrequencyPerYear: request.agronomy.fertilizationFrequencyPerYear
        )
    }
}
