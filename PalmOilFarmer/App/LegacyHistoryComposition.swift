import Foundation

extension FertilizerHistoryEditor {
    init(records: [FertilizerRecord], includesEmptyDraft: Bool = false, onSave: @escaping ([FertilizerRecord]) -> Bool) {
        let coordinator = GardenHistoryEditorCoordinator()
        self.init(flow: FertilizerHistoryFlow(
            viewModel: FertilizerHistoryViewModel(records: records, includesEmptyDraft: includesEmptyDraft,
                isActive: { !coordinator.isFinished }, onSave: onSave, onSaved: coordinator.close),
            coordinator: coordinator
        ))
    }
}

extension HarvestHistoryEditor {
    init(record: HarvestRecord?, onSave: @escaping (HarvestRecord) -> Bool) {
        let coordinator = GardenHistoryEditorCoordinator()
        self.init(flow: HarvestHistoryFlow(
            viewModel: HarvestHistoryViewModel(record: record, isActive: { !coordinator.isFinished },
                onSave: onSave, onSaved: coordinator.close), coordinator: coordinator
        ))
    }
}
