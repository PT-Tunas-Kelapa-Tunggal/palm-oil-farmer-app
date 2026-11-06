import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenBoundaryViewModelTests {
    @Test func pointEditsKeepOrderIgnoreDuplicateTapsAndSupportUndoClear() {
        let model = GardenBoundaryViewModel(location: mappingLocation(), saving: RegistrationSavingSpy(),
                                            authorization: MappingAuthorizationStub(), allowsLocationDrafts: true, onEvent: { _ in })
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
        var events: [GardenMappingEvent] = []
        let model = GardenBoundaryViewModel(location: mappingLocation(source: .photo), saving: RegistrationSavingSpy(),
            authorization: MappingAuthorizationStub(), allowsLocationDrafts: true, onEvent: { events.append($0) })
        mappingPoints().forEach(model.addPoint)
        model.confirmBoundary()
        #expect(model.isConfirmingPhoto && model.boundary.points.isEmpty && events.isEmpty)
        model.searchAgain()
        #expect(events == [.searchAgain])
        model.confirmPhoto()
        model.searchAgain()
        mappingPoints().forEach(model.addPoint)
        model.confirmBoundary()
        #expect(!model.isConfirmingPhoto && events == [.searchAgain, .searchAgain, .showDetails])
        #expect(!model.canSaveLocationDraft)
    }

    @Test func confirmUsesDomainBoundaryValidationIncludingInvalidDrags() {
        var events: [GardenMappingEvent] = []
        let model = GardenBoundaryViewModel(location: mappingLocation(), saving: RegistrationSavingSpy(),
            authorization: MappingAuthorizationStub(), allowsLocationDrafts: true, onEvent: { events.append($0) })
        let points = mappingPoints()
        points.prefix(2).forEach(model.addPoint)
        model.confirmBoundary()
        #expect(events.isEmpty)
        points.suffix(2).forEach(model.addPoint)
        model.movePoint(at: 1, to: points[0])
        #expect(!model.boundary.isValid)
        model.confirmBoundary()
        #expect(events.isEmpty)
        model.movePoint(at: 1, to: points[1])
        model.confirmBoundary()
        #expect(events == [.showDetails])
    }

    @Test func skipRequiresAnEmptySearchLocationAndAnAvailableSaveCapability() {
        for source in [GardenLocation.Source.photo, .draft] {
            let model = GardenBoundaryViewModel(location: mappingLocation(source: source), saving: RegistrationSavingSpy(),
                                                authorization: MappingAuthorizationStub(), allowsLocationDrafts: true, onEvent: { _ in })
            #expect(!model.canSaveLocationDraft && !model.saveDraft())
        }
        let model = GardenBoundaryViewModel(location: mappingLocation(), saving: RegistrationSavingSpy(),
                                            authorization: MappingAuthorizationStub(), allowsLocationDrafts: false, onEvent: { _ in })
        #expect(!model.canSaveLocationDraft && !model.saveDraft())
        let enabled = GardenBoundaryViewModel(location: mappingLocation(), saving: RegistrationSavingSpy(),
                                              authorization: MappingAuthorizationStub(), allowsLocationDrafts: true, onEvent: { _ in })
        #expect(enabled.canSaveLocationDraft)
        enabled.addPoint(mappingPoints()[0])
        #expect(!enabled.canSaveLocationDraft && !enabled.saveDraft())
    }

    @Test func failedDraftSaveStaysOnMapAndRetryEmitsSuccessOnlyOnce() {
        let saving = RegistrationSavingSpy()
        saving.acceptsDraft = false
        var events: [GardenMappingEvent] = []
        let location = mappingLocation()
        let model = GardenBoundaryViewModel(location: location, saving: saving,
            authorization: MappingAuthorizationStub(), allowsLocationDrafts: true, onEvent: { events.append($0) })
        #expect(!model.saveDraft() && events.isEmpty && model.canSaveLocationDraft)
        saving.acceptsDraft = true
        #expect(model.saveDraft())
        #expect(!model.saveDraft() && events == [.savedDraft])
        #expect(saving.drafts.count == 2 && saving.drafts.last?.coordinate == location.coordinate)
        #expect(saving.drafts.last?.name == location.name && saving.drafts.last?.subtitle == location.subtitle)
    }

    @Test func closeRequestsConfirmationOnlyForNonemptyBoundaryAndInactiveFlowRejectsEdits() {
        var active = true
        var events: [GardenMappingEvent] = []
        let saving = RegistrationSavingSpy()
        let model = GardenBoundaryViewModel(location: mappingLocation(), saving: saving,
            authorization: MappingAuthorizationStub(), allowsLocationDrafts: true, isActive: { active }, onEvent: { events.append($0) })
        model.close()
        model.addPoint(mappingPoints()[0])
        model.close()
        #expect(events == [.close, .confirmExit])
        active = false
        model.undo(); model.clear(); model.addPoint(mappingPoints()[1]); model.close()
        #expect(model.boundary.points == [mappingPoints()[0]] && events == [.close, .confirmExit])
        #expect(!model.saveDraft() && saving.drafts.isEmpty)
    }

    @Test func authorizationIsRequestedOnlyThroughInjectedBoundary() {
        let authorization = MappingAuthorizationStub()
        let model = GardenBoundaryViewModel(location: mappingLocation(), saving: RegistrationSavingSpy(),
                                            authorization: authorization, allowsLocationDrafts: true, onEvent: { _ in })
        #expect(authorization.requestCount == 0)
        model.requestLocationAuthorization()
        #expect(authorization.requestCount == 1)
    }
}
