import Foundation
import Observation

enum AppRoute: Hashable {
    case gardenProfile(UUID)
    case requestAssessment(UUID)
    case resultOverview(gardenId: String)
    case nutrientCondition(gardenId: String)
    case farmGreenIndex(gardenId: String)
    case fertilizerEstimation(gardenId: String)
    #if DEBUG
    case developerMode
    #endif
}

enum RegistrationSheet: String, Identifiable {
    case guide, search
    var id: Self { self }
}

@MainActor
@Observable
final class AppCoordinator {
    // SwiftUI writes these bindings for Back, swipe-to-dismiss, and modal dismissal.
    var path: [AppRoute] = []
    var registrationSheet: RegistrationSheet?
    var mappingLocation: GardenLocation?

    private var pendingLocation: GardenLocation?
    private var reopensSearch = false

    init() {}

    func handle(_ event: DashboardEvent) {
        guard path.isEmpty, registrationSheet == nil, mappingLocation == nil, pendingLocation == nil else { return }
        switch event {
        case .openGarden(let id):
            openGarden(id)
        case .resumeDraft(let draft):
            reopensSearch = false
            mappingLocation = DashboardMapper().mappingLocation(for: draft)
        case .registerGarden:
            reopensSearch = false
            registrationSheet = .guide
        #if DEBUG
        case .openDeveloperMode:
            path.append(.developerMode)
        #endif
        }
    }

    func openGarden(_ id: UUID) {
        path.append(.gardenProfile(id))
    }

    func openRequestAssessment(_ id: UUID) {
        path.append(.requestAssessment(id))
    }

    func openResultOverview(gardenId: String) {
        path.append(.resultOverview(gardenId: gardenId))
    }

    func openNutrientCondition(gardenId: String) {
        path.append(.nutrientCondition(gardenId: gardenId))
    }

    func openFarmGreenIndex(gardenId: String) {
        path.append(.farmGreenIndex(gardenId: gardenId))
    }

    func openFertilizerEstimation(gardenId: String) {
        path.append(.fertilizerEstimation(gardenId: gardenId))
    }

    func pop() {
        _ = path.popLast()
    }

    func locatedGarden(_ location: GardenLocation) {
        guard registrationSheet != nil else { return }
        pendingLocation = location
        registrationSheet = nil
    }

    func cancelRegistration() {
        pendingLocation = nil
        registrationSheet = nil
    }

    /// The map is presented only after the registration sheet finishes closing.
    func registrationDidDismiss() {
        guard let location = pendingLocation else { return }
        pendingLocation = nil
        mappingLocation = location
    }

    /// The map calls this while its dismiss action is already in progress.
    func searchAgain() {
        reopensSearch = true
    }

    func mappingFinished(_ outcome: GardenMappingOutcome) {
        if outcome == .searchAgain { searchAgain() }
    }

    func mappingDidDismiss() {
        mappingLocation = nil
        guard reopensSearch else { return }
        reopensSearch = false
        registrationSheet = .search
    }

    func returnHome() {
        path.removeAll()
    }
}
