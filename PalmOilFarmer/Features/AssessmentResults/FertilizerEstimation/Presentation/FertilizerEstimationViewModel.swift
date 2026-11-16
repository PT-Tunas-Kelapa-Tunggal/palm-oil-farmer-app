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
    public private(set) var savedNPKId: String?
    public private(set) var isSaving: Bool = false

    /// The save action appears whenever the preview differs from the saved choice.
    public var isSaveCompositionVisible: Bool {
        guard let overview else { return false }
        return overview.selectedNPKId != savedNPKId
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
            let loaded = try await repository.fetchEstimation(for: gardenId)
            if savedNPKId == nil { savedNPKId = loaded.selectedNPKId }
            overview = loaded
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

    public func saveComposition() async throws {
        guard let overview else { return }
        isSaving = true
        defer { isSaving = false }
        try await repository.saveNPK(optionId: overview.selectedNPKId, for: gardenId)
        savedNPKId = overview.selectedNPKId
    }
}

