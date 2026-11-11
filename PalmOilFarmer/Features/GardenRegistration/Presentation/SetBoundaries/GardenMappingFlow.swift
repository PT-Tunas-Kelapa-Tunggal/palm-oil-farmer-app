import Foundation

/// Everything the boundary map needs. Built by `GardenMappingFactory` (App/MappingComposition).
/// `makeDetailsFlow` builds step 3 (`GardenDetailsFlow`) when the boundary is confirmed.
@MainActor
struct GardenMappingFlow {
    let viewModel: GardenBoundaryViewModel
    let coordinator: GardenMappingCoordinator
    let makeDetailsFlow: () -> GardenDetailsFlow
}
