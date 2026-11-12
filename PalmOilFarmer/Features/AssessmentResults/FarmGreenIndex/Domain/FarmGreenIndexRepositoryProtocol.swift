import Foundation

/// Repository protocol defining data access operations for Farm Green Index (Peta Kondisi Kebun).
public protocol FarmGreenIndexRepositoryProtocol: Sendable {
    func fetchFarmGreenIndex(for gardenId: String) async throws -> FarmGreenIndexItem
}

/// In-memory mock repository conforming to `FarmGreenIndexRepositoryProtocol`.
/// Used for SwiftUI previews, testing, and offline development.
public actor DummyFarmGreenIndexRepository: FarmGreenIndexRepositoryProtocol {
    private let item: FarmGreenIndexItem

    public init(item: FarmGreenIndexItem = .sample) {
        self.item = item
    }

    public func fetchFarmGreenIndex(for gardenId: String) async throws -> FarmGreenIndexItem {
        item
    }
}

