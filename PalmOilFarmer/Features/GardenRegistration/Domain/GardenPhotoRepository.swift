import Foundation

/// Reads garden photos.
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
