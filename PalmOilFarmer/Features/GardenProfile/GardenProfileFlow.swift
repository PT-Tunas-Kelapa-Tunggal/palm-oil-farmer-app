import Foundation

@MainActor
struct GardenProfileFlow {
    let viewModel: GardenProfileViewModel
    let coordinator: GardenProfileCoordinator
    let reviewBridge: GardenProfileReviewBridge
    let reviewRepository: any FarmerReviewRepository
    let submitReview: (Garden, ReviewContactDetails) async throws -> PlantationReviewRequest
    let makeDetailsEditor: (GardenProfileSheet) -> GardenDetailsFlow
    let makeFertilizerEditor: (GardenProfileSheet) -> FertilizerHistoryFlow
    let makeHarvestEditor: (GardenProfileSheet) -> HarvestHistoryFlow
}
