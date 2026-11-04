import Foundation

// Preserve callbacks used by the profile, reference screens, and team experiment.
extension GardenBoundaryView {
    init(location: GardenLocation, onSave: @escaping (Garden) -> Bool,
         onSaveDraft: ((GardenLocation) -> Bool)? = nil, onSearchAgain: (() -> Void)? = nil) {
        let saving = CallbackRegistrationSaving(
            onSave: { garden, _ in onSave(garden) }, onSaveDraft: { _ in onSaveDraft?(location) ?? false }
        )
        self.init(flow: GardenMappingFactory(saving: saving, authorization: { MappingLocationAuthorization() },
                                             allowsLocationDrafts: onSaveDraft != nil).makeFlow(location: location) { outcome in
            if outcome == .searchAgain { onSearchAgain?() }
        })
    }
}

extension GardenDetailsView {
    init(location: GardenLocation, boundary: GardenBoundary, onSave: @escaping (Garden) -> Bool,
         referenceMapImage: String? = nil, metrics: GardenDisplayMetrics? = nil) {
        let coordinator = GardenDetailsCoordinator()
        let flow = GardenDetailsFlow(
            viewModel: GardenDetailsViewModel(locationName: location.name, boundary: boundary,
                isActive: { !coordinator.isFinished }, onSave: onSave, onSaved: {}),
            coordinator: coordinator
        )
        self.init(flow: flow, referenceMapImage: referenceMapImage, metrics: metrics)
    }

    init(editing garden: Garden, referenceMapImage: String? = nil, metrics: GardenDisplayMetrics? = nil,
         onSave: @escaping (Garden) -> Bool) {
        let coordinator = GardenDetailsCoordinator()
        self.init(flow: GardenDetailsFlow(
            viewModel: GardenDetailsViewModel(locationName: garden.locationName, boundary: garden.boundary,
                editing: garden, isActive: { !coordinator.isFinished }, onSave: onSave, onSaved: coordinator.close),
            coordinator: coordinator
        ), referenceMapImage: referenceMapImage, metrics: metrics)
    }
}

@MainActor
private struct CallbackRegistrationSaving: GardenRegistrationSaving {
    let onSave: (Garden, UUID?) -> Bool
    let onSaveDraft: (GardenDraft) -> Bool
    func saveGarden(_ garden: Garden, completingDraft draftID: UUID?) -> Bool { onSave(garden, draftID) }
    func saveLocationDraft(_ draft: GardenDraft) -> Bool { onSaveDraft(draft) }
}
