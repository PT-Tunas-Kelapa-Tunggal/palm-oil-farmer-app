import Foundation

/// Repository protocol defining data operations for the Assessment Results Overview feature.
public protocol ResultOverviewRepositoryProtocol: Sendable {
    func fetchOverview(for gardenId: String) async throws -> ResultOverviewItem
}

/// In-memory mock repository conforming to `ResultOverviewRepositoryProtocol`.
/// Useful for unit testing, offline development, and SwiftUI previews.
public actor DummyResultOverviewRepository: ResultOverviewRepositoryProtocol {
    private let item: ResultOverviewItem

    public init(item: ResultOverviewItem = .sample) {
        self.item = item
    }

    public func fetchOverview(for gardenId: String) async throws -> ResultOverviewItem {
        item
    }
}

