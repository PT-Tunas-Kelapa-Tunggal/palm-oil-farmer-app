import Foundation
import Testing
@testable import PalmOilFarmer

/// Presentation state of the boundary map: the "Data Kebun" sheet, the exit dialog and how the map finishes.
@MainActor
struct GardenBoundaryPresentationTests {
    private func drawnModel(onFinish: @escaping (GardenMappingOutcome) -> Void = { _ in }) -> GardenBoundaryViewModel {
        let model = GardenBoundaryViewModel(location: mappingLocation(), saving: RegistrationSavingSpy(),
                                            authorization: MappingAuthorizationStub(), allowsLocationDrafts: true,
                                            onFinish: onFinish)
        mappingPoints().forEach(model.addPoint)
        return model
    }

    @Test func detailsSessionBlocksOtherPresentationsAndCancellationCreatesFreshSession() throws {
        let model = drawnModel()
        model.confirmBoundary()
        let first = try #require(model.detailsSessionID)
        model.confirmBoundary()
        model.close()
        #expect(model.showsDetails && !model.showsExitConfirmation && model.outcome == nil)
        #expect(model.detailsSessionID == first)
        model.showsDetails = false
        // A cleared SwiftUI binding does not mean the dismissal animation has finished.
        model.confirmBoundary()
        #expect(!model.showsDetails && model.detailsSessionID == first && !model.canEditBoundary)
        model.detailsDidDismiss()
        #expect(model.canEditBoundary && model.outcome == nil && model.detailsSessionID == nil)
        model.confirmBoundary()
        #expect(model.detailsSessionID != first)
        model.detailsSaved(sessionID: first)
        #expect(model.showsDetails && model.outcome == nil)
    }

    @Test func successfulDetailsWaitForSheetDismissalBeforeFinishingMap() throws {
        var outcomes: [GardenMappingOutcome] = []
        let model = drawnModel(onFinish: { outcomes.append($0) })
        model.confirmBoundary()
        let session = try #require(model.detailsSessionID)
        model.detailsSaved(sessionID: session)
        model.detailsSaved(sessionID: session)
        model.close()
        #expect(!model.showsDetails && !model.canEditBoundary && outcomes.isEmpty && model.outcome == nil)
        model.detailsDidDismiss()
        model.detailsDidDismiss()
        #expect(outcomes == [.savedGarden] && model.outcome == .savedGarden)
        #expect(!model.saveDraft() && outcomes.count == 1)
    }

    @Test func destructiveDialogActionStillClosesAfterSwiftUIClearsItsBinding() {
        var outcomes: [GardenMappingOutcome] = []
        let model = drawnModel(onFinish: { outcomes.append($0) })
        model.close()
        #expect(model.showsExitConfirmation)
        model.showsExitConfirmation = false
        model.discardAndClose()
        model.discardAndClose()
        #expect(model.outcome == .closed && outcomes == [.closed])
    }

    @Test func continuingMappingKeepsPointsAndDialogBlocksEdits() {
        let model = GardenMappingFactory(saving: RegistrationSavingSpy(), authorization: { MappingAuthorizationStub() })
            .makeViewModel(location: mappingLocation(), onFinish: { _ in })
        mappingPoints().forEach(model.addPoint)
        model.close()
        #expect(model.showsExitConfirmation)
        model.clear()
        #expect(model.boundary.points == mappingPoints())
        model.continueMapping()
        #expect(model.outcome == nil && model.canEditBoundary)
        model.undo()
        #expect(model.boundary.points.count == 3)
    }

    @Test func plantingDateCanReopenUntilDetailsAreClosed() {
        let model = GardenDetailsViewModel(locationName: "Kebun", boundary: GardenBoundary(points: []),
                                           onSave: { _ in true }, onSaved: {})
        model.openPlantingDate()
        model.openPlantingDate()
        #expect(model.showsPlantingDate)
        model.showsPlantingDate = false
        model.openPlantingDate()
        #expect(model.showsPlantingDate)
        model.showsPlantingDate = false
        model.close()
        model.openPlantingDate()
        #expect(model.isFinished && !model.showsPlantingDate && !model.save())
    }

    @Test func photoSearchAgainReopensSearchOnlyAfterMapFinishesDismissing() {
        let root = AppCoordinator()
        root.handle(.registerGarden)
        root.locatedGarden(mappingLocation(source: .photo))
        root.registrationDidDismiss()
        let model = GardenMappingFactory(saving: RegistrationSavingSpy(), authorization: { MappingAuthorizationStub() })
            .makeViewModel(location: mappingLocation(source: .photo), onFinish: root.mappingFinished)
        model.searchAgain()
        #expect(model.outcome == .searchAgain && root.registrationSheet == nil && root.mappingLocation != nil)
        root.mappingLocation = nil
        root.mappingDidDismiss()
        #expect(root.registrationSheet == .search)
    }
}
