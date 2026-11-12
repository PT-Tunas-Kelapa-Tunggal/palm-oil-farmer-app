import Foundation
import Observation

/// ViewModel managing state and data loading for the Assessment Results Overview screen.
@Observable
@MainActor
public final class ResultOverviewViewModel {
    private let repository: any ResultOverviewRepositoryProtocol

    public let gardenId: String
    public var overview: ResultOverviewItem?
    public var isLoading: Bool = false
    public var errorMessage: String?

    public init(
        repository: any ResultOverviewRepositoryProtocol = DummyResultOverviewRepository(),
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
            overview = try await repository.fetchOverview(for: gardenId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func refresh() async {
        await load()
    }
}

