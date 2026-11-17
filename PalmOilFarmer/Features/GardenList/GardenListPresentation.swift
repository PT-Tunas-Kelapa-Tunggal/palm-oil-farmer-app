import Foundation

struct GardenListPresentation {
    let gardens: [Garden]
    let drafts: [GardenDraft]
    let filter: GardenListFilter

    var isEmpty: Bool { gardens.isEmpty && drafts.isEmpty }
    var hasNoVisibleItems: Bool { visibleGardens.isEmpty && visibleDrafts.isEmpty }

    var items: [GardenListItem] {
        GardenListItem.newestFirst(gardens: visibleGardens, drafts: visibleDrafts)
    }

    func actionCount(for filter: GardenListFilter) -> Int {
        filter.actionCount(gardens: gardens, drafts: drafts)
    }

    private var visibleGardens: [Garden] { gardens.filter(filter.includes) }
    private var visibleDrafts: [GardenDraft] { filter.includesDrafts ? drafts : [] }
}
