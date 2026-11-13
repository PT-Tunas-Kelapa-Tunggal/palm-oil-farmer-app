import Foundation
import Observation

/// One sheet presentation on the profile. A new identity per opening, so a closed editor cannot write.
struct GardenProfileSheet: Identifiable, Hashable {
    enum Kind: Hashable { case details, review, profile, reviewInformation }
    let id = UUID()
    let kind: Kind
}

enum GardenProfileReviewAction { case request, status, results }

/// Builds the review request screens for one sheet session.
typealias GardenProfileReviewRequestMaker = (_ gardenID: UUID, _ isActive: @escaping () -> Bool,
                                             _ onSubmitted: @escaping (PlantationReviewRequest) -> Void,
                                             _ onClose: @escaping () -> Void) -> ReviewRequestFlow

/// "Profil Kebun": the garden being shown, its writes, and the screen's own presentation state
/// (editor sheets, history page, delete dialog, review screens).
///
/// Only one editor session is live at a time, and every write checks it, so a closed or replaced
/// editor cannot write through an old callback. Deleting is blocked while anything else is open.
@MainActor
@Observable
final class GardenProfileViewModel {
    let gardenID: UUID
    let reviewViewModel = GardenProfileReviewViewModel()
    var showsDeleteError = false
    private(set) var hasDeleted = false

    var sheet: GardenProfileSheet?
    var showsDeleteConfirmation = false
    var showsSummary = false
    var showsReviewStatus = false
    var showsResults = false
    private(set) var profileJustSaved = false
    private(set) var isFinished = false

    private var activeSheet: GardenProfileSheet?
    private var pendingReviewAction: GardenProfileReviewAction?
    private let initialGarden: Garden
    private let source: any GardenProfileDataSource
    private let reviewRepository: (any FarmerReviewRepository)?
    private let makeReviewRequestFlow: GardenProfileReviewRequestMaker?

    init(garden: Garden, source: any GardenProfileDataSource,
         reviewRepository: (any FarmerReviewRepository)? = nil,
         makeReviewRequest: GardenProfileReviewRequestMaker? = nil) {
        gardenID = garden.id
        initialGarden = garden
        self.source = source
        self.reviewRepository = reviewRepository
        makeReviewRequestFlow = makeReviewRequest
    }

    // MARK: Garden

    // The fallback renders the closing screen after deletion; writes require a live value.
    var garden: Garden { currentGarden ?? initialGarden }
    var isAvailable: Bool { currentGarden != nil && !hasDeleted }
    var fertilizers: [FertilizerRecord] { garden.fertilizerRecords ?? [] }
    var isComplete: Bool { garden.isProfileComplete }
    var canDelete: Bool { source.canDeleteGardens && isAvailable }
    private var currentGarden: Garden? { source.gardens.first { $0.id == gardenID } }

    func loadReview() async {
        guard let reviewRepository else { return }
        await reviewViewModel.load(for: gardenID, repository: reviewRepository)
        syncLocalGardenReviewWithRemote()
    }

    func syncLocalGardenReviewWithRemote() {
        guard let activeStatus = reviewViewModel.activeStatus,
              var updated = currentGarden else { return }
        let currentReview = updated.review ?? GardenReview(contact: ReviewContactDetails(name: "", phone: "", address: ""))
        var stageDates = currentReview.stageDates
        if stageDates.count <= activeStatus.rawValue {
            stageDates += Array(repeating: Date(), count: (activeStatus.rawValue + 1) - stageDates.count)
        }
        if let events = reviewViewModel.detailEvents {
            for event in events {
                let idx: Int?
                switch event.title.lowercased() {
                case "sent": idx = 0
                case "scheduled": idx = 1
                case "in progress", "inprogress": idx = 2
                case "finished": idx = 3
                default: idx = nil
                }
                if let idx, stageDates.indices.contains(idx) {
                    stageDates[idx] = event.dateTime
                }
            }
        }
        let updatedReview = GardenReview(
            status: activeStatus,
            contact: currentReview.contact,
            stageDates: stageDates,
            resultsDownloaded: currentReview.resultsDownloaded || (activeStatus == .completed)
        )
        updated.review = updatedReview
        _ = source.update(updated)
    }

    func observeReviewUpdates() -> AsyncStream<PlantationReviewRequest>? {
        reviewRepository?.observeRequestUpdates(for: gardenID)
    }

    func saveProfile(harvest: HarvestRecord, frequency: Int, fertilizers: [FertilizerRecord]) -> Bool {
        guard !isFinished, !hasDeleted, var updated = currentGarden else { return false }
        updated.harvestRecord = harvest
        updated.fertilizationFrequencyPerYear = frequency
        updated.fertilizerRecords = fertilizers
        updated.profileUpdatedAt = .now
        return source.update(updated)
    }

