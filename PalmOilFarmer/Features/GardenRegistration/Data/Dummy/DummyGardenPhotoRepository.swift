#if DEBUG
import Foundation

/// (2) Dummy repository for canvas previews: a fixed gallery. Never asks for Photos permission.
/// Thumbnail bytes are injected (PreviewSupport passes the `RegistrationPhotoReference` asset),
/// so this Data-layer file needs no UI framework.
@MainActor
struct DummyGardenPhotoRepository: GardenPhotoRepository {
    enum Scenario { case photos, denied, empty }

    let scenario: Scenario
    let imageData: Data?

    init(_ scenario: Scenario = .photos, imageData: Data? = nil) {
        self.scenario = scenario
        self.imageData = imageData
    }

    func loadPhotos() async -> GardenPhotoLibrarySnapshot {
        switch scenario {
        case .photos: GardenPhotoLibrarySnapshot(access: .allowed, photos: Self.samplePhotos)
        case .denied: GardenPhotoLibrarySnapshot(access: .denied, photos: [])
        case .empty: GardenPhotoLibrarySnapshot(access: .allowed, photos: [])
        }
    }

    func thumbnails(for photoID: String) -> AsyncStream<Data> {
        let data = imageData
        return AsyncStream { continuation in
            if let data { continuation.yield(data) }
            continuation.finish()
        }
    }

    /// The photo with id `dummy-photo-3` has no GPS, to preview the "Foto tanpa lokasi" state.
    static var samplePhotos: [GardenPhoto] {
        (0..<16).compactMap { index in
            GardenPhoto(
                id: "dummy-photo-\(index)",
                coordinate: index == 3 ? nil
                    : GardenCoordinate(latitude: 1.106115 + Double(index) * 0.0002, longitude: 104.119121),
                creationDate: Date(timeIntervalSince1970: 1_793_582_040 - Double(index) * 86_400),
                isUserLibrary: true,
                isScreenshot: false
            )
        }
    }
}
#endif
