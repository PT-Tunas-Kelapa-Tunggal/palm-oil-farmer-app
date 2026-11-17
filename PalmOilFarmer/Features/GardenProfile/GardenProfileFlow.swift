import Foundation

@MainActor
struct GardenProfileFlow {
    let viewModel: GardenProfileViewModel
    let coordinator: GardenProfileCoordinator
    let reviewPresentation: GardenProfileReviewPresentation
    let reviewRepository: any FarmerReviewRepository
    let makeReviewRequest: (GardenProfileSheet) -> ReviewRequestFlow
    let makeDetailsEditor: (GardenProfileSheet) -> GardenDetailsFlow
    let makeProfileEditor: (GardenProfileSheet) -> GardenProfileEditorViewModel
}
