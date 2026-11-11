import Foundation

@MainActor
struct GardenRegistrationFactory {
    private let services: () -> GardenRegistrationServices

    init(services: @escaping () -> GardenRegistrationServices) {
        self.services = services
    }

    func makeViewModel(initialStep: GardenRegistrationStep,
                       initialQuery: String = "", initialResults: [GardenLocation] = [],
                       onLocate: @escaping (GardenLocation) -> Void,
                       onCancel: @escaping () -> Void) -> RegistrationIntroViewModel {
        RegistrationIntroViewModel(services: services(), initialStep: initialStep,
                                   initialQuery: initialQuery, initialResults: initialResults,
                                   onLocate: onLocate, onCancel: onCancel)
    }

    static func liveServices() -> GardenRegistrationServices {
        GardenRegistrationServices(locations: MapKitGardenLocationRepository(), photos: PhotosGardenPhotoRepository())
    }
}
