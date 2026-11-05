import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
func reviewReadyGarden() -> Garden {
    var garden = profileGarden()
    garden.fertilizerRecords = [profileFertilizer()]
    garden.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 500)
    return garden
}

@MainActor
func reviewTestDependencies(repository: any FarmerReviewRepository) -> AppDependencies {
    AppDependencies(modelContainer: AppConfiguration.makeModelContainer(inMemory: true), reviewRepository: repository,
        registrationServices: makeTestRegistrationServices, mappingAuthorization: makeTestMappingAuthorization)
}

@MainActor
func completeReviewContact(_ model: ReviewContactFormViewModel) {
    model.name = "  Budi \n"
    model.phone = "+62 (812)-3456 789"
    model.address = "  Riau \n"
    model.hasConsent = true
}

@MainActor
func openReviewContact(_ flow: ReviewRequestFlow) throws -> ReviewContactFlow {
    flow.viewModel.hasConsent = true
    flow.viewModel.continueToContact()
    return flow.makeContactFlow(try #require(flow.coordinator.currentContactID))
}

@MainActor
final class ReviewSubmissionRepositorySpy: FarmerReviewRepository {
    enum Failure: LocalizedError {
        case unavailable
        var errorDescription: String? { "Pengiriman gagal. Coba lagi." }
    }
    var rejectsSubmission = false
    var suspendsSubmission = false
    var submissions: [PlantationReviewRequest] = []
    var savedRequests: [UUID: PlantationReviewRequest] = [:]
    private var pending: [UUID: CheckedContinuation<PlantationReviewRequest, Error>] = [:]
    private var waiters: [UUID: CheckedContinuation<Void, Never>] = [:]

    func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest {
        submissions.append(request)
        if rejectsSubmission { throw Failure.unavailable }
        let saved: PlantationReviewRequest
        if suspendsSubmission {
            saved = try await withCheckedThrowingContinuation {
                pending[request.garden.id] = $0
                waiters.removeValue(forKey: request.garden.id)?.resume()
            }
        } else { saved = request }
        savedRequests[saved.garden.id] = saved
        return saved
    }

    func waitForSubmission(of gardenID: UUID) async {
        if pending[gardenID] != nil { return }
        await withCheckedContinuation { waiters[gardenID] = $0 }
    }

    func finishSubmission(of gardenID: UUID, with result: Result<PlantationReviewRequest, Error>) {
        pending.removeValue(forKey: gardenID)?.resume(with: result)
    }

    func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? { savedRequests[gardenID] }
    func fetchMyRequests() async throws -> [PlantationReviewRequest] { Array(savedRequests.values) }
    nonisolated func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest> {
        AsyncStream { $0.finish() }
    }
}
