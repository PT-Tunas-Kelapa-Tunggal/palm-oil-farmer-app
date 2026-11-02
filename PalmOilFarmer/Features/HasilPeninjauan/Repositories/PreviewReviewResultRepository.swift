#if DEBUG
import Foundation

/// Serves the design's example data so previews work without CloudKit.
struct PreviewReviewResultRepository: ReviewResultRepository {
    func fetchContent(for gardenID: UUID) async throws -> ReviewResultContent? {
        ReviewResultContent(
            result: .sample,
            allocations: [.sample, .uniformSample, .ureaSample],
            history: .sample
        )
    }

    func markFertilized(areaID: Int?, fertilizer: String, gardenID: UUID) async throws {}
}

extension ReviewResultViewModel {
    static var preview: ReviewResultViewModel {
        ReviewResultViewModel(gardenID: UUID(), repository: PreviewReviewResultRepository())
    }
}

extension AreaAllocationViewModel {
    static func preview(fertilizer: String = "Dolomit", selectedLine: AreaAllocation.Line? = nil) -> AreaAllocationViewModel {
        AreaAllocationViewModel(
            gardenID: UUID(),
            allocations: [.sample, .uniformSample, .ureaSample],
            initialFertilizer: fertilizer,
            initialSelectedLine: selectedLine,
            repository: PreviewReviewResultRepository()
        )!
    }
}
#endif
