import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenPhotoPickerViewModelTests {
    private let coordinate = GardenCoordinate(latitude: 1, longitude: 104)

    private func photo(_ id: String) throws -> GardenPhoto {
        try #require(GardenPhoto(id: id, coordinate: coordinate, creationDate: Date(timeIntervalSince1970: 1_000),
                                 isUserLibrary: true, isScreenshot: false))
    }

    @Test func eligibilityRetainsGeotagUserLibraryAndScreenshotRules() {
        let date = Date(timeIntervalSince1970: 1_000)
        for hasLocation in [false, true] {
            for isUserLibrary in [false, true] {
                for isScreenshot in [false, true] {
                    let value = GardenPhoto(id: "photo", coordinate: hasLocation ? coordinate : nil, creationDate: date,
                                            isUserLibrary: isUserLibrary, isScreenshot: isScreenshot)
                    #expect((value != nil) == (hasLocation && isUserLibrary && !isScreenshot))
                    if let value { #expect(value.id == "photo" && value.coordinate == coordinate && value.creationDate == date) }
                }
            }
        }
    }

    @Test func allowedLibraryPreservesRepositoryOrderingAndCoordinates() async throws {
        let repository = PhotoRepositoryStub()
        repository.snapshot = GardenPhotoLibrarySnapshot(access: .allowed, photos: [try photo("new"), try photo("old")])
        let model = GardenPhotoPickerViewModel(repository: repository, onSelect: { _ in })
        #expect(model.access == .unknown)
        await model.load()
        #expect(repository.loadCount == 1 && model.access == .allowed)
        #expect(model.photos.map(\.id) == ["new", "old"] && model.photos.first?.coordinate == coordinate)
    }

    @Test func deniedAndEmptyLibrariesDoNotAllowSelection() async {
        let repository = PhotoRepositoryStub()
        repository.snapshot = GardenPhotoLibrarySnapshot(access: .denied, photos: [])
        var selections = 0
        let model = GardenPhotoPickerViewModel(repository: repository, onSelect: { _ in selections += 1 })
        await model.load()
        #expect(model.access == .denied && !model.selectPhoto(id: "missing"))
        repository.snapshot = GardenPhotoLibrarySnapshot(access: .allowed, photos: [])
        await model.load()
        #expect(model.access == .allowed && model.photos.isEmpty && !model.selectPhoto(id: "missing"))
        #expect(selections == 0)
    }

    @Test func selectionUsesKnownPhotoMetadataOnly() async throws {
        let repository = PhotoRepositoryStub()
        repository.snapshot = GardenPhotoLibrarySnapshot(access: .allowed, photos: [try photo("known")])
        var selections: [GardenCoordinate] = []
        let model = GardenPhotoPickerViewModel(repository: repository, onSelect: { selections.append($0) })
        await model.load()
        #expect(!model.selectPhoto(id: "missing"))
        #expect(model.selectPhoto(id: "known"))
        #expect(selections == [coordinate])
    }

    @Test func invalidatedLoadCannotOverrideNewerLibrarySnapshot() async throws {
        let repository = ControlledPhotoRepository()
        let model = GardenPhotoPickerViewModel(repository: repository, onSelect: { _ in })
        let first = Task { await model.load() }
        await repository.waitForLoad(1)
        model.cancelLoading()
        let second = Task { await model.load() }
        await repository.waitForLoad(2)
        repository.finishLoad(2, with: GardenPhotoLibrarySnapshot(access: .allowed, photos: [try photo("latest")]))
        await second.value
        repository.finishLoad(1, with: GardenPhotoLibrarySnapshot(access: .denied, photos: []))
        await first.value
        #expect(model.access == .allowed && model.photos.map(\.id) == ["latest"])
    }

    @Test func cancelledLoadDoesNotPublishLatePermissionResult() async {
        let repository = ControlledPhotoRepository()
        let model = GardenPhotoPickerViewModel(repository: repository, onSelect: { _ in })
        let pending = Task { await model.load() }
        await repository.waitForLoad(1)
        pending.cancel()
        repository.finishLoad(1, with: GardenPhotoLibrarySnapshot(access: .denied, photos: []))
        await pending.value
        #expect(model.access == .unknown && model.photos.isEmpty)
    }

    @Test func reopenedGalleryCannotSelectStalePhotosWhilePermissionIsReloading() async throws {
        let repository = ControlledPhotoRepository()
        let model = GardenPhotoPickerViewModel(repository: repository, onSelect: { _ in })
        let first = Task { await model.load() }
        await repository.waitForLoad(1)
        repository.finishLoad(1, with: GardenPhotoLibrarySnapshot(access: .allowed, photos: [try photo("old")]))
        await first.value
        model.cancelLoading()
        #expect(!model.selectPhoto(id: "old"))
        let second = Task { await model.load() }
        await repository.waitForLoad(2)
        #expect(model.access == .unknown && model.photos.isEmpty && !model.selectPhoto(id: "old"))
        repository.finishLoad(2, with: GardenPhotoLibrarySnapshot(access: .denied, photos: []))
        await second.value
        #expect(model.access == .denied && !model.selectPhoto(id: "old"))
    }

    @Test func thumbnailUpdatesKeepPhotoIDAndProgressiveData() async {
        let repository = PhotoRepositoryStub()
        repository.thumbnailUpdates = [Data([1, 2]), Data([3, 4, 5])]
        let model = GardenPhotoPickerViewModel(repository: repository, onSelect: { _ in })
        var received: [Data] = []
        for await data in model.thumbnails(for: "photo") { received.append(data) }
        #expect(repository.thumbnailIDs == ["photo"] && received == repository.thumbnailUpdates)
    }
}
