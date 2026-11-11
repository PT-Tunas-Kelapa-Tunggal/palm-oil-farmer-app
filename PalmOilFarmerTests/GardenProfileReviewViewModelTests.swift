import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenProfileReviewViewModelTests {
    private func request(status: ReviewStatus) -> PlantationReviewRequest {
        var request = PlantationReviewRequest(garden: profileGarden(),
            contact: ReviewContactDetails(name: "Budi", phone: "08123456789", address: "Riau"))
        request.status = status
        return request
    }

    @Test func loadedStatusUsesExistingTimelineAndKeepsMissingReportFallbackAvailable() async {
        let value = request(status: .scheduled)
        let bridge = GardenProfileReviewViewModel()
        await bridge.load(for: value.garden.id, repository: ReviewRepositoryStub(requests: [value]))
        #expect(bridge.activeStatus == .scheduled && bridge.activeReport == nil)
        #expect(bridge.activeEntries.map(\.title) == value.timeline.entries(for: .scheduled).map(\.title))
        #expect(bridge.activeEntries.map(\.message) == value.timeline.entries(for: .scheduled).map(\.message))
    }

    @Test func reviewActionRetainsSubmittedCompletedAndDownloadedTransitions() {
        var garden = profileGarden()
        let bridge = GardenProfileReviewViewModel()
        #expect(bridge.action(for: garden) == .request)
        garden.review = GardenReview(status: .scheduled,
            contact: ReviewContactDetails(name: "A", phone: "08123456789", address: "B"), stageDates: [])
        #expect(bridge.action(for: garden) == .status)
        garden.review = GardenReview(status: .completed,
            contact: ReviewContactDetails(name: "A", phone: "08123456789", address: "B"), stageDates: [])
        #expect(bridge.action(for: garden) == .status)
        garden.review?.resultsDownloaded = true
        #expect(bridge.action(for: garden) == .results)
        garden.review?.resultsDownloaded = false
        bridge.submitted(request(status: .completed))
        #expect(bridge.action(for: garden) == .results)
    }

    @Test func cancelledReviewLoadDoesNotPublishLateState() async {
        let repository = ControlledProfileReviewRepository()
        let bridge = GardenProfileReviewViewModel()
        let value = request(status: .completed)
        let pending = Task { await bridge.load(for: value.garden.id, repository: repository) }
        await repository.waitForRequest(1)
        pending.cancel()
        repository.finish(1, with: .success(value))
        await pending.value
        #expect(bridge.activeStatus == nil && bridge.activeEntries.isEmpty)
    }

    @Test func newerLoadWinsAndFailedFetchRetainsCurrentPresentation() async {
        let repository = ControlledProfileReviewRepository()
        let bridge = GardenProfileReviewViewModel()
        let first = Task { await bridge.load(for: UUID(), repository: repository) }
        await repository.waitForRequest(1)
        let second = Task { await bridge.load(for: UUID(), repository: repository) }
        await repository.waitForRequest(2)
        repository.finish(2, with: .success(request(status: .completed)))
        await second.value
        repository.finish(1, with: .success(request(status: .submitted)))
        await first.value
        #expect(bridge.activeStatus == .completed)
        let failed = Task { await bridge.load(for: UUID(), repository: repository) }
        await repository.waitForRequest(3)
        repository.finish(3, with: .failure(ControlledProfileReviewRepository.Failure.unavailable))
        await failed.value
        #expect(bridge.activeStatus == .completed)
    }
}
