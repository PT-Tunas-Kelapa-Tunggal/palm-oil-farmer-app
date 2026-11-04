import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenStoreDependencyTests {
    private func garden() -> Garden {
        Garden(id: UUID(), name: "Lokal", locationName: "Dumai", boundary: GardenBoundary(),
               plantingYear: 2016, soilType: .peat)
    }

    private var contact: ReviewContactDetails {
        ReviewContactDetails(name: "Budi", phone: "08123456789", address: "Uji")
    }

    @Test func storeCanLoadWithoutSwiftDataAndRetainsSnapshotOnLoadFailure() {
        let local = garden()
        let repository = DraftRepositoryStub(gardens: [local])
        let store = GardenStore(draftRepository: repository, repository: ReviewRepositoryStub())
        #expect(store.gardens.map(\.id) == [local.id])
        repository.failsLoad = true
        store.loadLocalDrafts()
        #expect(store.gardens.map(\.id) == [local.id])
        #expect(store.errorMessage?.hasPrefix("Draf lokal tidak dapat dimuat:") == true)
    }

    @Test func failedDraftWritesKeepPublishedDataAndExistingMessages() {
        let local = garden()
        let draft = GardenDraft(location: GardenLocation(
            name: "Lokasi", subtitle: "Riau", coordinate: GardenCoordinate(latitude: 1, longitude: 104)
        ))
        let repository = DraftRepositoryStub(locations: [draft], gardens: [local])
        repository.failsWrites = true
        let store = GardenStore(draftRepository: repository, repository: ReviewRepositoryStub())
        #expect(!store.add(garden()))
        #expect(store.errorMessage?.hasPrefix("Kebun belum tersimpan di draf:") == true)
        #expect(!store.addDraft(draft))
        #expect(store.errorMessage?.hasPrefix("Draf kebun belum tersimpan:") == true)
        #expect(!store.update(local))
        #expect(store.errorMessage?.hasPrefix("Gagal memperbarui draf:") == true)
        #expect(!store.deleteDraft(draft))
        #expect(store.errorMessage?.hasPrefix("Draf belum terhapus:") == true)
        #expect(store.gardens.map(\.id) == [local.id] && store.drafts.map(\.id) == [draft.id])
    }

    @Test func rejectedSubmissionDoesNotAttemptLocalCleanup() async {
        let local = garden()
        let repository = DraftRepositoryStub(gardens: [local])
        let store = GardenStore(draftRepository: repository, repository: ReviewRepositoryStub(rejectsSubmission: true))
        do {
            _ = try await store.submitReview(for: local, contact: contact)
            Issue.record("Submission should fail")
        } catch {
            #expect(error is ReviewRepositoryStub.Failure)
        }
        #expect(repository.deletedIDs.isEmpty)
        #expect(store.gardens.first?.review == nil)
    }

    @Test func remoteSuccessStillPromotesGardenWhenLocalCleanupCannotSave() async throws {
        let local = garden()
        let repository = DraftRepositoryStub(gardens: [local])
        repository.failsWrites = true
        let store = GardenStore(draftRepository: repository, repository: ReviewRepositoryStub())
        let saved = try await store.submitReview(for: local, contact: contact)
        #expect(repository.deletedIDs == [local.id])
        #expect(store.gardens.count == 1 && store.gardens.first?.review?.status == saved.status)
        // Cleanup failure is deliberately not reported as a failed remote submission.
        #expect(store.errorMessage == nil)
    }

    @Test func mappedGardenDeletionRetainsExistingSaveFailurePolicy() {
        let local = garden()
        let repository = DraftRepositoryStub(gardens: [local])
        repository.failsWrites = true
        let store = GardenStore(draftRepository: repository, repository: ReviewRepositoryStub())
        #expect(store.delete(local))
        #expect(repository.deletedIDs == [local.id])
        #expect(store.errorMessage == nil)
    }

    @Test func submittedEditsAndDeletionRemainInMemoryOnly() async throws {
        let local = garden()
        let remote = PlantationReviewRequest(garden: local, contact: contact)
        let drafts = DraftRepositoryStub()
        let store = GardenStore(draftRepository: drafts, repository: ReviewRepositoryStub(requests: [remote]))
        await store.refreshRemote()
        var edited = try #require(store.gardens.first)
        edited.harvestRecord = HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 750)
        #expect(store.update(edited))
        #expect(store.gardens.first?.harvestRecord?.latestWeightKg == 750)
        #expect(drafts.gardens.isEmpty)
        #expect(store.delete(edited) && store.gardens.isEmpty)
        await store.refreshRemote()
        #expect(store.gardens.first?.harvestRecord == nil)
    }

    @Test func compositionSharesInjectedReviewRepositoryAndUsesSuppliedContainer() async throws {
        let container = AppConfiguration.makeModelContainer(inMemory: true)
        let reviewRepository = RecordingReviewRepository()
        let dependencies = AppDependencies(modelContainer: container, reviewRepository: reviewRepository,
                                           registrationServices: makeTestRegistrationServices)
        let local = garden()
        #expect(dependencies.modelContainer === container)
        #expect(dependencies.reviewRepository as? RecordingReviewRepository === reviewRepository)
        #expect(dependencies.gardenStore.add(local))
        let reopened = makeTestGardenStore(in: container)
        #expect(reopened.gardens.map(\.id) == [local.id])
        let saved = try await dependencies.gardenStore.submitReview(for: local, contact: contact)
        #expect(reviewRepository.submissions.map(\.id) == [saved.id])
        #expect(makeTestGardenStore(in: container).gardens.isEmpty)
        _ = try await dependencies.reviewRepository.fetchRequest(for: local.id)
        #expect(reviewRepository.fetchedIDs == [local.id])
    }
}

