import Foundation
import Observation

/// ViewModel managing state and user interactions for the Nutrient Condition assessment screen.
@Observable
@MainActor
public final class NutrientConditionViewModel {
    private let repository: any NutrientConditionRepositoryProtocol

    public let gardenId: String
    public var overview: NutrientConditionOverview?
    public var isLoading: Bool = false
    public var errorMessage: String?

    public init(
        repository: any NutrientConditionRepositoryProtocol = DummyNutrientConditionRepository(),
        gardenId: String = "garden-default"
    ) {
        self.repository = repository
        self.gardenId = gardenId
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            overview = try await repository.fetchNutrientCondition(for: gardenId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func refresh() async {
        await load()
    }
}

