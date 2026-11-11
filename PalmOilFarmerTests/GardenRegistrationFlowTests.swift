import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenRegistrationFlowTests {
    private let coordinate = GardenCoordinate(latitude: 1, longitude: 104)

    private func location() -> GardenLocation {
        GardenLocation(name: "Dumai", subtitle: "Riau", coordinate: coordinate)
    }

    private func introModel(_ step: GardenRegistrationStep, onLocate: @escaping (GardenLocation) -> Void,
                            onCancel: @escaping () -> Void = {}) -> RegistrationIntroViewModel {
        RegistrationIntroViewModel(services: makeTestRegistrationServices(), initialStep: step,
                                   onLocate: onLocate, onCancel: onCancel)
    }

    @Test func guideAdvancesToSearchBeforeOpeningGallery() {
        let model = introModel(.guide, onLocate: { _ in })
        model.openPhotoPicker()
        #expect(model.step == .guide && !model.showsPhotoPicker)
        model.continueToSearch()
        model.openPhotoPicker()
        #expect(model.step == .search && model.showsPhotoPicker)
    }

    @Test func selectedPhotoEmitsOnceOnlyAfterGalleryDismissal() {
        var selected: [GardenLocation] = []
        let model = introModel(.search, onLocate: { selected.append($0) })
        model.openPhotoPicker()
        model.selectedPhoto(GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun", coordinate: coordinate, source: .photo))
        #expect(!model.showsPhotoPicker && selected.isEmpty && !model.isFinished)
        model.photoPickerDidDismiss()
        model.photoPickerDidDismiss()
        #expect(selected.count == 1 && model.isFinished)
        #expect(selected.first?.coordinate == coordinate && selected.first?.source == .photo)
        #expect(selected.first?.name == "Lokasi dari foto" && selected.first?.subtitle == "Foto kebun")
    }

    @Test func cancelledGalleryStaysInSearchAndCanBeOpenedAgain() {
        var selections = 0
        let model = introModel(.search, onLocate: { _ in selections += 1 })
        model.openPhotoPicker()
        model.showsPhotoPicker = false
        model.photoPickerDidDismiss()
        #expect(selections == 0 && !model.isFinished && model.step == .search)
        model.openPhotoPicker()
        model.selectedPhoto(GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun", coordinate: coordinate, source: .photo))
        model.photoPickerDidDismiss()
        #expect(selections == 1)
    }

    @Test func cancellingRegistrationRejectsLatePhotoAndGPSCallbacks() {
        var selections = 0, cancellations = 0
        let model = introModel(.search, onLocate: { _ in selections += 1 }, onCancel: { cancellations += 1 })
        model.openPhotoPicker()
        model.selectedPhoto(GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun", coordinate: coordinate, source: .photo))
        model.cancel()
        model.cancel()
        model.photoPickerDidDismiss()
        model.selectLocation(location())
        model.openPhotoPicker()
        #expect(cancellations == 1 && selections == 0 && !model.showsPhotoPicker)
    }

    @Test func photoPresentationAndDismissalCannotBeInterruptedByLateLocation() {
        var selected: [GardenLocation] = []
        let model = introModel(.search, onLocate: { selected.append($0) })
        model.openPhotoPicker()
        model.selectLocation(location())
        #expect(selected.isEmpty && model.showsPhotoPicker)
        model.selectedPhoto(GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun", coordinate: coordinate, source: .photo))
        model.selectLocation(location())
        #expect(selected.isEmpty)
        model.photoPickerDidDismiss()
        #expect(selected.count == 1 && selected.first?.source == .photo)
    }

    @Test func selectedSearchLocationPreservesIdentityAndPreventsSecondNavigation() {
        var selected: [GardenLocation] = []
        var cancellations = 0
        let model = introModel(.search, onLocate: { selected.append($0) }, onCancel: { cancellations += 1 })
        let value = location()
        model.selectLocation(value)
        model.selectLocation(location())
        model.cancel()
        #expect(selected.map(\.id) == [value.id] && cancellations == 0)
    }

    @Test func compositionDefersServicesUntilViewModelCreationAndUsesSeparateServicesPerSheet() async {
        var locations: [LocationRepositoryStub] = []
        let value = location()
        let dependencies = AppDependencies(
            modelContainer: AppConfiguration.makeModelContainer(inMemory: true), reviewRepository: ReviewRepositoryStub(),
            registrationServices: {
                let repository = LocationRepositoryStub()
                repository.currentResult = value
                locations.append(repository)
                return GardenRegistrationServices(locations: repository, photos: PhotoRepositoryStub())
            },
            mappingAuthorization: makeTestMappingAuthorization
        )
        #expect(locations.isEmpty)
        dependencies.coordinator.handle(.registerGarden)
        let model = dependencies.registrationFactory.makeViewModel(
            initialStep: .search, onLocate: dependencies.coordinator.locatedGarden,
            onCancel: dependencies.coordinator.cancelRegistration
        )
        _ = dependencies.registrationFactory.makeViewModel(initialStep: .search, onLocate: { _ in }, onCancel: {})
        #expect(locations.count == 2 && locations[0] !== locations[1])
        model.searchViewModel.requestCurrentLocation()
        await model.searchViewModel.locateCurrentIfRequested()
        #expect(locations[0].currentRequests == 1 && locations[1].currentRequests == 0)
        #expect(dependencies.coordinator.registrationSheet == nil && dependencies.coordinator.mappingLocation == nil)
        dependencies.coordinator.registrationDidDismiss()
        #expect(dependencies.coordinator.mappingLocation?.id == value.id)
    }

    @Test func composedPhotoSelectionWaitsForBothGalleryAndRegistrationDismissal() async throws {
        let repository = PhotoRepositoryStub()
        let photo = try #require(GardenPhoto(id: "photo", coordinate: coordinate, creationDate: nil,
                                             isUserLibrary: true, isScreenshot: false))
        repository.snapshot = GardenPhotoLibrarySnapshot(access: .allowed, photos: [photo])
        let dependencies = AppDependencies(
            modelContainer: AppConfiguration.makeModelContainer(inMemory: true), reviewRepository: ReviewRepositoryStub(),
            registrationServices: { GardenRegistrationServices(locations: LocationRepositoryStub(), photos: repository) },
            mappingAuthorization: makeTestMappingAuthorization
        )
        dependencies.coordinator.handle(.registerGarden)
        let model = dependencies.registrationFactory.makeViewModel(
            initialStep: .guide, onLocate: dependencies.coordinator.locatedGarden,
            onCancel: dependencies.coordinator.cancelRegistration
        )
        model.continueToSearch()
        model.openPhotoPicker()
        await model.photoViewModel.load()
        #expect(model.photoViewModel.selectPhoto(id: photo.id))
        #expect(dependencies.coordinator.registrationSheet == .guide)
        #expect(dependencies.coordinator.mappingLocation == nil)
        model.photoPickerDidDismiss()
        #expect(dependencies.coordinator.registrationSheet == nil && dependencies.coordinator.mappingLocation == nil)
        dependencies.coordinator.registrationDidDismiss()
        #expect(dependencies.coordinator.mappingLocation?.source == .photo)
        #expect(dependencies.coordinator.mappingLocation?.coordinate == coordinate)
    }

    @Test func composedCancellationCannotReopenMappingFromLateGPSResult() async {
        let repository = ControlledLocationRepository()
        let dependencies = AppDependencies(
            modelContainer: AppConfiguration.makeModelContainer(inMemory: true), reviewRepository: ReviewRepositoryStub(),
            registrationServices: { GardenRegistrationServices(locations: repository, photos: PhotoRepositoryStub()) },
            mappingAuthorization: makeTestMappingAuthorization
        )
        dependencies.coordinator.handle(.registerGarden)
        let model = dependencies.registrationFactory.makeViewModel(
            initialStep: .search, onLocate: dependencies.coordinator.locatedGarden,
            onCancel: dependencies.coordinator.cancelRegistration
        )
        model.searchViewModel.requestCurrentLocation()
        let pending = Task { await model.searchViewModel.locateCurrentIfRequested() }
        await repository.waitForCurrentLocation()
        model.cancel()
        repository.finishCurrentLocation(with: .success(location()))
        await pending.value
        dependencies.coordinator.registrationDidDismiss()
        #expect(dependencies.coordinator.registrationSheet == nil && dependencies.coordinator.mappingLocation == nil)
    }
}
