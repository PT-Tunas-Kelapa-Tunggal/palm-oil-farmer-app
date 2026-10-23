import Foundation

/// Where a registered garden is in the farmer's journey; shown as the label on its card.
enum GardenStage: Equatable {
    case incomplete, readyForReview, inReview(ReviewStatus), results(downloaded: Bool)

    /// The farmer has something to do: finish the profile, submit, attend the visit, or open new results.
    var needsAction: Bool {
        switch self {
        case .incomplete, .readyForReview, .inReview(.scheduled), .results(downloaded: false): true
        case .inReview, .results: false
        }
    }
}

extension Garden {
    var isProfileComplete: Bool { !(fertilizerRecords ?? []).isEmpty && harvestRecord != nil }

    var stage: GardenStage {
        if let review {
            return review.status == .completed ? .results(downloaded: review.resultsDownloaded) : .inReview(review.status)
        }
        return isProfileComplete ? .readyForReview : .incomplete
    }
}

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

/// Home screen filter. Drafts always need mapping; other stages are labels on the cards under Semua.
enum GardenListFilter: String, CaseIterable, Identifiable {
    case all = "Semua"
    case draft = "Draf"
    case inReview = "Ditinjau"

    var id: Self { self }

    var accessibilityName: String {
        switch self {
        case .all: "Semua kebun"
        case .draft: "Lanjutkan pemetaan"
        case .inReview: "Dalam proses peninjauan"
        }
    }

    var emptyMessage: String {
        switch self {
        case .all: "Belum ada kebun terdaftar."
        case .draft: "Tidak ada kebun yang menunggu pemetaan."
        case .inReview: "Tidak ada kebun dalam proses peninjauan."
        }
    }

    func includes(_ garden: Garden) -> Bool {
        switch self {
        case .all: true
        case .draft: false
        case .inReview: if case .inReview = garden.stage { true } else { false }
        }
    }

    var includesDrafts: Bool { self != .inReview }

    /// Items in this tab that need the farmer to act, for the tab's badge.
    func actionCount(gardens: [Garden], drafts: [GardenDraft]) -> Int {
        gardens.filter { includes($0) && $0.stage.needsAction }.count + (includesDrafts ? drafts.count : 0)
    }
}
