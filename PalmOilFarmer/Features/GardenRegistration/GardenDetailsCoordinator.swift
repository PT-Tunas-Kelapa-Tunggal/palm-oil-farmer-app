import Foundation
import Observation

enum GardenDetailsRoute: Hashable { case soilTypes }

@MainActor
@Observable
final class GardenDetailsCoordinator {
    var path: [GardenDetailsRoute] = []
    var showsPlantingDate = false
    private(set) var isFinished = false

    func openSoilTypes() {
        guard !isFinished, path.isEmpty, !showsPlantingDate else { return }
        path.append(.soilTypes)
    }

    func openPlantingDate() {
        guard !isFinished, path.isEmpty, !showsPlantingDate else { return }
        showsPlantingDate = true
    }

    func close() { isFinished = true }
}

@MainActor
struct GardenDetailsFlow {
    let viewModel: GardenDetailsViewModel
    let coordinator: GardenDetailsCoordinator
}
