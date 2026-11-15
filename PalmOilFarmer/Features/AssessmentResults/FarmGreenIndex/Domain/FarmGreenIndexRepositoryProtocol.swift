import Foundation

/// Repository protocol defining data access operations for Farm Green Index (Peta Kondisi Kebun).
public protocol FarmGreenIndexRepositoryProtocol: Sendable {
    func fetchFarmGreenIndex(for gardenId: String) async throws -> FarmGreenIndexItem
}

