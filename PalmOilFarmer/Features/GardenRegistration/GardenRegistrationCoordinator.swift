import Foundation
import Observation

enum GardenRegistrationStep { case guide, search }

@MainActor
@Observable
final class GardenRegistrationCoordinator {
    private(set) var step: GardenRegistrationStep
    var showsPhotoPicker = false
    private(set) var isFinished = false
    private var pendingPhotoLocation: GardenLocation?
    private let onLocate: (GardenLocation) -> Void
    private let onCancel: () -> Void

    init(initialStep: GardenRegistrationStep, onLocate: @escaping (GardenLocation) -> Void,
         onCancel: @escaping () -> Void) {
        step = initialStep
        self.onLocate = onLocate
        self.onCancel = onCancel
    }

    func continueToSearch() {
        guard !isFinished else { return }
        step = .search
    }

    func openPhotoPicker() {
        guard !isFinished, step == .search, !showsPhotoPicker else { return }
        pendingPhotoLocation = nil
        showsPhotoPicker = true
    }

    func selectedPhoto(_ location: GardenLocation) {
        guard !isFinished, showsPhotoPicker else { return }
        pendingPhotoLocation = location
        showsPhotoPicker = false
    }

    func photoPickerDidDismiss() {
        showsPhotoPicker = false
        guard !isFinished, let location = pendingPhotoLocation else { return }
        pendingPhotoLocation = nil
        selectLocation(location)
    }

    func selectLocation(_ location: GardenLocation) {
        guard !isFinished, !showsPhotoPicker, pendingPhotoLocation == nil else { return }
        isFinished = true
        onLocate(location)
    }

    func cancel() {
        guard !isFinished else { return }
        isFinished = true
        pendingPhotoLocation = nil
        showsPhotoPicker = false
        onCancel()
    }
}

@MainActor
struct GardenRegistrationServices {
    let locations: any GardenLocationRepository
    let photos: any GardenPhotoRepository
}

@MainActor
struct GardenRegistrationFlow {
    let coordinator: GardenRegistrationCoordinator
    let searchViewModel: LocationSearchViewModel
    let photoViewModel: GardenPhotoPickerViewModel
}
