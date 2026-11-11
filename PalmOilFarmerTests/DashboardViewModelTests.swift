import Foundation
import Observation
import Testing
@testable import PalmOilFarmer

@MainActor
struct DashboardViewModelTests {
    private let mapper = DashboardMapper()

    private func garden(
        name: String = "Kebun", createdAt: Date? = nil,
        complete: Bool = false, status: ReviewStatus? = nil, downloaded: Bool = false
    ) -> Garden {
        var value = Garden(id: UUID(), name: name, locationName: "Dumai", boundary: GardenBoundary(),
                           plantingYear: 2016, soilType: .peat, createdAt: createdAt)
        if complete {
            value.fertilizerRecords = [FertilizerRecord(name: "Urea", bagWeightKg: 50, bagCount: 1, doseKgPerTree: 1)]
            value.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 500)
        }
        if let status {
            value.review = GardenReview(
                status: status, contact: ReviewContactDetails(name: "Budi", phone: "08123456789", address: "Uji"),
                stageDates: [Date(timeIntervalSince1970: 1_000)], resultsDownloaded: downloaded
            )
        }
        return value
    }

    private func draft(createdAt: Date = Date(timeIntervalSince1970: 2_000)) -> GardenDraft {
        GardenDraft(name: "Lokasi", subtitle: "Riau", coordinate: GardenCoordinate(latitude: 1, longitude: 104),
                    createdAt: createdAt)
    }

    @Test func filtersAndBadgesPreserveExistingStageRules() {
        let submitted = garden(status: .submitted), scheduled = garden(status: .scheduled)
        let values = [garden(), garden(complete: true), submitted, scheduled,
                      garden(status: .completed), garden(status: .completed, downloaded: true)]
        let location = draft()
        let repository = DashboardRepositorySpy(gardens: values, drafts: [location])
        let model = DashboardViewModel(repository: repository, onEvent: { _ in })
        let all = model.viewState(showsFilter: true)
        #expect(all.items.count == 7 && !all.isEmpty)
        #expect(all.actionCount(for: .all) == 5)
        #expect(all.actionCount(for: .draft) == 1)
        #expect(all.actionCount(for: .inReview) == 1)
        model.selectedFilter = .inReview
        let review = model.viewState(showsFilter: true)
        #expect(Set(review.items.map(\.id)) == Set([submitted.id, scheduled.id]))
        // Badge values count all data for their own tab, even while another tab is selected.
        #expect(review.actionCount(for: .all) == 5)
        model.selectedFilter = .draft
        #expect(model.viewState(showsFilter: true).items.map(\.id) == [location.id])
    }

    @Test func hidingFilterShowsAllWithoutLosingSelectedTab() {
        let local = garden(), location = draft()
        let model = DashboardViewModel(repository: DashboardRepositorySpy(gardens: [local], drafts: [location]), onEvent: { _ in })
        model.selectedFilter = .inReview
        #expect(model.viewState(showsFilter: true).hasNoVisibleItems)
        let hidden = model.viewState(showsFilter: false)
        #expect(hidden.filter == .all && hidden.items.count == 2)
        #expect(model.selectedFilter == .inReview)
        #expect(model.viewState(showsFilter: true).filter == .inReview)
        #expect(model.viewState(showsFilter: true).hasNoVisibleItems)
    }

    @Test func emptyFilteredListIsDistinctFromAnEmptyHome() {
        let repository = DashboardRepositorySpy()
        let model = DashboardViewModel(repository: repository, onEvent: { _ in })
        #expect(model.viewState(showsFilter: true).isEmpty)
        repository.appGardens = [garden()]
        model.selectedFilter = .draft
        let presentation = model.viewState(showsFilter: true)
        #expect(!presentation.isEmpty && presentation.hasNoVisibleItems)
    }

    @Test func presentationKeepsMixedDateOrderingAndLegacyGardenOrder() {
        let old = garden(name: "Lama-1"), newerLegacy = garden(name: "Lama-2")
        let dated = garden(createdAt: Date(timeIntervalSince1970: 1_000))
        let newest = garden(createdAt: Date(timeIntervalSince1970: 3_000))
        let location = draft()
        let model = DashboardViewModel(
            repository: DashboardRepositorySpy(gardens: [old, newerLegacy, dated, newest], drafts: [location]), onEvent: { _ in }
        )
        #expect(model.viewState(showsFilter: true).items.map(\.id) == [newest.id, location.id, dated.id, newerLegacy.id, old.id])
    }

    @Test func userActionsEmitValuesWithoutAConcreteCoordinatorDependency() {
        var events: [DashboardEvent] = []
        let repository = DashboardRepositorySpy()
        let model = DashboardViewModel(repository: repository, onEvent: { events.append($0) })
        let local = garden(), location = draft()
        model.selectGarden(mapper.map(local))
        model.selectDraft(mapper.map(location))
        model.registerGarden()
        model.openDeveloperMode()
        #expect(events.count == 4)
        if case .openGarden(let id) = events[0] { #expect(id == local.id) } else { Issue.record("Expected profile event") }
        if case .resumeDraft(let value) = events[1] { #expect(value.id == location.id) } else { Issue.record("Expected draft event") }
        if case .registerGarden = events[2] {} else { Issue.record("Expected registration event") }
        if case .openDeveloperMode = events[3] {} else { Issue.record("Expected developer event") }
        #expect(repository.refreshCount == 0 && repository.deletedIDs.isEmpty)
    }

    @Test func refreshAndDeleteUseInjectedSourceWithoutOptimisticRemovalOnFailure() async {
        let location = draft()
        let repository = DashboardRepositorySpy(drafts: [location])
        let remote = garden(status: .submitted)
        repository.refreshedGardens = [remote]
        let model = DashboardViewModel(repository: repository, onEvent: { _ in })
        await model.refresh()
        #expect(repository.refreshCount == 1)
        #expect(Set(model.viewState(showsFilter: true).items.map(\.id)) == Set([location.id, remote.id]))
        repository.rejectsDeletion = true
        #expect(!model.deleteDraft(mapper.map(location)))
        #expect(model.viewState(showsFilter: true).items.contains { $0.id == location.id })
        repository.rejectsDeletion = false
        #expect(model.deleteDraft(mapper.map(location)))
        #expect(model.viewState(showsFilter: true).items.map(\.id) == [remote.id])
        #expect(repository.deletedIDs == [location.id, location.id])
    }

    @Test func sharedStoreMutationInvalidatesObservationAndProfileEditsStayVisible() async throws {
        let store = makeTestGardenStore(in: AppConfiguration.makeModelContainer(inMemory: true))
        let model = DashboardViewModel(repository: DashboardRepository(store: store), onEvent: { _ in })
        var local = garden()
        await confirmation("Changes in the shared store invalidate list presentation") { changed in
            withObservationTracking {
                _ = model.viewState(showsFilter: true).items
            } onChange: {
                changed()
            }
            #expect(store.add(local))
        }
        #expect(model.viewState(showsFilter: true).items.map(\.id) == [local.id])
        local.fertilizerRecords = [FertilizerRecord(name: "Urea", bagWeightKg: 50, bagCount: 1, doseKgPerTree: 1)]
        local.harvestRecord = HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 750)
        #expect(store.update(local))
        let item = try #require(model.viewState(showsFilter: true).items.first)
        if case .garden(let updated) = item {
            #expect(updated.stage == .readyForReview)
        } else { Issue.record("Expected the updated garden") }
    }

    @Test func composedViewModelUsesSameStoreAndRoutesThroughCoordinator() async {
        let remote = garden(status: .submitted)
        let contact = ReviewContactDetails(name: "Budi", phone: "08123456789", address: "Uji")
        let dependencies = AppDependencies(
            modelContainer: AppConfiguration.makeModelContainer(inMemory: true),
            reviewRepository: ReviewRepositoryStub(requests: [PlantationReviewRequest(garden: remote, contact: contact)]),
            registrationServices: makeTestRegistrationServices,
            mappingAuthorization: makeTestMappingAuthorization
        )
        let location = draft()
        #expect(dependencies.gardenStore.addDraft(location))
        await dependencies.dashboardViewModel.refresh()
        #expect(dependencies.dashboardViewModel.viewState(showsFilter: true).items.count == 2)
        dependencies.dashboardViewModel.selectGarden(mapper.map(remote))
        #expect(dependencies.coordinator.path == [.gardenProfile(remote.id)])
        dependencies.coordinator.path = []
        dependencies.dashboardViewModel.selectDraft(mapper.map(location))
        #expect(dependencies.coordinator.mappingLocation?.draftID == location.id)
        #expect(dependencies.dashboardViewModel.deleteDraft(mapper.map(location)))
        #expect(dependencies.gardenStore.drafts.isEmpty)
        dependencies.coordinator.mappingDidDismiss()
        dependencies.dashboardViewModel.registerGarden()
        #expect(dependencies.coordinator.registrationSheet == .guide)
    }
}

@MainActor
@Observable
private final class DashboardRepositorySpy: DashboardRepositoryProtocol {
    var appGardens: [Garden]
    var appDrafts: [GardenDraft]
    var refreshedGardens: [Garden] = []
    var refreshCount = 0
    var deletedIDs: [UUID] = []
    var rejectsDeletion = false
    private let mapper = DashboardMapper()

    init(gardens: [Garden] = [], drafts: [GardenDraft] = []) {
        appGardens = gardens
        appDrafts = drafts
    }

    var gardens: [DashboardGarden] { appGardens.map { mapper.map($0) } }
    var drafts: [DashboardDraft] { appDrafts.map { mapper.map($0) } }

    func refresh() async {
        refreshCount += 1
        appGardens = refreshedGardens
    }

    func deleteDraft(id: UUID) -> Bool {
        deletedIDs.append(id)
        guard !rejectsDeletion else { return false }
        appDrafts.removeAll { $0.id == id }
        return true
    }
}