@MainActor
private final class DraftRepositoryStub: GardenDraftRepository {
    enum Failure: Error { case unavailable }
    var locations: [GardenDraft]
    var gardens: [Garden]
    var failsLoad = false
    var failsWrites = false
    var deletedIDs: [UUID] = []

    init(locations: [GardenDraft] = [], gardens: [Garden] = []) {
        self.locations = locations
        self.gardens = gardens
    }

    func loadDrafts() throws -> GardenDraftSnapshot {
        if failsLoad { throw Failure.unavailable }
        return GardenDraftSnapshot(locations: locations, gardens: gardens)
    }

    func add(_ garden: Garden, completingDraft draftID: UUID?) throws {
        if failsWrites { throw Failure.unavailable }
        gardens.append(garden)
        locations.removeAll { $0.id == draftID }
    }

    func addDraft(_ draft: GardenDraft) throws {
        if failsWrites { throw Failure.unavailable }
        locations.append(draft)
    }

    func update(_ garden: Garden) throws -> Bool {
        guard let index = gardens.firstIndex(where: { $0.id == garden.id }) else { return false }
        if failsWrites { throw Failure.unavailable }
        gardens[index] = garden
        return true
    }

    func deleteDraft(id: UUID) throws -> Bool {
        guard locations.contains(where: { $0.id == id }) || gardens.contains(where: { $0.id == id }) else { return false }
        deletedIDs.append(id)
        if failsWrites { throw Failure.unavailable }
        locations.removeAll { $0.id == id }
        gardens.removeAll { $0.id == id }
        return true
    }

    func eraseAll() throws {
        if failsWrites { throw Failure.unavailable }
        locations = []
        gardens = []
    }
}

@MainActor
private final class RecordingReviewRepository: FarmerReviewRepository {
    var submissions: [PlantationReviewRequest] = []
    var fetchedIDs: [UUID] = []

    func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest {
        submissions.append(request)
        return request
    }

    func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? {
        fetchedIDs.append(gardenID)
        return submissions.first { $0.garden.id == gardenID }
    }

    func fetchMyRequests() async throws -> [PlantationReviewRequest] { submissions }

    nonisolated func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest> {
        AsyncStream { $0.finish() }
    }
}
