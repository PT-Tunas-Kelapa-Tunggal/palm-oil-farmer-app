import Foundation
import Observation
import Testing
@testable import PalmOilFarmer

@MainActor
struct GardenListViewModelTests {
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
        let source = ListDataSourceSpy(gardens: values, drafts: [location])
        let model = GardenListViewModel(source: source, onEvent: { _ in })
        let all = model.presentation(showsFilter: true)
        #expect(all.items.count == 7 && !all.isEmpty)
        #expect(all.actionCount(for: .all) == 5)
        #expect(all.actionCount(for: .draft) == 1)
        #expect(all.actionCount(for: .inReview) == 1)
        model.selectedFilter = .inReview
        let review = model.presentation(showsFilter: true)
        #expect(Set(review.items.map(\.id)) == Set([submitted.id, scheduled.id]))
        // Badge values count all data for their own tab, even while another tab is selected.
        #expect(review.actionCount(for: .all) == 5)
        model.selectedFilter = .draft
        #expect(model.presentation(showsFilter: true).items.map(\.id) == [location.id])
    }

    @Test func hidingFilterShowsAllWithoutLosingSelectedTab() {
        let local = garden(), location = draft()
        let model = GardenListViewModel(source: ListDataSourceSpy(gardens: [local], drafts: [location]), onEvent: { _ in })
        model.selectedFilter = .inReview
        #expect(model.presentation(showsFilter: true).hasNoVisibleItems)
        let hidden = model.presentation(showsFilter: false)
        #expect(hidden.filter == .all && hidden.items.count == 2)
        #expect(model.selectedFilter == .inReview)
        #expect(model.presentation(showsFilter: true).filter == .inReview)
        #expect(model.presentation(showsFilter: true).hasNoVisibleItems)
    }

    @Test func emptyFilteredListIsDistinctFromAnEmptyHome() {
        let source = ListDataSourceSpy()
        let model = GardenListViewModel(source: source, onEvent: { _ in })
        #expect(model.presentation(showsFilter: true).isEmpty)
        source.gardens = [garden()]
        model.selectedFilter = .draft
        let presentation = model.presentation(showsFilter: true)
        #expect(!presentation.isEmpty && presentation.hasNoVisibleItems)
    }

    @Test func presentationKeepsMixedDateOrderingAndLegacyGardenOrder() {
        let old = garden(name: "Lama-1"), newerLegacy = garden(name: "Lama-2")
        let dated = garden(createdAt: Date(timeIntervalSince1970: 1_000))
        let newest = garden(createdAt: Date(timeIntervalSince1970: 3_000))
        let location = draft()
        let model = GardenListViewModel(
            source: ListDataSourceSpy(gardens: [old, newerLegacy, dated, newest], drafts: [location]), onEvent: { _ in }
        )
        #expect(model.presentation(showsFilter: true).items.map(\.id) == [newest.id, location.id, dated.id, newerLegacy.id, old.id])
    }

    @Test func userActionsEmitValuesWithoutAConcreteCoordinatorDependency() {
        var events: [GardenListEvent] = []
        let source = ListDataSourceSpy()
        let model = GardenListViewModel(source: source, onEvent: { events.append($0) })
        let local = garden(), location = draft()
        model.selectGarden(local)
        model.selectDraft(location)
        model.registerGarden()
        model.openDeveloperMode()
        #expect(events.count == 4)
        if case .openGarden(let id) = events[0] { #expect(id == local.id) } else { Issue.record("Expected profile event") }
        if case .resumeDraft(let value) = events[1] { #expect(value.id == location.id) } else { Issue.record("Expected draft event") }
        if case .registerGarden = events[2] {} else { Issue.record("Expected registration event") }
        if case .openDeveloperMode = events[3] {} else { Issue.record("Expected developer event") }
        #expect(source.refreshCount == 0 && source.deletedIDs.isEmpty)
    }

    @Test func refreshAndDeleteUseInjectedSourceWithoutOptimisticRemovalOnFailure() async {
        let location = draft()
        let source = ListDataSourceSpy(drafts: [location])
        let remote = garden(status: .submitted)
        source.refreshedGardens = [remote]
        let model = GardenListViewModel(source: source, onEvent: { _ in })
        await model.refresh()
        #expect(source.refreshCount == 1)
        #expect(Set(model.presentation(showsFilter: true).items.map(\.id)) == Set([location.id, remote.id]))
        source.rejectsDeletion = true
        #expect(!model.deleteDraft(location))
        #expect(model.presentation(showsFilter: true).items.contains { $0.id == location.id })
        source.rejectsDeletion = false
        #expect(model.deleteDraft(location))
        #expect(model.presentation(showsFilter: true).items.map(\.id) == [remote.id])
        #expect(source.deletedIDs == [location.id, location.id])
    }

    @Test func sharedStoreMutationInvalidatesObservationAndProfileEditsStayVisible() async throws {
        let store = makeTestGardenStore(in: AppConfiguration.makeModelContainer(inMemory: true))
        let model = GardenListViewModel(source: store, onEvent: { _ in })
        var local = garden()
        await confirmation("Changes in the shared store invalidate list presentation") { changed in
            withObservationTracking {
                _ = model.presentation(showsFilter: true).items
            } onChange: {
                changed()
            }
            #expect(store.add(local))
        }
        #expect(model.presentation(showsFilter: true).items.map(\.id) == [local.id])
        local.harvestRecord = HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 750)
        #expect(store.update(local))
        let item = try #require(model.presentation(showsFilter: true).items.first)
        if case .garden(let updated) = item {
            #expect(updated.harvestRecord?.latestWeightKg == 750)
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
        await dependencies.gardenListViewModel.refresh()
        #expect(dependencies.gardenListViewModel.presentation(showsFilter: true).items.count == 2)
        dependencies.gardenListViewModel.selectGarden(remote)
        #expect(dependencies.coordinator.path == [.gardenProfile(remote.id)])
        dependencies.coordinator.path = []
        dependencies.gardenListViewModel.selectDraft(location)
        #expect(dependencies.coordinator.mappingLocation?.draftID == location.id)
        #expect(dependencies.gardenListViewModel.deleteDraft(location))
        #expect(dependencies.gardenStore.drafts.isEmpty)
        dependencies.coordinator.mappingDidDismiss()
        dependencies.gardenListViewModel.registerGarden()
        #expect(dependencies.coordinator.registrationSheet == .guide)
    }
}

@MainActor
@Observable
private final class ListDataSourceSpy: GardenListDataSource {
    var gardens: [Garden]
    var drafts: [GardenDraft]
    var refreshedGardens: [Garden] = []
    var refreshCount = 0
    var deletedIDs: [UUID] = []
    var rejectsDeletion = false

    init(gardens: [Garden] = [], drafts: [GardenDraft] = []) {
        self.gardens = gardens
        self.drafts = drafts
    }

    func refreshRemote() async {
        refreshCount += 1
        gardens = refreshedGardens
    }

    func deleteDraft(_ draft: GardenDraft) -> Bool {
        deletedIDs.append(draft.id)
        guard !rejectsDeletion else { return false }
        drafts.removeAll { $0.id == draft.id }
        return true
    }
}
