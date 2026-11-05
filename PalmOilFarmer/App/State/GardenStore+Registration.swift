import Foundation

extension GardenStore: GardenRegistrationSaving {
    func saveGarden(_ garden: Garden, completingDraft draftID: UUID?) -> Bool {
        add(garden, completingDraft: draftID)
    }

    func saveLocationDraft(_ draft: GardenDraft) -> Bool { addDraft(draft) }
}
