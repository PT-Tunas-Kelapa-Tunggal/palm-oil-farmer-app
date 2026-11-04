import Foundation
import Observation

struct GardenProfileSheet: Identifiable {
    enum Kind { case details, fertilizer, harvest, review }
    let id = UUID()
    let kind: Kind
}

enum GardenProfileReviewAction { case request, status, results }

@MainActor
@Observable
final class GardenProfileCoordinator {
    var sheet: GardenProfileSheet?
    var showsDeleteConfirmation = false
    var showsReviewStatus = false
    var showsResults = false
    private(set) var isFinished = false
    private var activeSheet: GardenProfileSheet?

    var canDeleteNow: Bool {
        !isFinished && activeSheet == nil && !showsReviewStatus && !showsResults
    }

    func open(_ kind: GardenProfileSheet.Kind) {
        guard canDeleteNow, !showsDeleteConfirmation else { return }
        let presentation = GardenProfileSheet(kind: kind)
        activeSheet = presentation
        sheet = presentation
    }

    func isCurrent(_ presentation: GardenProfileSheet) -> Bool {
        !isFinished && activeSheet?.id == presentation.id && sheet?.id == presentation.id
            && activeSheet?.kind == presentation.kind
    }

    func closeSheet(_ presentation: GardenProfileSheet) {
        guard isCurrent(presentation) else { return }
        sheet = nil
    }

    func sheetDidDismiss() {
        sheet = nil
        activeSheet = nil
    }

    func requestDelete() {
        guard canDeleteNow else { return }
        showsDeleteConfirmation = true
    }

    func reviewAction(_ action: GardenProfileReviewAction) {
        guard canDeleteNow, !showsDeleteConfirmation else { return }
        switch action {
        case .request: open(.review)
        case .status: showsReviewStatus = true
        case .results: showsResults = true
        }
    }

    func openResults() {
        guard !isFinished, activeSheet == nil else { return }
        showsResults = true
    }

    func close() {
        isFinished = true
        sheet = nil
        showsDeleteConfirmation = false
    }
}
