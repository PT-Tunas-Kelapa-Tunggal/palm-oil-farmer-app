import Foundation

/// Repository protocol defining operations required for the Nutrient Condition feature.
public protocol NutrientConditionRepositoryProtocol: Sendable {
    func fetchNutrientCondition(for gardenId: String) async throws -> NutrientConditionOverview
}

/// In-memory mock repository conforming to `NutrientConditionRepositoryProtocol`.
/// Useful for unit testing, offline fallback, and SwiftUI previews.
public actor DummyNutrientConditionRepository: NutrientConditionRepositoryProtocol {
    private let stub: NutrientConditionOverview

    public init(stub: NutrientConditionOverview = .dummyData) {
        self.stub = stub
    }

    public func fetchNutrientCondition(for gardenId: String) async throws -> NutrientConditionOverview {
        stub
    }
}

