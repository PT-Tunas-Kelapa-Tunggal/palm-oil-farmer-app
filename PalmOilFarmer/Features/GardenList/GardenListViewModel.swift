import Foundation
import Observation

/// The list reads shared values without owning persistence or a navigation stack.
@MainActor
protocol GardenListDataSource: AnyObject {
    var gardens: [Garden] { get }
    var drafts: [GardenDraft] { get }
    func refreshRemote() async
    @discardableResult func deleteDraft(_ draft: GardenDraft) -> Bool
}

enum GardenListEvent {
    case openGarden(UUID)
    case resumeDraft(GardenDraft)
    case registerGarden
    #if DEBUG
    case openDeveloperMode
    #endif
}

@MainActor
@Observable
final class GardenListViewModel {
    var selectedFilter = GardenListFilter.all

    private let source: any GardenListDataSource
    private let onEvent: (GardenListEvent) -> Void

    init(source: any GardenListDataSource, onEvent: @escaping (GardenListEvent) -> Void) {
        self.source = source
        self.onEvent = onEvent
    }

    func presentation(showsFilter: Bool) -> GardenListPresentation {
        GardenListPresentation(
            gardens: source.gardens,
            drafts: source.drafts,
            filter: showsFilter ? selectedFilter : .all
        )
    }

    func refresh() async {
        await source.refreshRemote()
    }

    @discardableResult
    func deleteDraft(_ draft: GardenDraft) -> Bool {
        source.deleteDraft(draft)
    }

    func selectGarden(_ garden: Garden) { onEvent(.openGarden(garden.id)) }
    func selectDraft(_ draft: GardenDraft) { onEvent(.resumeDraft(draft)) }
    func registerGarden() { onEvent(.registerGarden) }

    #if DEBUG
    func openDeveloperMode() { onEvent(.openDeveloperMode) }
    #endif
}
