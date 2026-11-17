import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct LocationSearchViewModelTests {
    private func location(_ name: String) -> GardenLocation {
        GardenLocation(name: name, subtitle: "Riau", coordinate: GardenCoordinate(latitude: 1, longitude: 104))
    }

    @Test func blankQueryClearsResultsWithoutCallingSearch() async {
        let repository = LocationRepositoryStub()
        let model = LocationSearchViewModel(repository: repository, initialQuery: " \n ",
                                            initialResults: [location("Lama")], debounce: {}, onSelect: { _ in })
        await model.search()
        #expect(model.results.isEmpty && !model.isSearching)
        #expect(repository.queries.isEmpty && model.errorMessage == nil)
    }

    @Test func searchTrimsInputAndWaitsForInjectedDebounce() async {
        let repository = LocationRepositoryStub()
        let result = location("Dumai")
        repository.searchResult = [result]
        var debounced = false
        let model = LocationSearchViewModel(repository: repository, initialQuery: "  Dumai \n",
                                            debounce: { debounced = true }, onSelect: { _ in })
        await model.search()
        #expect(debounced && repository.queries == ["Dumai"])
        #expect(model.results.map(\.id) == [result.id] && !model.isSearching)
    }

    @Test func failedSearchKeepsExistingMessageAndRetryClearsIt() async {
        let repository = LocationRepositoryStub()
        repository.searchError = LocationRepositoryStub.Failure.unavailable
        let model = LocationSearchViewModel(repository: repository, initialQuery: "Dumai", debounce: {}, onSelect: { _ in })
        await model.search()
        #expect(model.errorMessage == "Pencarian gagal. Periksa koneksi internet lalu coba lagi.")
        #expect(!model.isSearching && model.results.isEmpty)
        repository.searchError = nil
        repository.searchResult = [location("Dumai")]
        await model.search()
        #expect(model.errorMessage == nil && model.results.count == 1)
    }

    @Test func olderResultCannotReplaceNewerQuery() async {
        let repository = ControlledLocationRepository()
        let model = LocationSearchViewModel(repository: repository, initialQuery: "Lama", debounce: {}, onSelect: { _ in })
        let old = Task { await model.search() }
        await repository.waitForSearch("Lama")
        model.query = "Baru"
        let new = Task { await model.search() }
        await repository.waitForSearch("Baru")
        let latest = location("Baru")
        repository.finishSearch("Baru", with: .success([latest]))
        await new.value
        repository.finishSearch("Lama", with: .success([location("Lama")]))
        await old.value
        #expect(model.results.map(\.id) == [latest.id] && !model.isSearching && model.errorMessage == nil)
    }

    @Test func obsoleteFailureDoesNotStopNewSearchOrPublishAnError() async {
        let repository = ControlledLocationRepository()
        let model = LocationSearchViewModel(repository: repository, initialQuery: "Lama", debounce: {}, onSelect: { _ in })
        let old = Task { await model.search() }
        await repository.waitForSearch("Lama")
        model.query = "Baru"
        let new = Task { await model.search() }
        await repository.waitForSearch("Baru")
        repository.finishSearch("Lama", with: .failure(LocationRepositoryStub.Failure.unavailable))
        await old.value
        #expect(model.isSearching && model.errorMessage == nil)
        repository.finishSearch("Baru", with: .success([]))
        await new.value
        #expect(!model.isSearching)
    }

    @Test func changedQueryRejectsResponseBeforeNextSwiftUITaskStarts() async {
        let repository = ControlledLocationRepository()
        let model = LocationSearchViewModel(repository: repository, initialQuery: "Lama", debounce: {}, onSelect: { _ in })
        let pending = Task { await model.search() }
        await repository.waitForSearch("Lama")
        model.query = "Baru"
        repository.finishSearch("Lama", with: .success([location("Lama")]))
        await pending.value
        #expect(model.results.isEmpty && model.errorMessage == nil)
    }

    @Test func cancelledSearchIgnoresLateResponseWithoutShowingFailure() async {
        let repository = ControlledLocationRepository()
        let model = LocationSearchViewModel(repository: repository, initialQuery: "Dumai", debounce: {}, onSelect: { _ in })
        let pending = Task { await model.search() }
        await repository.waitForSearch("Dumai")
        pending.cancel()
        repository.finishSearch("Dumai", with: .success([location("Terlambat")]))
        await pending.value
        #expect(model.results.isEmpty && model.errorMessage == nil && !model.isSearching)
    }

    @Test func debounceCancellationDoesNotReachRepository() async {
        let repository = LocationRepositoryStub()
        let model = LocationSearchViewModel(repository: repository, initialQuery: "Dumai",
                                            debounce: { throw CancellationError() }, onSelect: { _ in })
        await model.search()
        #expect(repository.queries.isEmpty && model.errorMessage == nil && !model.isSearching)
    }

    @Test func repeatedCurrentLocationTapUsesOneRequestAndPublishesOriginalLocation() async {
        let repository = LocationRepositoryStub()
        let selected = location("Lokasi saat ini")
        repository.currentResult = selected
        var selections: [GardenLocation] = []
        let model = LocationSearchViewModel(repository: repository, debounce: {}, onSelect: { selections.append($0) })
        model.requestCurrentLocation()
        let requestID = model.locationRequestID
        model.requestCurrentLocation()
        #expect(model.locationRequestID == requestID && model.isLocating)
        await model.locateCurrentIfRequested()
        #expect(repository.currentRequests == 1 && !model.isLocating)
        #expect(selections.map(\.id) == [selected.id] && selections.first?.source == .search)
    }

    @Test func locationFailureCanBeRetriedWithSameMessage() async {
        let repository = LocationRepositoryStub()
        var selected: GardenLocation?
        let model = LocationSearchViewModel(repository: repository, debounce: {}, onSelect: { selected = $0 })
        model.requestCurrentLocation()
        await model.locateCurrentIfRequested()
        #expect(!model.isLocating && selected == nil)
        #expect(model.errorMessage == "Lokasi tidak dapat diperoleh. Periksa izin lokasi dan coba lagi.")
        repository.currentResult = location("Coba lagi")
        model.requestCurrentLocation()
        await model.locateCurrentIfRequested()
        #expect(repository.currentRequests == 2 && selected?.name == "Coba lagi")
    }

    @Test func leavingScreenInvalidatesInFlightLocationEvenIfBackendIgnoresCancellation() async {
        let repository = ControlledLocationRepository()
        var selections = 0
        let model = LocationSearchViewModel(repository: repository, debounce: {}, onSelect: { _ in selections += 1 })
        model.requestCurrentLocation()
        let pending = Task { await model.locateCurrentIfRequested() }
        await repository.waitForCurrentLocation()
        model.cancelPendingWork()
        repository.finishCurrentLocation(with: .success(location("Terlambat")))
        await pending.value
        #expect(selections == 0 && !model.isLocating && model.errorMessage == nil)
    }

    @Test func taskCancelledLocationDoesNotEmitSelectionOrError() async {
        let repository = ControlledLocationRepository()
        var selections = 0
        let model = LocationSearchViewModel(repository: repository, debounce: {}, onSelect: { _ in selections += 1 })
        model.requestCurrentLocation()
        let pending = Task { await model.locateCurrentIfRequested() }
        await repository.waitForCurrentLocation()
        pending.cancel()
        repository.finishCurrentLocation(with: .success(location("Terlambat")))
        await pending.value
        #expect(selections == 0 && !model.isLocating && model.errorMessage == nil)
    }

    @Test func selectedSearchResultIsForwardedWithoutChangingIdentityOrSource() {
        var selected: GardenLocation?
        let value = location("Dumai")
        let model = LocationSearchViewModel(repository: LocationRepositoryStub(), onSelect: { selected = $0 })
        model.selectResult(value)
        #expect(selected?.id == value.id && selected?.coordinate == value.coordinate && selected?.source == value.source)
    }
}
