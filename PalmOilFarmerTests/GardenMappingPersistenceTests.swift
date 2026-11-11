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
        dependencies.coordinator.handle(.resumeDraft(DashboardMapper().map(draft)))
        let flow = dependencies.mappingFactory.makeFlow(location: draft.location, onFinish: dependencies.coordinator.mappingFinished)
        mappingPoints().forEach(flow.viewModel.addPoint)
        flow.viewModel.confirmBoundary()
        let details = flow.makeDetailsFlow()
        completeDetails(details.viewModel)
        #expect(dependencies.gardenStore.drafts.count == 2)
        #expect(details.save())
        #expect(mapping.outcome == nil && !mapping.showsDetails)
        #expect(dependencies.gardenStore.drafts.map(\.id) == [other.id])
        let garden = try #require(dependencies.gardenStore.gardens.first)
        #expect(garden.id != draft.id && garden.boundary.points == mappingPoints() && garden.review == nil)
        #expect(garden.plantingMonth == Calendar.current.component(.month, from: .now) && garden.createdAt != nil)
        #expect(dependencies.dashboardViewModel.viewState(showsFilter: true).items.count == 2)
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
        let mapping = GardenMappingFactory(saving: GardenRegistrationRepository(gardens: store), authorization: makeTestMappingAuthorization)
            .makeViewModel(location: mappingLocation(), onFinish: { _ in })
        #expect(mapping.saveDraft())
        #expect(mapping.outcome == .savedDraft && store.gardens.isEmpty)
        let reopened = makeTestGardenStore(in: container)
        let draft = try #require(reopened.drafts.first)
        #expect(draft.coordinate == mappingLocation().coordinate && draft.name == "Dumai" && draft.subtitle == "Riau")
        let root = AppCoordinator()
        root.handle(.resumeDraft(DashboardMapper().map(draft)))
        #expect(root.mappingLocation?.draftID == draft.id && root.mappingLocation?.source == .draft)
    }

    @Test func failedMappedSaveKeepsDetailsAndPassesCompletingDraftIdentityOnRetry() {
        let saving = RegistrationSavingSpy()
        saving.acceptsGarden = false
        let draft = GardenDraft(location: mappingLocation())
        var outcomes: [GardenMappingOutcome] = []
        let mapping = GardenMappingFactory(saving: saving, authorization: makeTestMappingAuthorization)
            .makeViewModel(location: draft.location, onFinish: { outcomes.append($0) })
        mappingPoints().forEach(mapping.addPoint)
        mapping.confirmBoundary()
        let details = mapping.makeDetailsViewModel()
        completeDetails(details)
        #expect(!details.save())
        #expect(mapping.showsDetails && outcomes.isEmpty && details.showsSaveError)
        #expect(saving.completedDraftIDs == [draft.id])
        saving.acceptsGarden = true
        #expect(details.save())
        #expect(saving.completedDraftIDs == [draft.id, draft.id] && outcomes.isEmpty)
        mapping.detailsDidDismiss()
        #expect(outcomes == [.savedGarden])
    }

    @Test func cancelledOrReplacedEditorCannotWriteThroughItsOldCallback() {
        let saving = RegistrationSavingSpy()
        let mapping = GardenMappingFactory(saving: saving, authorization: makeTestMappingAuthorization)
            .makeViewModel(location: mappingLocation(), onFinish: { _ in })
        mappingPoints().forEach(mapping.addPoint)
        mapping.confirmBoundary()
        let old = mapping.makeDetailsViewModel()
        completeDetails(old)
        old.close()
        #expect(!old.save() && saving.gardens.isEmpty)
        mapping.showsDetails = false
        mapping.detailsDidDismiss()
        mapping.confirmBoundary()
        let current = mapping.makeDetailsViewModel()
        completeDetails(current)
        #expect(!old.save() && saving.gardens.isEmpty)
        // Underlying geometry cannot drift while the current details editor is presented.
        mapping.clear()
        mapping.movePoint(at: 0, to: GardenCoordinate(latitude: 2, longitude: 105))
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
        let first = dependencies.mappingFactory.makeViewModel(location: mappingLocation(), onFinish: { _ in })
        _ = dependencies.mappingFactory.makeViewModel(location: mappingLocation(), onFinish: { _ in })
        #expect(authorizations.count == 2 && authorizations[0] !== authorizations[1])
        #expect(authorizations[0].requestCount == 0 && authorizations[1].requestCount == 0)
        first.requestLocationAuthorization()
        #expect(authorizations[0].requestCount == 1 && authorizations[1].requestCount == 0)
    }
}
