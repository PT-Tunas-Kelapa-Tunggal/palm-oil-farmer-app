import Foundation
import Observation

@MainActor
@Observable
final class GardenPhotoPickerViewModel {
    private(set) var access = GardenPhotoAccess.unknown
    private(set) var photos: [GardenPhoto] = []
    private let repository: any GardenPhotoRepository
    private let onSelect: (GardenLocation) -> Void
    private var loadID: UUID?
    private let resolveLocation: (GardenCoordinate) async -> GardenLocation
    private(set) var previewPhotoID: String?
    private(set) var previewLocation: GardenLocation?

    init(repository: any GardenPhotoRepository,
         resolveLocation: @escaping (GardenCoordinate) async -> GardenLocation = {
             GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun", coordinate: $0, source: .photo)
         },
         onSelect: @escaping (GardenLocation) -> Void) {
        self.repository = repository
        self.onSelect = onSelect
        self.resolveLocation = resolveLocation
    }

    func load() async {
        let id = UUID()
        loadID = id
        clearPreview()
        access = .unknown
        photos = []
        let snapshot = await repository.loadPhotos()
        guard !Task.isCancelled, loadID == id else { return }
        access = snapshot.access
        photos = snapshot.photos
    }

    @discardableResult
    func selectPhoto(id: String) -> Bool {
        guard loadID != nil, access == .allowed, let photo = photos.first(where: { $0.id == id }) else { return false }
        let location = previewPhotoID == id ? previewLocation : nil
        onSelect(location ?? GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun",
                                           coordinate: photo.coordinate, source: .photo))
        return true
    }

    func thumbnails(for photoID: String) -> AsyncStream<Data> {
        repository.thumbnails(for: photoID)
    }

    func previewImages(for photoID: String) -> AsyncStream<Data> {
        repository.previewImages(for: photoID)
    }

    @discardableResult
    func showPreview(for photoID: String) -> Bool {
        guard loadID != nil, access == .allowed, photos.contains(where: { $0.id == photoID }) else { return false }
        previewPhotoID = photoID
        previewLocation = nil
        return true
    }

    func preparePreview(for photoID: String) async {
        guard let requestID = loadID, access == .allowed, previewPhotoID == photoID,
              let photo = photos.first(where: { $0.id == photoID }) else { return }
        var location = await resolveLocation(photo.coordinate)
        guard !Task.isCancelled, loadID == requestID, previewPhotoID == photoID else { return }
        location.source = .photo
        previewLocation = location
    }

    func confirmPreview(imageData: Data?) -> Bool {
        guard let id = previewPhotoID, var location = previewLocation else { return false }
        location.photoPreviewData = imageData
        previewLocation = location
        let selected = selectPhoto(id: id)
        if selected { clearPreview() }
        return selected
    }

    func clearPreview() {
        previewPhotoID = nil
        previewLocation = nil
    }

    func cancelLoading() {
        loadID = nil
        clearPreview()
    }
}
