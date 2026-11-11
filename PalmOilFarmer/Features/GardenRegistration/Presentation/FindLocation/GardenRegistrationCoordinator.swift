import Foundation
import Observation

/// Step 1 of registration: find the garden location.
///
/// Navigation inside the "Cari Lokasi" sheet (`RegistrationIntroView`):
/// `.guide` → `LocationDiscoveryGuide`, `.search` → `LocationSearchView`,
/// and from search the photo sheet `GardenPhotoPickerView`.
/// When a location is chosen, `onLocate` hands over to step 2 (`SetBoundaries`).
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
