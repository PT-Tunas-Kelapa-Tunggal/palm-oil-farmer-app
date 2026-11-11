import Foundation
import Observation

/// What the farmer asked for on the dashboard. The view model only emits these;
/// the app decides where to go, so this feature has no coordinator or flow of its own.
enum DashboardEvent {
    case openGarden(UUID)
    case resumeDraft(DashboardDraft)
    case registerGarden
    #if DEBUG
    case openDeveloperMode
    #endif
}

/// Holds the dashboard's presentation state and reaches data only through
/// `DashboardRepositoryProtocol`, injected at the composition root.
@MainActor
@Observable
final class DashboardViewModel {
    var selectedFilter = DashboardFilter.all

    private let repository: any DashboardRepositoryProtocol
    private let onEvent: (DashboardEvent) -> Void

    init(repository: any DashboardRepositoryProtocol, onEvent: @escaping (DashboardEvent) -> Void) {
        self.repository = repository
        self.onEvent = onEvent
    }

    func viewState(showsFilter: Bool) -> DashboardViewState {
        DashboardViewState(
            gardens: repository.gardens,
            drafts: repository.drafts,
            filter: showsFilter ? selectedFilter : .all
        )
    }

    func refresh() async {
        await repository.refresh()
    }

    @discardableResult
    func deleteDraft(_ draft: DashboardDraft) -> Bool {
        repository.deleteDraft(id: draft.id)
    }

    func selectGarden(_ garden: DashboardGarden) { onEvent(.openGarden(garden.id)) }
    func selectDraft(_ draft: DashboardDraft) { onEvent(.resumeDraft(draft)) }
    func registerGarden() { onEvent(.registerGarden) }

    #if DEBUG
    func openDeveloperMode() { onEvent(.openDeveloperMode) }
    #endif
}
