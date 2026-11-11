import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenBoundaryViewModelTests {
    private func makeModel(source: GardenLocation.Source = .search, saving: RegistrationSavingSpy = RegistrationSavingSpy(),
                           authorization: MappingAuthorizationStub = MappingAuthorizationStub(),
                           allowsLocationDrafts: Bool = true,
                           onFinish: @escaping (GardenMappingOutcome) -> Void = { _ in }) -> GardenBoundaryViewModel {
        GardenBoundaryViewModel(location: mappingLocation(source: source), saving: saving, authorization: authorization,
                                allowsLocationDrafts: allowsLocationDrafts, onFinish: onFinish)
    }

    @Test func pointEditsKeepOrderIgnoreDuplicateTapsAndSupportUndoClear() {
        let model = makeModel()
        let points = mappingPoints()
        points.forEach(model.addPoint)
        model.addPoint(points[0])
        #expect(model.boundary.points == points && model.boundary.isValid)
        model.movePoint(at: -1, to: points[1])
        model.movePoint(at: 9, to: points[1])
        #expect(model.boundary.points == points)
        model.movePoint(at: 1, to: GardenCoordinate(latitude: 1, longitude: 104.003))
        #expect(model.boundary.points[1].longitude == 104.003 && model.boundary.points[0] == points[0])
        model.undo()
        #expect(model.boundary.points.count == 3)
        model.clear()
        model.undo()
        #expect(model.boundary.points.isEmpty)
    }

    @Test func photoConfirmationBlocksMappingAndEmptyMapCanReturnToSearch() {
        let model = makeModel(source: .photo)
        mappingPoints().forEach(model.addPoint)
        model.confirmBoundary()
        #expect(model.isConfirmingPhoto && model.boundary.points.isEmpty && !model.showsDetails)
        model.confirmPhoto()
        mappingPoints().forEach(model.addPoint)
        model.confirmBoundary()
        #expect(!model.isConfirmingPhoto && model.showsDetails && model.outcome == nil)
        #expect(!model.canSaveLocationDraft)

        var outcomes: [GardenMappingOutcome] = []
        let unconfirmed = makeModel(source: .photo, onFinish: { outcomes.append($0) })
        unconfirmed.searchAgain()
        unconfirmed.searchAgain()
        #expect(outcomes == [.searchAgain] && unconfirmed.outcome == .searchAgain)
    }

    @Test func confirmUsesDomainBoundaryValidationIncludingInvalidDrags() {
        let model = makeModel()
        let points = mappingPoints()
        points.prefix(2).forEach(model.addPoint)
        model.confirmBoundary()
        #expect(!model.showsDetails)
        points.suffix(2).forEach(model.addPoint)
        model.movePoint(at: 1, to: points[0])
        #expect(!model.boundary.isValid)
        model.confirmBoundary()
        #expect(!model.showsDetails)
        model.movePoint(at: 1, to: points[1])
        model.confirmBoundary()
        #expect(model.showsDetails && model.detailsSessionID != nil)
    }

    @Test func closedPreviewStillAcceptsMoreCornersAndEveryPointRemainsMovable() {
        let model = makeModel(allowsLocationDrafts: false)
        let points = mappingPoints()
        points.forEach(model.addPoint)
        let fifth = GardenCoordinate(latitude: 1.001, longitude: 103.999)
        model.addPoint(fifth)
        #expect(model.boundary.points == points + [fifth])
        #expect(model.canConfirmBoundary)
        for index in model.boundary.points.indices {
            let original = model.boundary.points[index]
            model.movePoint(at: index, to: GardenCoordinate(latitude: original.latitude + 0.0001, longitude: original.longitude))
            #expect(model.boundary.points.count == 5)
            #expect(model.boundary.points[index].latitude == original.latitude + 0.0001)
            model.movePoint(at: index, to: original)
        }
        #expect(model.canConfirmBoundary)
        model.undo()
        #expect(model.boundary.points == points && model.canConfirmBoundary)
        model.undo()
        #expect(model.boundary.points.count == 3 && !model.canConfirmBoundary)
    }

    @Test func skipRequiresAnEmptySearchLocationAndAnAvailableSaveCapability() {
        for source in [GardenLocation.Source.photo, .draft] {
            let model = makeModel(source: source)
            #expect(!model.canSaveLocationDraft && !model.saveDraft())
        }
        let model = makeModel(allowsLocationDrafts: false)
        #expect(!model.canSaveLocationDraft && !model.saveDraft())
        let enabled = makeModel()
        #expect(enabled.canSaveLocationDraft)
        enabled.addPoint(mappingPoints()[0])
        #expect(!enabled.canSaveLocationDraft && !enabled.saveDraft())
    }

    @Test func failedDraftSaveStaysOnMapAndRetryFinishesOnlyOnce() {
        let saving = RegistrationSavingSpy()
        saving.acceptsDraft = false
        var outcomes: [GardenMappingOutcome] = []
        let location = mappingLocation()
        let model = makeModel(saving: saving, onFinish: { outcomes.append($0) })
        #expect(!model.saveDraft() && outcomes.isEmpty && model.canSaveLocationDraft)
        saving.acceptsDraft = true
        #expect(model.saveDraft())
        #expect(!model.saveDraft() && outcomes == [.savedDraft])
        #expect(saving.drafts.count == 2 && saving.drafts.last?.coordinate == location.coordinate)
        #expect(saving.drafts.last?.name == location.name && saving.drafts.last?.subtitle == location.subtitle)
    }

    @Test func closeAsksOnlyForNonemptyBoundaryAndFinishedOrDialogStateRejectsEdits() {
        var outcomes: [GardenMappingOutcome] = []
        let saving = RegistrationSavingSpy()
        let empty = makeModel(saving: saving, onFinish: { outcomes.append($0) })
        empty.close()
        #expect(outcomes == [.closed])
        empty.addPoint(mappingPoints()[0])
        #expect(empty.boundary.points.isEmpty && !empty.saveDraft())

        let model = makeModel(saving: saving, onFinish: { outcomes.append($0) })
        model.addPoint(mappingPoints()[0])
        model.close()
        #expect(model.showsExitConfirmation && outcomes == [.closed])
        model.undo(); model.clear(); model.addPoint(mappingPoints()[1]); model.close()
        #expect(model.boundary.points == [mappingPoints()[0]] && outcomes == [.closed])
        #expect(!model.saveDraft() && saving.drafts.isEmpty)
    }

    @Test func authorizationIsRequestedOnlyThroughInjectedBoundary() {
        let authorization = MappingAuthorizationStub()
        let model = makeModel(authorization: authorization)
        #expect(authorization.requestCount == 0)
        model.requestLocationAuthorization()
        #expect(authorization.requestCount == 1)
    }
}
