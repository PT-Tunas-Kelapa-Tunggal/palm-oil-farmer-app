import Foundation
import Observation

@MainActor
@Observable
final class GardenPhotoPickerViewModel {
    private(set) var access = GardenPhotoAccess.unknown
    private(set) var photos: [GardenPhoto] = []
    private let repository: any GardenPhotoRepository
    private let onSelect: (GardenCoordinate) -> Void
    private var loadID: UUID?

    init(repository: any GardenPhotoRepository, onSelect: @escaping (GardenCoordinate) -> Void) {
        self.repository = repository
        self.onSelect = onSelect
    }

    func load() async {
        let id = UUID()
        loadID = id
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
        onSelect(photo.coordinate)
        return true
    }

    func thumbnails(for photoID: String) -> AsyncStream<Data> {
        repository.thumbnails(for: photoID)
    }

    func cancelLoading() { loadID = nil }
}
