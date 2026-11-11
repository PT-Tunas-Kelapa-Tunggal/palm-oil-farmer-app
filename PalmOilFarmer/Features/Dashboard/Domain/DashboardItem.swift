import Foundation

/// One card on the home list: a registered garden or a draft waiting to be mapped.
enum DashboardItem: Identifiable {
    case garden(DashboardGarden)
    case draft(DashboardDraft)

    var id: UUID {
        switch self {
        case .garden(let garden): garden.id
        case .draft(let draft): draft.id
        }
    }

    /// Newest first. Gardens saved before `createdAt` existed keep their saved order, after dated items.
    static func newestFirst(gardens: [DashboardGarden], drafts: [DashboardDraft]) -> [DashboardItem] {
        let dated = gardens.enumerated().map { index, garden in
            (item: DashboardItem.garden(garden),
             date: garden.createdAt ?? Date.distantPast.addingTimeInterval(Double(index)))
        } + drafts.map { (item: DashboardItem.draft($0), date: $0.createdAt) }
        return dated.sorted { $0.date > $1.date }.map(\.item)
    }
}
