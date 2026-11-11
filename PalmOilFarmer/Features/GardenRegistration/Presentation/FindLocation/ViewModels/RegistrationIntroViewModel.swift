import Foundation
import Observation

/// Which page the "Cari Lokasi" sheet shows.
enum GardenRegistrationStep { case guide, search }

/// "Cari Lokasi" sheet: the guide/search page, the photo sheet, and the hand-over to the map.
///
/// Owns the search and photo view models. A location is handed over (`onLocate`) only once, and a
/// photo location only after the photo sheet has finished dismissing.
@MainActor
@Observable
final class RegistrationIntroViewModel {
    private(set) var step: GardenRegistrationStep
    var showsPhotoPicker = false
    private(set) var isFinished = false
    let searchViewModel: LocationSearchViewModel
    let photoViewModel: GardenPhotoPickerViewModel

    private var pendingPhotoLocation: GardenLocation?
    private let onLocate: (GardenLocation) -> Void
    private let onCancel: () -> Void

    init(services: GardenRegistrationServices, initialStep: GardenRegistrationStep,
         initialQuery: String = "", initialResults: [GardenLocation] = [],
         onLocate: @escaping (GardenLocation) -> Void, onCancel: @escaping () -> Void) {
        weak var owner: RegistrationIntroViewModel?
        searchViewModel = LocationSearchViewModel(
            repository: services.locations, initialQuery: initialQuery, initialResults: initialResults,
            onSelect: { owner?.selectLocation($0) }
        )
        photoViewModel = GardenPhotoPickerViewModel(
            repository: services.photos,
            resolveLocation: { [locations = services.locations] in await locations.location(at: $0) },
            onSelect: { owner?.selectedPhoto($0) }
        )
        step = initialStep
        self.onLocate = onLocate
        self.onCancel = onCancel
        owner = self
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
