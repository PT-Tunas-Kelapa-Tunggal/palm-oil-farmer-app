import Foundation

/// Saves registration results into the shared garden data source.
/// One SwiftData container backs every feature, so the garden list updates by itself after a save.
@MainActor
final class GardenRegistrationRepository: GardenRegistrationSaving {
    private let gardens: any GardenDataSource

    init(gardens: any GardenDataSource) {
        self.gardens = gardens
    }

    func saveGarden(_ garden: Garden, completingDraft draftID: UUID?) -> Bool {
        gardens.add(garden, completingDraft: draftID)
    }

    func saveLocationDraft(_ draft: GardenDraft) -> Bool {
        gardens.addDraft(draft)
    }
}
