import Foundation

/// (1) Repository protocol: reads garden photos. Real impl: `PhotosGardenPhotoRepository`,
/// canvas/offline impl: `DummyGardenPhotoRepository`.
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
