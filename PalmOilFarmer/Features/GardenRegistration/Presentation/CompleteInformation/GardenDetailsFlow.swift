import Foundation

/// Everything the "Data Kebun" sheet needs. Built in `App/MappingComposition` (registration)
/// or `App/LegacyMappingComposition` (editing from the garden profile).
@MainActor
struct GardenDetailsFlow {
    let viewModel: GardenDetailsViewModel
    let coordinator: GardenDetailsCoordinator
}
