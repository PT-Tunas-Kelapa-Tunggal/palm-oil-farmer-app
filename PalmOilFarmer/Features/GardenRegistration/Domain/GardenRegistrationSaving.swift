import Foundation

/// Saves the registration result.
@MainActor
protocol GardenRegistrationSaving {
    func saveGarden(_ garden: Garden, completingDraft draftID: UUID?) -> Bool
    func saveLocationDraft(_ draft: GardenDraft) -> Bool
}
