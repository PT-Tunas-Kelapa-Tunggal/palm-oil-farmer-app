import Foundation
@testable import PalmOilFarmer

@MainActor
func mappingLocation(source: GardenLocation.Source = .search) -> GardenLocation {
    GardenLocation(name: "Dumai", subtitle: "Riau", coordinate: GardenCoordinate(latitude: 1, longitude: 104), source: source)
}

@MainActor
func mappingPoints() -> [GardenCoordinate] {
    [(1.0, 104.0), (1.0, 104.002), (1.002, 104.002), (1.002, 104.0)].map {
        GardenCoordinate(latitude: $0.0, longitude: $0.1)
    }
}

@MainActor
func completeDetails(_ model: GardenDetailsViewModel) {
    model.name = "Belakang rumah"
    model.plantingYear = 2016
    model.soilType = .peat
}

@MainActor
final class RegistrationSavingSpy: GardenRegistrationSaving {
    var acceptsGarden = true
    var acceptsDraft = true
    var gardens: [Garden] = []
    var completedDraftIDs: [UUID?] = []
    var drafts: [GardenDraft] = []

    func saveGarden(_ garden: Garden, completingDraft draftID: UUID?) -> Bool {
        gardens.append(garden)
        completedDraftIDs.append(draftID)
        return acceptsGarden
    }

    func saveLocationDraft(_ draft: GardenDraft) -> Bool {
        drafts.append(draft)
        return acceptsDraft
    }
}
