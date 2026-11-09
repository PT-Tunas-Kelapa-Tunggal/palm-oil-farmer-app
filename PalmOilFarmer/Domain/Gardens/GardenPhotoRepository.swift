import Foundation

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

@MainActor
protocol GardenPhotoRepository {
    func loadPhotos() async -> GardenPhotoLibrarySnapshot
    /// Encoded thumbnail updates, including opportunistic lower-resolution images.
    func thumbnails(for photoID: String) -> AsyncStream<Data>
    func previewImages(for photoID: String) -> AsyncStream<Data>
}

extension GardenPhotoRepository {
    func previewImages(for photoID: String) -> AsyncStream<Data> { thumbnails(for: photoID) }
}
