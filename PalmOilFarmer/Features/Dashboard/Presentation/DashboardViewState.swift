import Foundation

/// What the dashboard shows for the current data and filter, derived by `DashboardViewModel`.
struct DashboardViewState {
    let gardens: [DashboardGarden]
    let drafts: [DashboardDraft]
    let filter: DashboardFilter

    var isEmpty: Bool { gardens.isEmpty && drafts.isEmpty }
    var hasNoVisibleItems: Bool { visibleGardens.isEmpty && visibleDrafts.isEmpty }

    var items: [DashboardItem] {
        DashboardItem.newestFirst(gardens: visibleGardens, drafts: visibleDrafts)
    }

    func actionCount(for filter: DashboardFilter) -> Int {
        filter.actionCount(gardens: gardens, drafts: drafts)
    }

    private var visibleGardens: [DashboardGarden] { gardens.filter(filter.includes) }
    private var visibleDrafts: [DashboardDraft] { filter.includesDrafts ? drafts : [] }
}
