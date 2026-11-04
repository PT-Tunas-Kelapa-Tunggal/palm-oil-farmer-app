import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct ReviewRepositoryContractTests {
    private func garden() -> Garden {
        Garden(id: UUID(), name: "Lokal", locationName: "Dumai", boundary: GardenBoundary(),
               plantingYear: 2016, soilType: .peat)
    }

    @Test func refreshUsesRepositoryContractAndRemoteOverridesMatchingLocalGarden() async {
        let container = AppConfiguration.makeModelContainer(inMemory: true)
        let local = garden()
        let remote = PlantationReviewRequest(
            farmer: FarmerContact(name: "Budi", phone: "08123456789", address: "Uji"),
            garden: GardenSummary(id: local.id, name: "Remote", locationName: "Dumai", areaHectares: 0),
            boundary: [], agronomy: AgronomicProfile(plantingYear: 2016, soilType: "Gambut")
        )
        let repository = ReviewRepositoryStub(requests: [remote])
        let store = GardenStore(modelContainer: container, repository: repository)
        #expect(store.add(local))
        await store.refreshRemote()
        #expect(store.gardens.count == 1)
        #expect(store.gardens.first?.id == local.id)
        #expect(store.gardens.first?.name == "Remote")
        #expect(store.gardens.first?.review?.status == .submitted)
        #expect(!store.isLoading)
    }

    @Test func successfulSubmissionPreservesPromotionAndDraftEviction() async throws {
        let container = AppConfiguration.makeModelContainer(inMemory: true)
        let repository = ReviewRepositoryStub()
        let store = GardenStore(modelContainer: container, repository: repository)
        let value = garden()
        #expect(store.add(value))
        let saved = try await store.submitReview(
            for: value, contact: ReviewContactDetails(name: "Budi", phone: "08123456789", address: "Uji")
        )
        #expect(saved.garden.id == value.id)
        #expect(store.gardens.count == 1 && store.gardens.first?.review?.status == .submitted)
        // Current product policy: submitted data has no persistent local cache.
        let reopened = GardenStore(modelContainer: container, repository: repository)
        #expect(reopened.gardens.isEmpty)
    }

    @Test func rejectedSubmissionRetainsPersistentLocalDraft() async {
        let container = AppConfiguration.makeModelContainer(inMemory: true)
        let repository = ReviewRepositoryStub(rejectsSubmission: true)
        let store = GardenStore(modelContainer: container, repository: repository)
        let value = garden()
        #expect(store.add(value))
        do {
            _ = try await store.submitReview(
                for: value, contact: ReviewContactDetails(name: "Budi", phone: "08123456789", address: "Uji")
            )
            Issue.record("Submission should fail for the rejecting repository")
        } catch {
            #expect(error is ReviewRepositoryStub.Failure)
        }
        #expect(store.gardens.first?.review == nil)
        let reopened = GardenStore(modelContainer: container, repository: repository)
        #expect(reopened.gardens.map(\.id) == [value.id])
        #expect(reopened.gardens.first?.review == nil)
    }
}

@MainActor
private struct ReviewRepositoryStub: FarmerReviewRepository {
    enum Failure: Error { case rejected }
    var requests: [PlantationReviewRequest] = []
    var rejectsSubmission = false

    func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest {
        if rejectsSubmission { throw Failure.rejected }
        return request
    }

    func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? {
        requests.first { $0.garden.id == gardenID }
    }

    func fetchMyRequests() async throws -> [PlantationReviewRequest] {
        requests
    }

    nonisolated func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest> {
        AsyncStream { $0.finish() }
    }
}
