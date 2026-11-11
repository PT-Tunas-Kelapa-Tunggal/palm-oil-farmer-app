#if DEBUG
import Foundation

/// Dummy `GardenRegistrationSaving`: accepts every save without touching SwiftData.
@MainActor
struct DummyGardenRegistrationSaving: GardenRegistrationSaving {
    var succeeds = true

    func saveGarden(_ garden: Garden, completingDraft draftID: UUID?) -> Bool { succeeds }
    func saveLocationDraft(_ draft: GardenDraft) -> Bool { succeeds }
}
#endif
