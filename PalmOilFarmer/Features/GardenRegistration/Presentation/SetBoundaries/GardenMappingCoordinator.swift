import Foundation
import Observation

/// Step 2 of registration: set the garden boundary on the satellite map (`GardenBoundaryView`).
///
/// Stages inside `GardenBoundaryView` and the bottom sheet each one shows:
/// `.location` → `LocationConfirmationPanel`, `.guide` → `BoundaryDrawingGuideSheet`
/// (+ animated `BoundaryDrawingGuideDemo` on the map), `.drawing` → `BoundaryEditingPanel`.
/// "Simpan Batas Kebun" opens step 3 (`CompleteInformation/GardenDetailsView`) as a sheet.
enum GardenMappingOutcome { case savedGarden, savedDraft, closed, searchAgain }

@MainActor
@Observable
final class GardenMappingCoordinator {
    var showsDetails = false
    var showsExitConfirmation = false
    private(set) var outcome: GardenMappingOutcome?
    private(set) var detailsSessionID: UUID?
    private(set) var savedGardenName: String?
    private var pendingOutcome: GardenMappingOutcome?
    private let onFinish: (GardenMappingOutcome) -> Void

    init(onFinish: @escaping (GardenMappingOutcome) -> Void) { self.onFinish = onFinish }

    var canEditBoundary: Bool {
        outcome == nil && pendingOutcome == nil && detailsSessionID == nil && !showsDetails && !showsExitConfirmation
    }

    func isCurrentDetailsSession(_ id: UUID) -> Bool {
        outcome == nil && pendingOutcome == nil && showsDetails && detailsSessionID == id
    }

    func handle(_ event: GardenMappingEvent) {
        guard canEditBoundary else { return }
        switch event {
        case .showDetails:
            detailsSessionID = UUID()
            showsDetails = true
        case .confirmExit: showsExitConfirmation = true
        case .close: finish(.closed)
        case .searchAgain: finish(.searchAgain)
        case .savedDraft: finish(.savedDraft)
        }
    }

    func continueMapping() { showsExitConfirmation = false }

    func recordSavedGarden(_ name: String) {
        savedGardenName = name
    }

    func discardAndClose() {
        // SwiftUI can clear the dialog binding before invoking its button action.
        guard outcome == nil, detailsSessionID == nil, !showsDetails, pendingOutcome == nil else { return }
        showsExitConfirmation = false
        finish(.closed)
    }

    func detailsSaved(sessionID: UUID) {
        guard isCurrentDetailsSession(sessionID) else { return }
        pendingOutcome = .savedGarden
        showsDetails = false
    }

    /// Closing the map waits until its details sheet has actually disappeared.
    func detailsDidDismiss() {
        showsDetails = false
        detailsSessionID = nil
        guard let pendingOutcome else { return }
        self.pendingOutcome = nil
        finish(pendingOutcome)
    }

    private func finish(_ outcome: GardenMappingOutcome) {
        guard self.outcome == nil else { return }
        self.outcome = outcome
        onFinish(outcome)
    }
}
