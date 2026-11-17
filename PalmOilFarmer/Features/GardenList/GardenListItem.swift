import Foundation

/// One card on the home list: a registered garden or a draft waiting to be mapped.
enum GardenListItem: Identifiable {
    case garden(Garden)
    case draft(GardenDraft)

    var id: UUID {
        switch self {
        case .garden(let garden): garden.id
        case .draft(let draft): draft.id
        }
    }

    /// Newest first. Gardens saved before `createdAt` existed keep their saved order, after dated items.
    static func newestFirst(gardens: [Garden], drafts: [GardenDraft]) -> [GardenListItem] {
        let dated = gardens.enumerated().map { index, garden in
            (item: GardenListItem.garden(garden),
             date: garden.createdAt ?? Date.distantPast.addingTimeInterval(Double(index)))
        } + drafts.map { (item: GardenListItem.draft($0), date: $0.createdAt) }
        return dated.sorted { $0.date > $1.date }.map(\.item)
    }
}
