import Foundation
import Observation

/// Step 3 of registration: complete the garden information (`GardenDetailsView`, a sheet over the map).
/// "Tahun Tanam" opens the `PlantingDatePickerView` sheet; after saving, the map shows
/// `GardenSavedConfirmationView` full screen. The same screen is reused to edit a garden from its profile.
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
