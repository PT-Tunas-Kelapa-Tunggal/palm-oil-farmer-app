import Foundation

@MainActor
struct GardenRegistrationFactory {
    private let services: () -> GardenRegistrationServices

    init(services: @escaping () -> GardenRegistrationServices) {
        self.services = services
    }

    func makeFlow(initialStep: GardenRegistrationStep,
                  initialQuery: String = "", initialResults: [GardenLocation] = [],
                  onLocate: @escaping (GardenLocation) -> Void,
                  onCancel: @escaping () -> Void) -> GardenRegistrationFlow {
        let dependencies = services()
        let coordinator = GardenRegistrationCoordinator(initialStep: initialStep, onLocate: onLocate, onCancel: onCancel)
        return GardenRegistrationFlow(
            coordinator: coordinator,
            searchViewModel: LocationSearchViewModel(
                repository: dependencies.locations, initialQuery: initialQuery, initialResults: initialResults,
                onSelect: coordinator.selectLocation
            ),
            photoViewModel: GardenPhotoPickerViewModel(
                repository: dependencies.photos,
                resolveLocation: { [locations = dependencies.locations] in await locations.location(at: $0) },
                onSelect: coordinator.selectedPhoto
            )
        )
    }

    static func liveServices() -> GardenRegistrationServices {
        GardenRegistrationServices(locations: MapKitGardenLocationRepository(), photos: PhotosGardenPhotoRepository())
    }
}
