import Foundation
import Observation

enum AppRoute: Hashable {
    case gardenProfile(UUID)
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

    func handle(_ event: GardenListEvent) {
        guard path.isEmpty, registrationSheet == nil, mappingLocation == nil, pendingLocation == nil else { return }
        switch event {
        case .openGarden(let id):
            path.append(.gardenProfile(id))
        case .resumeDraft(let draft):
            reopensSearch = false
            mappingLocation = draft.location
        case .registerGarden:
            reopensSearch = false
            registrationSheet = .guide
        #if DEBUG
        case .openDeveloperMode:
            path.append(.developerMode)
        #endif
        }
    }

    func locatedGarden(_ location: GardenLocation) {
        guard registrationSheet != nil else { return }
        pendingLocation = location
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
