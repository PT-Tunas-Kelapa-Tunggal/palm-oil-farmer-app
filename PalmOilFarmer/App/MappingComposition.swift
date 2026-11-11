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

    func makeFlow(location: GardenLocation, onFinish: @escaping (GardenMappingOutcome) -> Void) -> GardenMappingFlow {
        let saving = self.saving
        let coordinator = GardenMappingCoordinator(onFinish: onFinish)
        let model = GardenBoundaryViewModel(location: location, saving: saving, authorization: authorization(),
                                            allowsLocationDrafts: allowsLocationDrafts,
                                            isActive: { coordinator.canEditBoundary }, onEvent: coordinator.handle)
        return GardenMappingFlow(viewModel: model, coordinator: coordinator, makeDetailsFlow: {
            let sessionID = coordinator.detailsSessionID
            return GardenDetailsViewModel(locationName: location.name, boundary: model.boundary,
                isActive: {
                    guard let sessionID else { return false }
                    return coordinator.isCurrentDetailsSession(sessionID)
                },
                onSave: { garden in
                    let saved = saving.saveGarden(garden, completingDraft: location.draftID)
                    if saved { coordinator.recordSavedGarden(garden.name) }
                    return saved
                }, onSaved: {
                    if let sessionID { coordinator.detailsSaved(sessionID: sessionID) }
                })
        })
    }
}
