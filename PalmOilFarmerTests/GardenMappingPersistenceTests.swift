import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenMappingPersistenceTests {
    @Test func resumedDraftIsReplacedOnlyAfterSuccessfulGardenSaveAndListUpdates() throws {
        let container = AppConfiguration.makeModelContainer(inMemory: true)
        let dependencies = AppDependencies(modelContainer: container, reviewRepository: ReviewRepositoryStub(),
            registrationServices: makeTestRegistrationServices, mappingAuthorization: makeTestMappingAuthorization)
        let draft = GardenDraft(location: mappingLocation())
        let other = GardenDraft(location: mappingLocation())
        #expect(dependencies.gardenStore.addDraft(draft) && dependencies.gardenStore.addDraft(other))
        dependencies.coordinator.handle(.resumeDraft(draft))
        let flow = dependencies.mappingFactory.makeFlow(location: draft.location, onFinish: dependencies.coordinator.mappingFinished)
        mappingPoints().forEach(flow.viewModel.addPoint)
        flow.viewModel.confirmBoundary()
        let details = flow.makeDetailsFlow()
        completeDetails(details)
        #expect(dependencies.gardenStore.drafts.count == 2)
        #expect(details.save())
        #expect(flow.coordinator.outcome == nil && !flow.coordinator.showsDetails)
        #expect(dependencies.gardenStore.drafts.map(\.id) == [other.id])
        let garden = try #require(dependencies.gardenStore.gardens.first)
        #expect(garden.id != draft.id && garden.boundary.points == mappingPoints() && garden.review == nil)
        #expect(garden.plantingMonth == Calendar.current.component(.month, from: .now) && garden.createdAt != nil)
        #expect(dependencies.gardenListViewModel.presentation(showsFilter: true).items.count == 2)
        flow.coordinator.detailsDidDismiss()
        #expect(flow.coordinator.outcome == .savedGarden && dependencies.coordinator.mappingLocation != nil)
        dependencies.coordinator.mappingDidDismiss()
        #expect(dependencies.coordinator.mappingLocation == nil && dependencies.coordinator.registrationSheet == nil)
        let reopened = makeTestGardenStore(in: container)
        #expect(reopened.gardens.map(\.id) == [garden.id] && reopened.drafts.map(\.id) == [other.id])
    }

    @Test func locationDraftPersistsAndResumesWithOriginalCoordinateAndDraftID() throws {
        let container = AppConfiguration.makeModelContainer(inMemory: true)
        let store = makeTestGardenStore(in: container)
        let flow = GardenMappingFactory(saving: GardenRegistrationRepository(gardens: store), authorization: makeTestMappingAuthorization)
            .makeFlow(location: mappingLocation(), onFinish: { _ in })
        #expect(flow.viewModel.saveDraft())
        #expect(flow.coordinator.outcome == .savedDraft && store.gardens.isEmpty)
        let reopened = makeTestGardenStore(in: container)
        let draft = try #require(reopened.drafts.first)
        #expect(draft.coordinate == mappingLocation().coordinate && draft.name == "Dumai" && draft.subtitle == "Riau")
        let root = AppCoordinator()
        root.handle(.resumeDraft(draft))
        #expect(root.mappingLocation?.draftID == draft.id && root.mappingLocation?.source == .draft)
    }

    @Test func failedMappedSaveKeepsDetailsAndPassesCompletingDraftIdentityOnRetry() {
        let saving = RegistrationSavingSpy()
        saving.acceptsGarden = false
        let draft = GardenDraft(location: mappingLocation())
        var outcomes: [GardenMappingOutcome] = []
        let flow = GardenMappingFactory(saving: saving, authorization: makeTestMappingAuthorization)
            .makeFlow(location: draft.location, onFinish: { outcomes.append($0) })
        mappingPoints().forEach(flow.viewModel.addPoint)
        flow.viewModel.confirmBoundary()
        let details = flow.makeDetailsFlow()
        completeDetails(details)
        #expect(!details.save())
        #expect(flow.coordinator.showsDetails && outcomes.isEmpty && details.showsSaveError)
        #expect(saving.completedDraftIDs == [draft.id])
        saving.acceptsGarden = true
        #expect(details.save())
        #expect(saving.completedDraftIDs == [draft.id, draft.id] && outcomes.isEmpty)
        flow.coordinator.detailsDidDismiss()
        #expect(outcomes == [.savedGarden])
    }

    @Test func cancelledOrReplacedEditorCannotWriteThroughItsOldCallback() {
        let saving = RegistrationSavingSpy()
        let flow = GardenMappingFactory(saving: saving, authorization: makeTestMappingAuthorization)
            .makeFlow(location: mappingLocation(), onFinish: { _ in })
        mappingPoints().forEach(flow.viewModel.addPoint)
        flow.viewModel.confirmBoundary()
        let old = flow.makeDetailsFlow()
        completeDetails(old)
        old.close()
        #expect(!old.save() && saving.gardens.isEmpty)
        flow.coordinator.showsDetails = false
        flow.coordinator.detailsDidDismiss()
        flow.viewModel.confirmBoundary()
        let current = flow.makeDetailsFlow()
        completeDetails(current)
        #expect(!old.save() && saving.gardens.isEmpty)
        // Underlying geometry cannot drift while the current details editor is presented.
        flow.viewModel.clear()
        flow.viewModel.movePoint(at: 0, to: GardenCoordinate(latitude: 2, longitude: 105))
        #expect(current.save())
        #expect(saving.gardens.count == 1 && saving.gardens.first?.boundary.points == mappingPoints())
    }

    @Test func permissionServiceIsLazyPerMappingFlowAndUsesExplicitDependency() {
        var authorizations: [MappingAuthorizationStub] = []
        let dependencies = AppDependencies(modelContainer: AppConfiguration.makeModelContainer(inMemory: true),
            reviewRepository: ReviewRepositoryStub(), registrationServices: makeTestRegistrationServices,
            mappingAuthorization: {
                let authorization = MappingAuthorizationStub()
                authorizations.append(authorization)
                return authorization
            })
        #expect(authorizations.isEmpty)
        let first = dependencies.mappingFactory.makeFlow(location: mappingLocation(), onFinish: { _ in })
        _ = dependencies.mappingFactory.makeFlow(location: mappingLocation(), onFinish: { _ in })
        #expect(authorizations.count == 2 && authorizations[0] !== authorizations[1])
        #expect(authorizations[0].requestCount == 0 && authorizations[1].requestCount == 0)
        first.viewModel.requestLocationAuthorization()
        #expect(authorizations[0].requestCount == 1 && authorizations[1].requestCount == 0)
    }
}
