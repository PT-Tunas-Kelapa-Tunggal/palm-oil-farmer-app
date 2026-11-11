import Foundation

/// Everything the boundary map needs. Built by `GardenMappingFactory` (App/MappingComposition).
/// `makeDetailsFlow` builds step 3 (`GardenDetailsViewModel`) when the boundary is confirmed.
@MainActor
struct GardenMappingFlow {
    let viewModel: GardenBoundaryViewModel
    let coordinator: GardenMappingCoordinator
    let makeDetailsFlow: () -> GardenDetailsViewModel
}
