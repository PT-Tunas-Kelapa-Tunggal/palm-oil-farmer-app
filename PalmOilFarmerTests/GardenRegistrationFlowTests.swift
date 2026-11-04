import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenRegistrationFlowTests {
    private let coordinate = GardenCoordinate(latitude: 1, longitude: 104)

    private func location() -> GardenLocation {
        GardenLocation(name: "Dumai", subtitle: "Riau", coordinate: coordinate)
    }

    @Test func guideAdvancesToSearchBeforeOpeningGallery() {
        let coordinator = GardenRegistrationCoordinator(initialStep: .guide, onLocate: { _ in }, onCancel: {})
        coordinator.openPhotoPicker()
        #expect(coordinator.step == .guide && !coordinator.showsPhotoPicker)
        coordinator.continueToSearch()
        coordinator.openPhotoPicker()
        #expect(coordinator.step == .search && coordinator.showsPhotoPicker)
    }

    @Test func selectedPhotoEmitsOnceOnlyAfterGalleryDismissal() {
        var selected: [GardenLocation] = []
        let coordinator = GardenRegistrationCoordinator(initialStep: .search, onLocate: { selected.append($0) }, onCancel: {})
        coordinator.openPhotoPicker()
        coordinator.selectedPhoto(coordinate)
        #expect(!coordinator.showsPhotoPicker && selected.isEmpty && !coordinator.isFinished)
        coordinator.photoPickerDidDismiss()
        coordinator.photoPickerDidDismiss()
        #expect(selected.count == 1 && coordinator.isFinished)
        #expect(selected.first?.coordinate == coordinate && selected.first?.source == .photo)
        #expect(selected.first?.name == "Lokasi dari foto" && selected.first?.subtitle == "Foto kebun")
    }

    @Test func cancelledGalleryStaysInSearchAndCanBeOpenedAgain() {
        var selections = 0
        let coordinator = GardenRegistrationCoordinator(initialStep: .search, onLocate: { _ in selections += 1 }, onCancel: {})
        coordinator.openPhotoPicker()
        coordinator.showsPhotoPicker = false
        coordinator.photoPickerDidDismiss()
        #expect(selections == 0 && !coordinator.isFinished && coordinator.step == .search)
        coordinator.openPhotoPicker()
        coordinator.selectedPhoto(coordinate)
        coordinator.photoPickerDidDismiss()
        #expect(selections == 1)
    }

    @Test func cancellingRegistrationRejectsLatePhotoAndGPSCallbacks() {
        var selections = 0, cancellations = 0
        let coordinator = GardenRegistrationCoordinator(initialStep: .search,
            onLocate: { _ in selections += 1 }, onCancel: { cancellations += 1 })
        coordinator.openPhotoPicker()
        coordinator.selectedPhoto(coordinate)
        coordinator.cancel()
        coordinator.cancel()
        coordinator.photoPickerDidDismiss()
        coordinator.selectLocation(location())
        coordinator.openPhotoPicker()
        #expect(cancellations == 1 && selections == 0 && !coordinator.showsPhotoPicker)
    }

    @Test func photoPresentationAndDismissalCannotBeInterruptedByLateLocation() {
        var selected: [GardenLocation] = []
        let coordinator = GardenRegistrationCoordinator(initialStep: .search, onLocate: { selected.append($0) }, onCancel: {})
        coordinator.openPhotoPicker()
        coordinator.selectLocation(location())
        #expect(selected.isEmpty && coordinator.showsPhotoPicker)
        coordinator.selectedPhoto(coordinate)
        coordinator.selectLocation(location())
        #expect(selected.isEmpty)
        coordinator.photoPickerDidDismiss()
        #expect(selected.count == 1 && selected.first?.source == .photo)
    }

    @Test func selectedSearchLocationPreservesIdentityAndPreventsSecondNavigation() {
        var selected: [GardenLocation] = []
        var cancellations = 0
        let coordinator = GardenRegistrationCoordinator(initialStep: .search,
            onLocate: { selected.append($0) }, onCancel: { cancellations += 1 })
        let value = location()
        coordinator.selectLocation(value)
        coordinator.selectLocation(location())
        coordinator.cancel()
        #expect(selected.map(\.id) == [value.id] && cancellations == 0)
    }

    @Test func compositionDefersServicesUntilFlowCreationAndUsesSeparateServicesPerFlow() async {
        var locations: [LocationRepositoryStub] = []
        let value = location()
        let dependencies = AppDependencies(
            modelContainer: AppConfiguration.makeModelContainer(inMemory: true), reviewRepository: ReviewRepositoryStub(),
            registrationServices: {
                let repository = LocationRepositoryStub()
                repository.currentResult = value
                locations.append(repository)
                return GardenRegistrationServices(locations: repository, photos: PhotoRepositoryStub())
            }
        )
        #expect(locations.isEmpty)
        dependencies.coordinator.handle(.registerGarden)
        let flow = dependencies.registrationFactory.makeFlow(
            initialStep: .search, onLocate: dependencies.coordinator.locatedGarden,
            onCancel: dependencies.coordinator.cancelRegistration
        )
        _ = dependencies.registrationFactory.makeFlow(initialStep: .search, onLocate: { _ in }, onCancel: {})
        #expect(locations.count == 2 && locations[0] !== locations[1])
        flow.searchViewModel.requestCurrentLocation()
        await flow.searchViewModel.locateCurrentIfRequested()
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
            registrationServices: { GardenRegistrationServices(locations: LocationRepositoryStub(), photos: repository) }
        )
        dependencies.coordinator.handle(.registerGarden)
        let flow = dependencies.registrationFactory.makeFlow(
            initialStep: .guide, onLocate: dependencies.coordinator.locatedGarden,
            onCancel: dependencies.coordinator.cancelRegistration
        )
        flow.coordinator.continueToSearch()
        flow.coordinator.openPhotoPicker()
        await flow.photoViewModel.load()
        #expect(flow.photoViewModel.selectPhoto(id: photo.id))
        #expect(dependencies.coordinator.registrationSheet == .guide)
        #expect(dependencies.coordinator.mappingLocation == nil)
        flow.coordinator.photoPickerDidDismiss()
        #expect(dependencies.coordinator.registrationSheet == nil && dependencies.coordinator.mappingLocation == nil)
        dependencies.coordinator.registrationDidDismiss()
        #expect(dependencies.coordinator.mappingLocation?.source == .photo)
        #expect(dependencies.coordinator.mappingLocation?.coordinate == coordinate)
    }

    @Test func composedCancellationCannotReopenMappingFromLateGPSResult() async {
        let repository = ControlledLocationRepository()
        let dependencies = AppDependencies(
            modelContainer: AppConfiguration.makeModelContainer(inMemory: true), reviewRepository: ReviewRepositoryStub(),
            registrationServices: { GardenRegistrationServices(locations: repository, photos: PhotoRepositoryStub()) }
        )
        dependencies.coordinator.handle(.registerGarden)
        let flow = dependencies.registrationFactory.makeFlow(
            initialStep: .search, onLocate: dependencies.coordinator.locatedGarden,
            onCancel: dependencies.coordinator.cancelRegistration
        )
        flow.searchViewModel.requestCurrentLocation()
        let pending = Task { await flow.searchViewModel.locateCurrentIfRequested() }
        await repository.waitForCurrentLocation()
        flow.coordinator.cancel()
        repository.finishCurrentLocation(with: .success(location()))
        await pending.value
        dependencies.coordinator.registrationDidDismiss()
        #expect(dependencies.coordinator.registrationSheet == nil && dependencies.coordinator.mappingLocation == nil)
    }
}
