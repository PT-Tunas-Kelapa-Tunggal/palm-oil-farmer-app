import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct SubmitGardenReviewTests {
    private let contact = ReviewContactDetails(name: "Budi", phone: "08123456789", address: "Riau")

    @Test func unavailableIncompleteAndAlreadySubmittedGardensCannotReachRemoteRepository() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        let app = reviewTestDependencies(repository: repository)
        do {
            _ = try await app.submitGardenReview.execute(gardenID: UUID(), contact: contact)
            Issue.record("Expected unavailable garden")
        } catch { #expect(error as? ReviewSubmissionError == .gardenUnavailable) }
        var garden = profileGarden()
        #expect(app.gardenStore.add(garden))
        do {
            _ = try await app.submitGardenReview.execute(gardenID: garden.id, contact: contact)
            Issue.record("Expected incomplete profile")
        } catch { #expect(error as? ReviewSubmissionError == .profileIncomplete) }
        garden.fertilizerRecords = [profileFertilizer()]
        garden.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 500)
        garden.review = GardenReview(contact: contact)
        // Submitted projection is fetched from the repository rather than cached locally.
        repository.savedRequests[garden.id] = PlantationReviewRequest(garden: garden, contact: contact)
        await app.gardenStore.refreshRemote()
        do {
            _ = try await app.submitGardenReview.execute(gardenID: garden.id, contact: contact)
            Issue.record("Expected already submitted garden")
        } catch { #expect(error as? ReviewSubmissionError == .alreadySubmitted) }
        #expect(repository.submissions.isEmpty)
    }

    @Test func submissionUsesLatestGardenAtSendTime() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        let app = reviewTestDependencies(repository: repository)
        let original = reviewReadyGarden()
        #expect(app.gardenStore.add(original))
        let latestFertilizer = profileFertilizer()
        let updated = Garden(id: original.id, name: "Terbaru", locationName: original.locationName, boundary: original.boundary,
            plantingYear: 2018, soilType: .mineral, plantingMonth: 9, fertilizerRecords: [latestFertilizer],
            harvestRecord: HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 800), createdAt: original.createdAt)
        #expect(app.gardenStore.update(updated))
        let saved = try await app.submitGardenReview.execute(gardenID: original.id, contact: contact)
        #expect(saved.garden.name == "Terbaru" && saved.agronomy.plantingYear == 2018 && saved.agronomy.plantingMonth == 9)
        #expect(saved.agronomy.fertilizerRecords.first?.id == latestFertilizer.id && saved.agronomy.harvestRecord?.latestWeightKg == 800)
    }

    @Test func sharedUseCaseBlocksSameGardenInFlightButAllowsDifferentGardens() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        repository.suspendsSubmission = true
        let app = reviewTestDependencies(repository: repository)
        let firstGarden = reviewReadyGarden(), secondGarden = reviewReadyGarden()
        #expect(app.gardenStore.add(firstGarden) && app.gardenStore.add(secondGarden))
        let first = Task { try await app.submitGardenReview.execute(gardenID: firstGarden.id, contact: contact) }
        await repository.waitForSubmission(of: firstGarden.id)
        do {
            _ = try await app.submitGardenReview.execute(gardenID: firstGarden.id, contact: contact)
            Issue.record("Expected an in-flight guard")
        } catch { #expect(error as? ReviewSubmissionError == .inProgress) }
        let second = Task { try await app.submitGardenReview.execute(gardenID: secondGarden.id, contact: contact) }
        await repository.waitForSubmission(of: secondGarden.id)
        #expect(repository.submissions.count == 2)
        for garden in [firstGarden, secondGarden] {
            let request = try #require(repository.submissions.first { $0.garden.id == garden.id })
            repository.finishSubmission(of: garden.id, with: .success(request))
        }
        _ = try await first.value
        _ = try await second.value
        #expect(app.gardenStore.gardens.count == 2)
    }

    @Test func failedRemoteSaveKeepsDraftAndUnlocksRetry() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        repository.rejectsSubmission = true
        let app = reviewTestDependencies(repository: repository)
        let garden = reviewReadyGarden()
        #expect(app.gardenStore.add(garden))
        do {
            _ = try await app.submitGardenReview.execute(gardenID: garden.id, contact: contact)
            Issue.record("Expected repository failure")
        } catch { #expect(error is ReviewSubmissionRepositorySpy.Failure) }
        #expect(makeTestGardenStore(in: app.modelContainer).gardens.map(\.id) == [garden.id])
        repository.rejectsSubmission = false
        _ = try await app.submitGardenReview.execute(gardenID: garden.id, contact: contact)
        #expect(repository.submissions.count == 2 && makeTestGardenStore(in: app.modelContainer).gardens.isEmpty)
        #expect(app.gardenStore.gardens.first?.review?.status == .submitted)
    }

    @Test func confirmedSuccessStillPromotesAndEvictsDraftWhenCallerWasCancelled() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        repository.suspendsSubmission = true
        let app = reviewTestDependencies(repository: repository)
        let garden = reviewReadyGarden()
        #expect(app.gardenStore.add(garden))
        let pending = Task { try await app.submitGardenReview.execute(gardenID: garden.id, contact: contact) }
        await repository.waitForSubmission(of: garden.id)
        pending.cancel()
        let request = try #require(repository.submissions.first)
        repository.finishSubmission(of: garden.id, with: .success(request))
        let saved = try await pending.value
        #expect(saved.garden.id == garden.id && app.gardenStore.gardens.first?.review?.status == .submitted)
        #expect(makeTestGardenStore(in: app.modelContainer).gardens.isEmpty)
    }

    @Test func alreadyCancelledTaskCannotStartRemoteWrite() async {
        let repository = ReviewSubmissionRepositorySpy()
        let app = reviewTestDependencies(repository: repository)
        let garden = reviewReadyGarden()
        #expect(app.gardenStore.add(garden))
        let pending = Task { try await app.submitGardenReview.execute(gardenID: garden.id, contact: contact) }
        pending.cancel()
        do { _ = try await pending.value; Issue.record("Expected cancellation") }
        catch { #expect(error is CancellationError) }
        #expect(repository.submissions.isEmpty)
    }

    @Test func confirmedSubmittedGardenCannotBeSubmittedAgain() async throws {
        let repository = ReviewSubmissionRepositorySpy()
        let app = reviewTestDependencies(repository: repository)
        let garden = reviewReadyGarden()
        #expect(app.gardenStore.add(garden))
        _ = try await app.submitGardenReview.execute(gardenID: garden.id, contact: contact)
        do {
            _ = try await app.submitGardenReview.execute(gardenID: garden.id, contact: contact)
            Issue.record("Expected submitted guard")
        } catch { #expect(error as? ReviewSubmissionError == .alreadySubmitted) }
        #expect(repository.submissions.count == 1)
    }
}
