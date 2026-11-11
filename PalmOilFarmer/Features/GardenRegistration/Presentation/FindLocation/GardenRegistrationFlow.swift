import Foundation

/// Data sources step 1 needs. Built at the composition root (`App/RegistrationComposition`).
@MainActor
struct GardenRegistrationServices {
    let locations: any GardenLocationRepository
    let photos: any GardenPhotoRepository
}

/// Everything the "Cari Lokasi" sheet needs: one coordinator plus the view models it drives.
@MainActor
struct GardenRegistrationFlow {
    let coordinator: GardenRegistrationCoordinator
    let searchViewModel: LocationSearchViewModel
    let photoViewModel: GardenPhotoPickerViewModel
}
