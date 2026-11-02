import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct HasilPeninjauanViewModelTests {
    private enum SampleError: Error { case offline }

    private final class FakeRepository: ReviewResultRepository, @unchecked Sendable {
        var content: ReviewResultContent?
        var failsToFetch = false
        var failsToMark = false
        private(set) var marked: [(areaID: Int?, fertilizer: String)] = []

        init(content: ReviewResultContent? = nil) {
            self.content = content
        }

        func fetchContent(for gardenID: UUID) async throws -> ReviewResultContent? {
            if failsToFetch { throw SampleError.offline }
            return content
        }

        func markFertilized(areaID: Int?, fertilizer: String, gardenID: UUID) async throws {
            if failsToMark { throw SampleError.offline }
            marked.append((areaID, fertilizer))
        }
    }

    private var sampleContent: ReviewResultContent {
        ReviewResultContent(result: .sample, allocations: [.sample, .uniformSample, .ureaSample], history: .sample)
    }

    private func allocationModel(
        _ repository: FakeRepository,
        fertilizer: String? = nil
    ) throws -> AreaAllocationViewModel {
        try #require(AreaAllocationViewModel(
            gardenID: UUID(),
            allocations: [.sample, .uniformSample, .ureaSample],
            initialFertilizer: fertilizer,
            repository: repository
        ))
    }

    private func status(ofArea id: Int, in allocation: AreaAllocation) -> AreaAllocation.Status? {
        guard case .perArea(let lines, _) = allocation.distribution else { return nil }
        return lines.first { $0.id == id }?.status
    }

    @Test func loadShowsContent() async {
        let viewModel = ReviewResultViewModel(gardenID: UUID(), repository: FakeRepository(content: sampleContent))
        await viewModel.load()
        guard case .loaded(let content) = viewModel.phase else {
            Issue.record("Expected loaded content")
            return
        }
        #expect(content.allocations.count == 3)
    }

    @Test func loadWithoutResultIsEmpty() async {
        let viewModel = ReviewResultViewModel(gardenID: UUID(), repository: FakeRepository())
        await viewModel.load()
        guard case .empty = viewModel.phase else {
            Issue.record("Expected the empty state")
            return
        }
    }

    @Test func failedLoadCanBeRetried() async {
        let repository = FakeRepository(content: sampleContent)
        repository.failsToFetch = true
        let viewModel = ReviewResultViewModel(gardenID: UUID(), repository: repository)
        await viewModel.load()
        guard case .failed = viewModel.phase else {
            Issue.record("Expected the failed state")
            return
        }

        repository.failsToFetch = false
        await viewModel.load()
        guard case .loaded = viewModel.phase else {
            Issue.record("Expected retry to load content")
            return
        }
    }

    @Test func emptyAllocationsCannotCreateAViewModel() {
        let viewModel = AreaAllocationViewModel(gardenID: UUID(), allocations: [], repository: FakeRepository())
        #expect(viewModel == nil)
    }

    @Test func unknownFertilizerKeepsTheCurrentSelection() throws {
        let viewModel = try allocationModel(FakeRepository())
        viewModel.selectFertilizer("Tidak ada")
        #expect(viewModel.selectedFertilizer == "Dolomit")

        viewModel.selectFertilizer("Urea")
        #expect(viewModel.allocation.selectedFertilizer == "Urea")
    }

    @Test func markingAnAreaUpdatesOnlyThatAreaAndFertilizer() async throws {
        let repository = FakeRepository()
        let viewModel = try allocationModel(repository, fertilizer: "Urea")
        viewModel.select(.ureaAreaTwo)

        await viewModel.markFertilized(areaID: 2)

        #expect(status(ofArea: 2, in: viewModel.allocation) == .fertilized)
        #expect(status(ofArea: 5, in: viewModel.allocation) == .sameDose)
        viewModel.selectFertilizer("Dolomit")
        #expect(status(ofArea: 2, in: viewModel.allocation) == .sameDose)
        #expect(viewModel.selectedLine == nil)
        #expect(repository.marked.first?.areaID == 2)
        #expect(repository.marked.first?.fertilizer == "Urea")
    }

    @Test func failedMarkKeepsTheStatusAndTheOpenSheet() async throws {
        let repository = FakeRepository()
        repository.failsToMark = true
        let viewModel = try allocationModel(repository, fertilizer: "Urea")
        viewModel.select(.ureaAreaTwo)

        await viewModel.markFertilized(areaID: 2)

        #expect(status(ofArea: 2, in: viewModel.allocation) == .sameDose)
        #expect(viewModel.selectedLine != nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func markingEvenSpreadingCoversTheWholeGarden() async throws {
        let repository = FakeRepository()
        let viewModel = try allocationModel(repository, fertilizer: "NPK 15-15-15")

        await viewModel.markFertilized(areaID: nil)

        guard case .uniform(_, _, let isFertilized) = viewModel.allocation.distribution else {
            Issue.record("Expected even spreading")
            return
        }
        #expect(isFertilized)
        #expect(repository.marked.first?.areaID == nil)
    }
}
