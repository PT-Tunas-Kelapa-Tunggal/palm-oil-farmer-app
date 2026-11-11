import Foundation

/// Data sources the "Cari Lokasi" step needs. Built at the composition root (`App/RegistrationComposition`).
@MainActor
struct GardenRegistrationServices {
    let locations: any GardenLocationRepository
    let photos: any GardenPhotoRepository
}
