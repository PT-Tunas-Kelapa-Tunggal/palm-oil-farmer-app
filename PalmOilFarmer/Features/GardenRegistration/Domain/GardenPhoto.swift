import Foundation

/// (4) Domain model: a library photo that may reveal where a garden is.
struct GardenPhoto: Identifiable {
    let id: String
    let coordinate: GardenCoordinate?
    let creationDate: Date?

    /// Keep photos without GPS so the preview can explain why they cannot locate a garden.
    init?(id: String, coordinate: GardenCoordinate?, creationDate: Date?,
          isUserLibrary: Bool, isScreenshot: Bool) {
        guard isUserLibrary, !isScreenshot else { return nil }
        self.id = id
        self.coordinate = coordinate
        self.creationDate = creationDate
    }
}

enum GardenPhotoAccess { case unknown, allowed, denied }

struct GardenPhotoLibrarySnapshot {
    let access: GardenPhotoAccess
    let photos: [GardenPhoto]
}
