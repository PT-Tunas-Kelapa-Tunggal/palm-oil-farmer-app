import Foundation

/// Everything the review result screens need for one garden.
struct ReviewResultContent {
    let result: ReviewResult
    let allocations: [AreaAllocation]
    let history: ReviewHistory
}

protocol ReviewResultRepository: Sendable {
    /// Returns nil when the garden has no finished review yet.
    func fetchContent(for gardenID: UUID) async throws -> ReviewResultContent?

    /// Records that a fertilizer was applied. A nil `areaID` means the whole garden.
    func markFertilized(areaID: Int?, fertilizer: String, gardenID: UUID) async throws
}
