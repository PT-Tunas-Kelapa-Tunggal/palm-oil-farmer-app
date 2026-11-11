import Foundation
import Observation

/// ViewModel managing state and user actions for the Fertilizer Cost Estimation screen.
@Observable
@MainActor
public final class FertilizerEstimationViewModel {
    private let repository: any FertilizerEstimationRepositoryProtocol

    public let gardenId: String
    public var overview: FertilizerEstimationOverview?
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var isNPKPickerPresented: Bool = false

    /// Indicates whether the farmer has selected an alternative NPK formulation differing from default.
    public var isSaveCompositionVisible: Bool {
        overview?.isNPKChangedFromDefault ?? false
    }

    public init(
        repository: any FertilizerEstimationRepositoryProtocol = DummyFertilizerEstimationRepository(),
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
            overview = try await repository.fetchEstimation(for: gardenId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func refresh() async {
        await load()
    }

    public func selectNPK(option: NPKOption) async {
        do {
            overview = try await repository.selectNPK(optionId: option.id, for: gardenId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Saves the selected custom fertilizer composition.
    /// Kept as no-op for now as requested.
    public func saveComposition() {
        // Intentionally no-op for now as requested
    }
}

