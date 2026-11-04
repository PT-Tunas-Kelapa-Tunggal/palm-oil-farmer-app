import Foundation
import Observation

@MainActor
@Observable
final class GardenHistoryEditorCoordinator {
    var selectedDraftID: UUID?
    private(set) var isFinished = false

    func selectType(for id: UUID) {
        guard !isFinished else { return }
        selectedDraftID = id
    }

    func close() { isFinished = true }
}

@MainActor
struct FertilizerHistoryFlow {
    let viewModel: FertilizerHistoryViewModel
    let coordinator: GardenHistoryEditorCoordinator
}

@MainActor
struct HarvestHistoryFlow {
    let viewModel: HarvestHistoryViewModel
    let coordinator: GardenHistoryEditorCoordinator
}
