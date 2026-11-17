import Foundation
import Observation

@MainActor
@Observable
final class GardenDetailsCoordinator {
    var showsPlantingDate = false
    private(set) var isFinished = false

    func openPlantingDate() {
        guard !isFinished, !showsPlantingDate else { return }
        showsPlantingDate = true
    }

    func close() { isFinished = true }
}

@MainActor
struct GardenDetailsFlow {
    let viewModel: GardenDetailsViewModel
    let coordinator: GardenDetailsCoordinator
}
