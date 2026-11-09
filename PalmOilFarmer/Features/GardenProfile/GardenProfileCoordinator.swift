import Foundation
import Observation

struct GardenProfileSheet: Identifiable {
    enum Kind { case details, review, profile, reviewInformation }
    let id = UUID()
    let kind: Kind
}

enum GardenProfileReviewAction { case request, status, results }

@MainActor
@Observable
final class GardenProfileCoordinator {
    private(set) var profileJustSaved = false
    var sheet: GardenProfileSheet?
    var showsDeleteConfirmation = false
    var showsSummary = false
    var showsReviewStatus = false
    var showsResults = false
    private(set) var isFinished = false
    private var activeSheet: GardenProfileSheet?
    private var pendingSheet: GardenProfileSheet.Kind?
    private var pendingReviewAction: GardenProfileReviewAction?

    var canDeleteNow: Bool {
        !isFinished && activeSheet == nil && !showsSummary && !showsReviewStatus && !showsResults
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

    func profileSaved(_ presentation: GardenProfileSheet) {
        guard presentation.kind == .profile, isCurrent(presentation) else { return }
        profileJustSaved = true
        closeSheet(presentation)
    }

    func closeSheet(_ presentation: GardenProfileSheet) {
        guard isCurrent(presentation) else { return }
        sheet = nil
    }

    func sheetDidDismiss() {
        sheet = nil
        activeSheet = nil
        let nextSheet = pendingSheet
        let nextReviewAction = pendingReviewAction
        pendingSheet = nil
        pendingReviewAction = nil
        guard !isFinished else { return }
        if let nextSheet { open(nextSheet) }
        if let nextReviewAction { reviewAction(nextReviewAction) }
    }

    func openSummary() {
        guard canDeleteNow, !showsDeleteConfirmation else { return }
        showsSummary = true
    }

    func closeSummary() {
        guard activeSheet == nil else { return }
        showsSummary = false
    }

    func editSummary() {
        guard showsSummary, !isFinished, activeSheet == nil else { return }
        let presentation = GardenProfileSheet(kind: .profile)
        activeSheet = presentation
        sheet = presentation
    }

    func applyForReview(from presentation: GardenProfileSheet, action: GardenProfileReviewAction) {
        guard presentation.kind == .reviewInformation, isCurrent(presentation) else { return }
        pendingReviewAction = action
        closeSheet(presentation)
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
        activeSheet = nil
        pendingSheet = nil
        pendingReviewAction = nil
        showsDeleteConfirmation = false
        showsSummary = false
        showsReviewStatus = false
        showsResults = false
    }
}
