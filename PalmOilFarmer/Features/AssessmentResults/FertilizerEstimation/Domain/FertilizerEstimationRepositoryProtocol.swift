import Foundation

/// Repository protocol defining data operations for the Fertilizer Cost Estimation feature.
public protocol FertilizerEstimationRepositoryProtocol: Sendable {
    func fetchEstimation(for gardenId: String) async throws -> FertilizerEstimationOverview
    func selectNPK(optionId: String, for gardenId: String) async throws -> FertilizerEstimationOverview
    func saveNPK(optionId: String, for gardenId: String) async throws
}

/// In-memory mock repository conforming to `FertilizerEstimationRepositoryProtocol`.
/// Useful for unit testing, offline development, and SwiftUI previews.
public actor DummyFertilizerEstimationRepository: FertilizerEstimationRepositoryProtocol {
    private var state: FertilizerEstimationOverview

    public init(initialState: FertilizerEstimationOverview = .sample) {
        self.state = initialState
    }

    public func fetchEstimation(for gardenId: String) async throws -> FertilizerEstimationOverview {
        state
    }

    public func selectNPK(optionId: String, for gardenId: String) async throws -> FertilizerEstimationOverview {
        guard let selectedOption = state.npkOptions.first(where: { $0.id == optionId }) else {
            return state
        }

        // Calculate if there's any cheaper option remaining
        let minPrice = state.npkOptions.map(\.totalPrice).min() ?? selectedOption.totalPrice
        let savingsDiff = selectedOption.totalPrice - minPrice
        let savingsHint: String? = savingsDiff > 0
            ? "Ada pilihan NPK yang \(CurrencyFormatter.formatRupiah(savingsDiff)) lebih hemat."
            : nil

        // Update the NPK fertilizer row
        let updatedFertilizers = state.fertilizers.map { item -> FertilizerItem in
            if item.isCustomizableNPK {
                return FertilizerItem(
                    id: item.id,
                    name: selectedOption.name,
                    pricePerBag: selectedOption.pricePerBag,
                    bagWeightKg: item.bagWeightKg,
                    weightKg: selectedOption.weightKg,
                    bagCount: selectedOption.bagCount,
                    totalPrice: selectedOption.totalPrice,
                    isCustomizableNPK: true,
                    savingsHint: savingsHint
                )
            }
            return item
        }

        let updatedOverview = FertilizerEstimationOverview(
            id: state.id,
            gardenName: state.gardenName,
            periodDescription: state.periodDescription,
            budgetLimit: state.budgetLimit,
            fertilizers: updatedFertilizers,
            npkOptions: state.npkOptions,
            selectedNPKId: selectedOption.id,
            defaultNPKId: state.defaultNPKId,
            footnote: state.footnote
        )

        self.state = updatedOverview
        return updatedOverview
    }

    public func saveNPK(optionId: String, for gardenId: String) async throws {
        _ = try await selectNPK(optionId: optionId, for: gardenId)
    }
}

