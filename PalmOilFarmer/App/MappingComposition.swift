import Foundation

@MainActor
struct GardenMappingFactory {
    private let saving: any GardenRegistrationSaving
    private let authorization: () -> any GardenLocationAuthorizing
    private let allowsLocationDrafts: Bool

    init(saving: any GardenRegistrationSaving, authorization: @escaping () -> any GardenLocationAuthorizing,
         allowsLocationDrafts: Bool = true) {
        self.saving = saving
        self.authorization = authorization
        self.allowsLocationDrafts = allowsLocationDrafts
    }

    func makeViewModel(location: GardenLocation,
                       onFinish: @escaping (GardenMappingOutcome) -> Void) -> GardenBoundaryViewModel {
        GardenBoundaryViewModel(location: location, saving: saving, authorization: authorization(),
                                allowsLocationDrafts: allowsLocationDrafts, onFinish: onFinish)
    }
}
