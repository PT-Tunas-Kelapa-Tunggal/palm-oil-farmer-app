import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct RegistrationDesignFlowTests {
    @Test func photoPreviewDoesNotNavigateUntilConfirmedAndGalleryDismisses() async throws {
        let repository = PhotoRepositoryStub()
        let coordinate = GardenCoordinate(latitude: 1.106115, longitude: 104.119121)
        let photo = try #require(GardenPhoto(id: "preview", coordinate: coordinate, creationDate: nil,
                                             isUserLibrary: true, isScreenshot: false))
        repository.snapshot = GardenPhotoLibrarySnapshot(access: .allowed, photos: [photo])
        var selections: [GardenLocation] = []
        let intro = RegistrationIntroViewModel(services: makeTestRegistrationServices(), initialStep: .search,
            onLocate: { selections.append($0) }, onCancel: {})
        let model = GardenPhotoPickerViewModel(
            repository: repository,
            resolveLocation: { GardenLocation(name: "Malang Rapat", subtitle: "Bintan", coordinate: $0) },
            onSelect: intro.selectedPhoto
        )
        intro.openPhotoPicker()
        await model.load()
        #expect(model.showPreview(for: photo.id))
        await model.preparePreview(for: photo.id)
        #expect(selections.isEmpty && intro.showsPhotoPicker)
        let data = Data([1, 2, 3])
        #expect(model.confirmPreview(imageData: data))
        #expect(selections.isEmpty && !intro.showsPhotoPicker)
        intro.photoPickerDidDismiss()
        #expect(selections.count == 1)
        #expect(selections.first?.name == "Malang Rapat")
        #expect(selections.first?.source == .photo)
        #expect(selections.first?.photoPreviewData == data)
    }

    @Test func abandoningPhotoPreviewCannotConfirmOldSelection() async throws {
        let repository = PhotoRepositoryStub()
        let photo = try #require(GardenPhoto(id: "preview",
            coordinate: GardenCoordinate(latitude: 1, longitude: 104),
            creationDate: nil, isUserLibrary: true, isScreenshot: false))
        repository.snapshot = GardenPhotoLibrarySnapshot(access: .allowed, photos: [photo])
        var selectionCount = 0
        let model = GardenPhotoPickerViewModel(repository: repository, onSelect: { _ in selectionCount += 1 })
        await model.load()
        #expect(model.showPreview(for: photo.id))
        await model.preparePreview(for: photo.id)
        model.clearPreview()
        #expect(!model.confirmPreview(imageData: nil) && selectionCount == 0)
        #expect(model.showPreview(for: photo.id))
        await model.preparePreview(for: photo.id)
        model.cancelLoading()
        #expect(!model.confirmPreview(imageData: nil) && selectionCount == 0)
    }

    @Test func switchingPreviewClearsPreviousAddressAndRequiresNewConfirmation() async throws {
        let repository = PhotoRepositoryStub()
        let firstCoordinate = GardenCoordinate(latitude: 1, longitude: 104)
        let secondCoordinate = GardenCoordinate(latitude: 2, longitude: 105)
        let first = try #require(GardenPhoto(id: "first", coordinate: firstCoordinate, creationDate: nil,
                                             isUserLibrary: true, isScreenshot: false))
        let second = try #require(GardenPhoto(id: "second", coordinate: secondCoordinate, creationDate: nil,
                                              isUserLibrary: true, isScreenshot: false))
        repository.snapshot = GardenPhotoLibrarySnapshot(access: .allowed, photos: [first, second])
        var selections: [GardenLocation] = []
        let model = GardenPhotoPickerViewModel(repository: repository, onSelect: { selections.append($0) })
        await model.load()
        #expect(model.showPreview(for: first.id))
        await model.preparePreview(for: first.id)
        #expect(model.previewLocation?.coordinate == firstCoordinate)
        #expect(model.showPreview(for: second.id))
        #expect(model.previewPhotoID == second.id && model.previewLocation == nil)
        #expect(!model.confirmPreview(imageData: nil) && selections.isEmpty)
        await model.preparePreview(for: second.id)
        #expect(model.confirmPreview(imageData: nil))
        #expect(selections.count == 1 && selections.first?.coordinate == secondCoordinate)
        #expect(!model.confirmPreview(imageData: nil))
    }

    @Test func abandonedPreviewRejectsAddressThatFinishesAfterReturningToGallery() async throws {
        let repository = PhotoRepositoryStub()
        let coordinate = GardenCoordinate(latitude: 1, longitude: 104)
        let photo = try #require(GardenPhoto(id: "pending", coordinate: coordinate, creationDate: nil,
                                             isUserLibrary: true, isScreenshot: false))
        repository.snapshot = GardenPhotoLibrarySnapshot(access: .allowed, photos: [photo])
        var pending: CheckedContinuation<GardenLocation, Never>?
        var selections = 0
        let model = GardenPhotoPickerViewModel(repository: repository, resolveLocation: { _ in
            await withCheckedContinuation { pending = $0 }
        }, onSelect: { _ in selections += 1 })
        await model.load()
        #expect(model.showPreview(for: photo.id))
        let request = Task { await model.preparePreview(for: photo.id) }
        while pending == nil { await Task.yield() }
        model.clearPreview()
        pending?.resume(returning: GardenLocation(name: "Alamat terlambat", subtitle: "", coordinate: coordinate))
        await request.value
        #expect(model.previewPhotoID == nil && model.previewLocation == nil)
        #expect(!model.confirmPreview(imageData: nil) && selections == 0)
    }

    @Test func searchingAgainCannotSilentlyDiscardDrawnBoundary() {
        var outcomes: [GardenMappingOutcome] = []
        let model = GardenBoundaryViewModel(location: mappingLocation(), saving: RegistrationSavingSpy(),
            authorization: MappingAuthorizationStub(), allowsLocationDrafts: true, onFinish: { outcomes.append($0) })
        model.addPoint(mappingPoints()[0])
        model.searchAgain()
        #expect(outcomes.isEmpty && model.boundary.points.count == 1)
        model.clear()
        model.searchAgain()
        #expect(outcomes == [.searchAgain])
    }
    @Test func photoWithoutGPSCanBePreviewedButNeverSelected() async throws {
        let repository = PhotoRepositoryStub()
        let photo = try #require(GardenPhoto(id: "no-gps", coordinate: nil, creationDate: nil,
                                             isUserLibrary: true, isScreenshot: false))
        repository.snapshot = GardenPhotoLibrarySnapshot(access: .allowed, photos: [photo])
        var selections = 0
        let model = GardenPhotoPickerViewModel(repository: repository, onSelect: { _ in selections += 1 })
        await model.load()
        #expect(model.showPreview(for: photo.id))
        await model.preparePreview(for: photo.id)
        #expect(model.previewHasNoLocation)
        #expect(!model.selectPhoto(id: photo.id))
        #expect(!model.confirmPreview(imageData: nil))
        #expect(selections == 0)
        model.clearPreview()
        #expect(!model.previewHasNoLocation)
    }

    @Test func fourCornersCloseThePreviewAndConfirmWithoutTappingTheFirstPoint() {
        let model = GardenBoundaryViewModel(location: mappingLocation(), saving: RegistrationSavingSpy(),
            authorization: MappingAuthorizationStub(), allowsLocationDrafts: false, onFinish: { _ in })
        let points = mappingPoints()
        points.prefix(3).forEach(model.addPoint)
        #expect(model.boundary.isValid && !model.canConfirmBoundary)
        model.confirmBoundary()
        #expect(!model.showsDetails && !model.isClosed)
        model.addPoint(points[3])
        #expect(model.isClosed && model.canConfirmBoundary)
        model.undo()
        #expect(!model.isClosed && model.boundary.points.count == 3)
        model.confirmBoundary()
        #expect(!model.showsDetails)
        model.clear()
        #expect(!model.isClosed && model.boundary.points.isEmpty)
        points.forEach(model.addPoint)
        model.confirmBoundary()
        #expect(model.showsDetails)
        // The open "Data Kebun" sheet locks the boundary it is about to save.
        model.clear()
        #expect(model.isClosed && model.boundary.points == points)
    }
}
