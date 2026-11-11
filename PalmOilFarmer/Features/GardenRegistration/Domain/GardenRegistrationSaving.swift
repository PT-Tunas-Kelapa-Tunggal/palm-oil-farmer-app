import Foundation

/// (1) Repository protocol: saves the registration result.
/// Real impl: `GardenRegistrationRepository` (writes through Core's `GardenDataSource`),
/// canvas impl: `DummyGardenRegistrationSaving`.
@MainActor
protocol GardenRegistrationSaving {
    func saveGarden(_ garden: Garden, completingDraft draftID: UUID?) -> Bool
    func saveLocationDraft(_ draft: GardenDraft) -> Bool
}
