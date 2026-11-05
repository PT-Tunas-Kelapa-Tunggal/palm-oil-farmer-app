import Foundation
import Observation

enum GardenRegistrationStep { case guide, search }

@MainActor
@Observable
final class GardenRegistrationCoordinator {
    private(set) var step: GardenRegistrationStep
    var showsPhotoPicker = false
    private(set) var isFinished = false
    private var pendingPhoto: GardenCoordinate?
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
        pendingPhoto = nil
        showsPhotoPicker = true
    }

    func selectedPhoto(_ coordinate: GardenCoordinate) {
        guard !isFinished, showsPhotoPicker else { return }
        pendingPhoto = coordinate
        showsPhotoPicker = false
    }

    func photoPickerDidDismiss() {
        showsPhotoPicker = false
        guard !isFinished, let coordinate = pendingPhoto else { return }
        pendingPhoto = nil
        selectLocation(GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun",
                                      coordinate: coordinate, source: .photo))
    }

    func selectLocation(_ location: GardenLocation) {
        guard !isFinished, !showsPhotoPicker, pendingPhoto == nil else { return }
        isFinished = true
        pendingPhoto = nil
        onLocate(location)
    }

    func cancel() {
        guard !isFinished else { return }
        isFinished = true
        pendingPhoto = nil
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