    func saveFertilizers(_ records: [FertilizerRecord]) -> Bool {
        guard !isFinished, !hasDeleted, var updated = currentGarden else { return false }
        updated.fertilizerRecords = records
        updated.profileUpdatedAt = .now
        return source.update(updated)
    }

    func saveHarvest(_ record: HarvestRecord) -> Bool {
        guard !isFinished, !hasDeleted, var updated = currentGarden else { return false }
        updated.harvestRecord = record
        updated.profileUpdatedAt = .now
        return source.update(updated)
    }

    func saveDetails(_ edited: Garden) -> Bool {
        guard !isFinished, !hasDeleted, edited.id == gardenID, let latest = currentGarden else { return false }
        let updated = Garden(
            id: latest.id, name: edited.name, locationName: latest.locationName, boundary: latest.boundary,
            plantingYear: edited.plantingYear, soilType: edited.soilType, plantingMonth: edited.plantingMonth,
            fertilizerRecords: latest.fertilizerRecords, harvestRecord: latest.harvestRecord,
            review: latest.review, createdAt: latest.createdAt, fertilizationFrequencyPerYear: latest.fertilizationFrequencyPerYear, profileUpdatedAt: latest.profileUpdatedAt
        )
        return source.update(updated)
    }

    func updateReview(_ change: (inout GardenReview) -> Void) {
        guard !isFinished, !hasDeleted, var updated = currentGarden, var review = updated.review else { return }
        change(&review)
        updated.review = review
        _ = source.update(updated)
    }

    // MARK: Deleting

    var canDeleteNow: Bool {
        !isFinished && activeSheet == nil && !showsSummary && !showsReviewStatus && !showsResults
    }

    func requestDelete() {
        guard canDeleteNow else { return }
        showsDeleteConfirmation = true
    }

    @discardableResult
    func delete() -> Bool {
        guard !hasDeleted else { return true }
        guard canDeleteNow, canDelete, let currentGarden else { return false }
        guard source.delete(currentGarden) else { showsDeleteError = true; return false }
        hasDeleted = true
        close()
        return true
    }

    // MARK: Sheets

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

    func profileSaved(_ presentation: GardenProfileSheet) {
        guard presentation.kind == .profile, isCurrent(presentation) else { return }
        profileJustSaved = true
        closeSheet(presentation)
    }

    /// Clears the session once the sheet has actually disappeared, then runs a queued review action.
    func sheetDidDismiss() {
        sheet = nil
        activeSheet = nil
        let nextReviewAction = pendingReviewAction
        pendingReviewAction = nil
        guard !isFinished, let nextReviewAction else { return }
        reviewAction(nextReviewAction)
    }

    func makeDetailsEditor(for presentation: GardenProfileSheet) -> GardenDetailsViewModel {
        let latest = garden
        return GardenDetailsViewModel(locationName: latest.locationName, boundary: latest.boundary, editing: latest,
            isActive: { [weak self] in
                presentation.kind == .details && self?.isCurrent(presentation) == true
            },
            closesAfterSaving: true,
            onSave: { [weak self] edited in self?.saveDetails(edited) ?? false },
            onSaved: { [weak self] in self?.closeSheet(presentation) })
    }

    func makeProfileEditor(for presentation: GardenProfileSheet) -> GardenProfileEditorViewModel {
        GardenProfileEditorViewModel(garden: garden,
            isActive: { [weak self] in
                presentation.kind == .profile && self?.isCurrent(presentation) == true
            },
            onSave: { [weak self] in self?.saveProfile(harvest: $0, frequency: $1, fertilizers: $2) ?? false },
            onSaved: { [weak self] in self?.profileSaved(presentation) })
    }

    func makeReviewRequest(for presentation: GardenProfileSheet) -> ReviewRequestFlow? {
        makeReviewRequestFlow?(gardenID,
            { [weak self] in presentation.kind == .review && self?.isCurrent(presentation) == true },
            { [weak self] saved in
                guard let self, isCurrent(presentation) else { return }
                reviewViewModel.submitted(saved)
            },
            { [weak self] in self?.closeSheet(presentation) })
    }

    // MARK: History page

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

    // MARK: Review

    func applyForReview(from presentation: GardenProfileSheet, action: GardenProfileReviewAction) {
        guard presentation.kind == .reviewInformation, isCurrent(presentation) else { return }
        pendingReviewAction = action
        closeSheet(presentation)
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

    // MARK: Leaving

    func close() {
        isFinished = true
        sheet = nil
        activeSheet = nil
        pendingReviewAction = nil
        showsDeleteConfirmation = false
        showsSummary = false
        showsReviewStatus = false
        showsResults = false
    }
}
