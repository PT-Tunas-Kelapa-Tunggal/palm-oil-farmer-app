import Foundation

@MainActor
struct GardenProfileFactory {
    let source: any GardenProfileDataSource
    let reviewRepository: any FarmerReviewRepository
    let submitReview: (Garden, ReviewContactDetails) async throws -> PlantationReviewRequest

    func makeFlow(garden: Garden) -> GardenProfileFlow {
        let coordinator = GardenProfileCoordinator()
        let model = GardenProfileViewModel(garden: garden, source: source,
            isActive: { !coordinator.isFinished }, canDeleteNow: { coordinator.canDeleteNow }, onDeleted: coordinator.close)
        return GardenProfileFlow(
            viewModel: model, coordinator: coordinator, reviewBridge: GardenProfileReviewBridge(),
            reviewRepository: reviewRepository, submitReview: submitReview,
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
            makeFertilizerEditor: { sheet in
                let editor = GardenHistoryEditorCoordinator()
                return FertilizerHistoryFlow(
                    viewModel: FertilizerHistoryViewModel(records: model.fertilizers,
                        isActive: { !editor.isFinished && sheet.kind == .fertilizer && coordinator.isCurrent(sheet) },
                        onSave: model.saveFertilizers, onSaved: { editor.close(); coordinator.closeSheet(sheet) }),
                    coordinator: editor
                )
            },
            makeHarvestEditor: { sheet in
                let editor = GardenHistoryEditorCoordinator()
                return HarvestHistoryFlow(
                    viewModel: HarvestHistoryViewModel(record: model.garden.harvestRecord,
                        isActive: { !editor.isFinished && sheet.kind == .harvest && coordinator.isCurrent(sheet) },
                        onSave: model.saveHarvest, onSaved: { editor.close(); coordinator.closeSheet(sheet) }),
                    coordinator: editor
                )
            }
        )
    }
}
