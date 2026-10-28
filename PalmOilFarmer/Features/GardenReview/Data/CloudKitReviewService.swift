import Foundation

/// Connects the existing app flow to the same repository and payload as palm-oil-cloudkit.
extension ReviewService {
    static func operatorConnection(bundle: Bundle = .main) -> ReviewService {
        do {
            let configuration = try CloudKitServiceConfiguration.load(bundle: bundle)
            switch configuration.transport {
            case .native:
                return .cloudKit(repository: CloudKitFarmerReviewRepository(
                    containerIdentifier: configuration.containerIdentifier))
            case .web:
                let repository = CloudKitWebFarmerReviewRepository(
                    configuration: try .load(services: configuration, bundle: bundle))
                var service = Self.cloudKit(repository: repository)
                service.refreshInteractively = { garden in
                    try await repository.fetchRequest(for: garden.id, allowsSignIn: true)?.makeGardenReview()
                }
                return service
            }
        } catch {
            return ReviewService(submit: { _, _ in throw error }, refresh: { _ in throw error })
        }
    }

    static func cloudKit(
        repository: any FarmerReviewRepository
    ) -> ReviewService {
        ReviewService(submit: { garden, contact in
            let request = PlantationReviewRequest(garden: garden, contact: contact)
            let saved = try await repository.submitRequest(request)
            return saved.makeGardenReview()
        }, refresh: { garden in
            let request = try await repository.fetchRequest(for: garden.id)
            return request?.makeGardenReview()
        })
    }
}

extension PlantationReviewRequest {
    init(garden: Garden, contact: ReviewContactDetails) {
        self.init(
            farmer: FarmerContact(name: contact.name, phone: contact.phone, address: contact.address),
            garden: GardenSummary(
                id: garden.id, name: garden.name, locationName: garden.locationName,
                areaHectares: garden.boundary.areaHectares
            ),
            boundary: garden.boundary.points.map {
                CoordinatePoint(latitude: $0.latitude, longitude: $0.longitude)
            },
            agronomy: AgronomicProfile(
                plantingYear: garden.plantingYear,
                plantingMonth: garden.plantingMonth,
                soilType: garden.soilType.rawValue,
                fertilizerRecords: (garden.fertilizerRecords ?? []).map {
                    FertilizerUsage(
                        id: $0.id, name: $0.name, bagWeightKg: $0.bagWeightKg,
                        bagCount: $0.bagCount, doseKgPerTree: $0.doseKgPerTree
                    )
                },
                harvestRecord: garden.harvestRecord.map {
                    HarvestYield(frequencyPerMonth: $0.frequencyPerMonth, latestWeightKg: $0.latestWeightKg)
                }
            )
        )
    }

    func makeGardenReview() -> GardenReview {
        GardenReview(
            requestID: id.uuidString, status: status,
            entries: timeline.entries(for: status), report: makeRecommendationReport()
        )
    }
}
