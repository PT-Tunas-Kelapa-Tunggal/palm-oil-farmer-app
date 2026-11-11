import Foundation

@MainActor
struct GardenProfileFactory {
    let source: any GardenProfileDataSource
    let reviewRepository: any FarmerReviewRepository
    let reviewRequestFactory: ReviewRequestFactory

    func makeFlow(garden: Garden) -> GardenProfileFlow {
        let coordinator = GardenProfileCoordinator()
        let presentation = GardenProfileReviewPresentation()
        let model = GardenProfileViewModel(garden: garden, source: source,
            isActive: { !coordinator.isFinished }, canDeleteNow: { coordinator.canDeleteNow }, onDeleted: coordinator.close)
        return GardenProfileFlow(
            viewModel: model, coordinator: coordinator, reviewPresentation: presentation,
            reviewRepository: reviewRepository,
            makeReviewRequest: { sheet in
                let currentGarden = model.garden
                return reviewRequestFactory.makeFlow(gardenID: model.gardenID,
                    gardenName: currentGarden.name, areaHectares: currentGarden.boundary.areaHectares,
                    isActive: { sheet.kind == .review && coordinator.isCurrent(sheet) },
                    onSubmitted: { saved in
                        if coordinator.isCurrent(sheet) { presentation.submitted(saved) }
                    }, onClose: { coordinator.closeSheet(sheet) })
            },
            makeDetailsEditor: { sheet in
                let editor = GardenDetailsCoordinator()
                let latest = model.garden
                return GardenDetailsFlow(
                    viewModel: GardenDetailsViewModel(locationName: latest.locationName, boundary: latest.boundary, editing: latest,
                        isActive: { !editor.isFinished && sheet.kind == .details && coordinator.isCurrent(sheet) },
                        onSave: model.saveDetails, onSaved: { editor.close(); coordinator.closeSheet(sheet) }),
                    coordinator: editor
                )
            },
            makeProfileEditor: { sheet in
                GardenProfileEditorViewModel(garden: model.garden,
                    isActive: { sheet.kind == .profile && coordinator.isCurrent(sheet) },
                    onSave: { model.saveProfile(harvest: $0, frequency: $1, fertilizers: $2) },
                    onSaved: { coordinator.profileSaved(sheet) })
            }
        )
    }
}
