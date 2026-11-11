import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct AppCoordinatorTests {
    private func location(source: GardenLocation.Source = .search) -> GardenLocation {
        GardenLocation(name: "Dumai", subtitle: "Riau",
                       coordinate: GardenCoordinate(latitude: 1, longitude: 104), source: source)
    }

    @Test func profileSelectionDoesNotDuplicateAndNativeBackAllowsAnotherSelection() {
        let coordinator = AppCoordinator()
        let first = UUID(), second = UUID()
        coordinator.handle(.openGarden(first))
        coordinator.handle(.openGarden(first))
        #expect(coordinator.path == [.gardenProfile(first)])
        // NavigationStack writes the bound path for Back and the swipe gesture.
        coordinator.path.removeLast()
        coordinator.handle(.openGarden(second))
        #expect(coordinator.path == [.gardenProfile(second)])
    }

    @Test func registrationDefersPhotoMappingUntilSheetFinishesDismissing() {
        let coordinator = AppCoordinator()
        let selected = location(source: .photo)
        coordinator.handle(.registerGarden)
        #expect(coordinator.registrationSheet == .guide)
        coordinator.locatedGarden(selected)
        #expect(coordinator.registrationSheet == nil && coordinator.mappingLocation == nil)
        coordinator.registrationDidDismiss()
        #expect(coordinator.mappingLocation?.id == selected.id)
        #expect(coordinator.mappingLocation?.source == .photo)
        #expect(coordinator.path.isEmpty)
    }

    @Test func cancelledRegistrationDoesNotOpenMappingOrAcceptLateLocation() {
        let coordinator = AppCoordinator()
        coordinator.handle(.registerGarden)
        coordinator.registrationSheet = nil
        coordinator.locatedGarden(location())
        coordinator.registrationDidDismiss()
        #expect(coordinator.mappingLocation == nil)
        coordinator.handle(.registerGarden)
        #expect(coordinator.registrationSheet == .guide)
    }

    @Test func photoSearchAgainWaitsForCoverDismissalAndOpensSearchDirectly() {
        let coordinator = AppCoordinator()
        coordinator.handle(.registerGarden)
        coordinator.locatedGarden(location(source: .photo))
        coordinator.registrationDidDismiss()
        // The map's dismiss action can clear its binding before onSearchAgain runs.
        coordinator.mappingLocation = nil
        coordinator.searchAgain()
        #expect(coordinator.registrationSheet == nil)
        coordinator.mappingDidDismiss()
        #expect(coordinator.mappingLocation == nil && coordinator.registrationSheet == .search)
        let replacement = location()
        coordinator.locatedGarden(replacement)
        coordinator.registrationDidDismiss()
        #expect(coordinator.mappingLocation?.id == replacement.id)
        coordinator.mappingDidDismiss()
        #expect(coordinator.registrationSheet == nil)
    }

    @Test func resumingDraftPreservesIdentityAndSkipsRegistrationSheet() {
        let coordinator = AppCoordinator()
        let draft = GardenDraft(location: location())
        coordinator.handle(.resumeDraft(DashboardMapper().map(draft)))
        #expect(coordinator.registrationSheet == nil)
        #expect(coordinator.mappingLocation?.draftID == draft.id)
        #expect(coordinator.mappingLocation?.source == .draft)
        #expect(coordinator.mappingLocation?.coordinate == draft.coordinate)
    }

    @Test func closingMappingWithoutSearchAgainReturnsHomeAndNextRegistrationStartsAtGuide() {
        let coordinator = AppCoordinator()
        coordinator.handle(.resumeDraft(DashboardMapper().map(GardenDraft(location: location()))))
        coordinator.mappingDidDismiss()
        #expect(coordinator.mappingLocation == nil && coordinator.registrationSheet == nil)
        coordinator.handle(.registerGarden)
        #expect(coordinator.registrationSheet == .guide)
    }

    @Test func repeatedEventsCannotInterruptPendingModalTransition() {
        let coordinator = AppCoordinator()
        let selected = location()
        coordinator.handle(.registerGarden)
        coordinator.locatedGarden(selected)
        coordinator.handle(.registerGarden)
        coordinator.handle(.openGarden(UUID()))
        coordinator.handle(.resumeDraft(DashboardMapper().map(GardenDraft(location: location()))))
        #expect(coordinator.registrationSheet == nil && coordinator.path.isEmpty)
        coordinator.registrationDidDismiss()
        coordinator.registrationDidDismiss()
        #expect(coordinator.mappingLocation?.id == selected.id)
        coordinator.handle(.registerGarden)
        #expect(coordinator.registrationSheet == nil)
    }

    @Test func developerRouteCanReturnHomeAfterErasingData() {
        let coordinator = AppCoordinator()
        coordinator.handle(.openDeveloperMode)
        #expect(coordinator.path == [.developerMode])
        coordinator.returnHome()
        #expect(coordinator.path.isEmpty)
        coordinator.handle(.registerGarden)
        #expect(coordinator.registrationSheet == .guide)
    }
}
