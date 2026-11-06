import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenMappingCoordinatorTests {
    @Test func detailsSessionBlocksOtherPresentationsAndCancellationCreatesFreshSession() throws {
        let coordinator = GardenMappingCoordinator(onFinish: { _ in })
        coordinator.handle(.showDetails)
        let first = try #require(coordinator.detailsSessionID)
        coordinator.handle(.showDetails)
        coordinator.handle(.confirmExit)
        coordinator.handle(.searchAgain)
        #expect(coordinator.showsDetails && !coordinator.showsExitConfirmation && coordinator.outcome == nil)
        #expect(coordinator.detailsSessionID == first)
        coordinator.showsDetails = false
        // A cleared SwiftUI binding does not mean the dismissal animation has finished.
        coordinator.handle(.showDetails)
        #expect(!coordinator.showsDetails && coordinator.detailsSessionID == first && !coordinator.canEditBoundary)
        coordinator.detailsDidDismiss()
        #expect(coordinator.canEditBoundary && coordinator.outcome == nil && coordinator.detailsSessionID == nil)
        coordinator.handle(.showDetails)
        #expect(coordinator.detailsSessionID != first)
        coordinator.detailsSaved(sessionID: first)
        #expect(coordinator.showsDetails && coordinator.outcome == nil)
    }

    @Test func successfulDetailsWaitForSheetDismissalBeforeFinishingMap() throws {
        var outcomes: [GardenMappingOutcome] = []
        let coordinator = GardenMappingCoordinator(onFinish: { outcomes.append($0) })
        coordinator.handle(.showDetails)
        let session = try #require(coordinator.detailsSessionID)
        coordinator.detailsSaved(sessionID: session)
        coordinator.detailsSaved(sessionID: session)
        coordinator.handle(.close)
        #expect(!coordinator.showsDetails && !coordinator.canEditBoundary && outcomes.isEmpty && coordinator.outcome == nil)
        coordinator.detailsDidDismiss()
        coordinator.detailsDidDismiss()
        #expect(outcomes == [.savedGarden] && coordinator.outcome == .savedGarden)
        coordinator.handle(.savedDraft)
        #expect(outcomes.count == 1)
    }

    @Test func destructiveDialogActionStillClosesAfterSwiftUIClearsItsBinding() {
        var outcomes: [GardenMappingOutcome] = []
        let coordinator = GardenMappingCoordinator(onFinish: { outcomes.append($0) })
        coordinator.handle(.confirmExit)
        coordinator.showsExitConfirmation = false
        coordinator.discardAndClose()
        coordinator.discardAndClose()
        #expect(coordinator.outcome == .closed && outcomes == [.closed])
    }

    @Test func continuingMappingKeepsPointsAndDialogBlocksEdits() {
        let flow = GardenMappingFactory(saving: RegistrationSavingSpy(), authorization: { MappingAuthorizationStub() })
            .makeFlow(location: mappingLocation(), onFinish: { _ in })
        mappingPoints().forEach(flow.viewModel.addPoint)
        flow.viewModel.close()
        #expect(flow.coordinator.showsExitConfirmation)
        flow.viewModel.clear()
        #expect(flow.viewModel.boundary.points == mappingPoints())
        flow.coordinator.continueMapping()
        #expect(flow.coordinator.outcome == nil && flow.coordinator.canEditBoundary)
        flow.viewModel.undo()
        #expect(flow.viewModel.boundary.points.count == 3)
    }

    @Test func plantingDateCanReopenUntilDetailsAreClosed() {
        let coordinator = GardenDetailsCoordinator()
        coordinator.openPlantingDate()
        coordinator.openPlantingDate()
        #expect(coordinator.showsPlantingDate)
        coordinator.showsPlantingDate = false
        coordinator.openPlantingDate()
        #expect(coordinator.showsPlantingDate)
        coordinator.showsPlantingDate = false
        coordinator.close()
        coordinator.openPlantingDate()
        #expect(coordinator.isFinished && !coordinator.showsPlantingDate)
    }

    @Test func photoSearchAgainReopensSearchOnlyAfterMapFinishesDismissing() {
        let root = AppCoordinator()
        root.handle(.registerGarden)
        root.locatedGarden(mappingLocation(source: .photo))
        root.registrationDidDismiss()
        let flow = GardenMappingFactory(saving: RegistrationSavingSpy(), authorization: { MappingAuthorizationStub() })
            .makeFlow(location: mappingLocation(source: .photo), onFinish: root.mappingFinished)
        flow.viewModel.searchAgain()
        #expect(flow.coordinator.outcome == .searchAgain && root.registrationSheet == nil && root.mappingLocation != nil)
        root.mappingLocation = nil
        root.mappingDidDismiss()
        #expect(root.registrationSheet == .search)
    }
}
