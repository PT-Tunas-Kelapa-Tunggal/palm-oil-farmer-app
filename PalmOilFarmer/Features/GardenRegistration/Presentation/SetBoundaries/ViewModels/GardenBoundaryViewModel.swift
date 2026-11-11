import Foundation
import Observation

/// How the boundary map ended. The app root decides where to go next.
enum GardenMappingOutcome { case savedGarden, savedDraft, closed, searchAgain }

/// Boundary map: the drawn boundary plus the map's own presentation state.
///
/// While the "Data Kebun" sheet or the exit dialog is open the boundary is locked
/// (`canEditBoundary == false`), so the geometry cannot drift under the details editor.
/// A successful save waits for the details sheet to finish dismissing before the map finishes.
@MainActor
@Observable
final class GardenBoundaryViewModel {
    let location: GardenLocation
    private(set) var boundary = GardenBoundary()
    private(set) var isConfirmingPhoto: Bool
    var showsDetails = false
    var showsExitConfirmation = false
    private(set) var outcome: GardenMappingOutcome?
    private(set) var detailsSessionID: UUID?
    private(set) var savedGardenName: String?

    private var didSaveDraft = false
    private var pendingOutcome: GardenMappingOutcome?
    private let allowsLocationDrafts: Bool
    private let saving: any GardenRegistrationSaving
    private let authorization: any GardenLocationAuthorizing
    private let onFinish: (GardenMappingOutcome) -> Void

    init(location: GardenLocation, saving: any GardenRegistrationSaving,
         authorization: any GardenLocationAuthorizing, allowsLocationDrafts: Bool,
         onFinish: @escaping (GardenMappingOutcome) -> Void) {
        self.location = location
        self.saving = saving
        self.authorization = authorization
        self.allowsLocationDrafts = allowsLocationDrafts
        isConfirmingPhoto = location.source == .photo
        self.onFinish = onFinish
    }

    // MARK: State

    var isClosed: Bool { boundary.points.count >= GardenBoundary.minimumMappingPointCount }

    var canEditBoundary: Bool {
        outcome == nil && pendingOutcome == nil && detailsSessionID == nil && !showsDetails && !showsExitConfirmation
    }

    var canConfirmBoundary: Bool { canEditBoundary && !isConfirmingPhoto && boundary.isReadyForMapping }

    var canSaveLocationDraft: Bool {
        canEditBoundary && allowsLocationDrafts && location.source == .search && boundary.points.isEmpty
            && !isConfirmingPhoto && !didSaveDraft
    }

    // MARK: Boundary editing

    func requestLocationAuthorization() { authorization.requestAuthorization() }

    func confirmPhoto() {
        guard canEditBoundary else { return }
        isConfirmingPhoto = false
    }

    func addPoint(_ point: GardenCoordinate) {
        guard canEditBoundary, !isConfirmingPhoto, !boundary.points.contains(point) else { return }
        boundary.points.append(point)
    }

    func movePoint(at index: Int, to point: GardenCoordinate) {
        guard canEditBoundary, !isConfirmingPhoto, boundary.points.indices.contains(index),
              boundary.points[index] != point else { return }
        boundary.points[index] = point
    }

    func undo() {
        guard canEditBoundary else { return }
        _ = boundary.points.popLast()
    }

    func clear() {
        guard canEditBoundary else { return }
        boundary.points.removeAll()
    }

    // MARK: Leaving the map

    /// "Simpan Batas Kebun": opens the "Data Kebun" sheet with a fresh session.
    func confirmBoundary() {
        guard canConfirmBoundary else { return }
        detailsSessionID = UUID()
        showsDetails = true
    }

    /// An empty map closes at once; a drawn boundary asks first.
    func close() {
        guard canEditBoundary else { return }
        if boundary.points.isEmpty {
            finish(.closed)
        } else {
            showsExitConfirmation = true
        }
    }

    func searchAgain() {
        guard canEditBoundary, boundary.points.isEmpty else { return }
        finish(.searchAgain)
    }

    @discardableResult
    func saveDraft() -> Bool {
        guard canSaveLocationDraft, saving.saveLocationDraft(GardenDraft(location: location)) else { return false }
        didSaveDraft = true
        finish(.savedDraft)
        return true
    }

    // MARK: Exit dialog

    func continueMapping() { showsExitConfirmation = false }

    func discardAndClose() {
        // SwiftUI can clear the dialog binding before invoking its button action.
        guard outcome == nil, detailsSessionID == nil, !showsDetails, pendingOutcome == nil else { return }
        showsExitConfirmation = false
        finish(.closed)
    }

    // MARK: Details sheet

    /// Builds the "Data Kebun" view model for the current session. A view model from an older,
    /// cancelled session can no longer save.
    func makeDetailsViewModel() -> GardenDetailsViewModel {
        let sessionID = detailsSessionID
        return GardenDetailsViewModel(locationName: location.name, boundary: boundary,
            isActive: { [weak self] in
                guard let self, let sessionID else { return false }
                return isCurrentDetailsSession(sessionID)
            },
            onSave: { [weak self] garden in
                guard let self else { return false }
                let saved = saving.saveGarden(garden, completingDraft: location.draftID)
                if saved { savedGardenName = garden.name }
                return saved
            },
            onSaved: { [weak self] in
                if let sessionID { self?.detailsSaved(sessionID: sessionID) }
            })
    }

    func isCurrentDetailsSession(_ id: UUID) -> Bool {
        outcome == nil && pendingOutcome == nil && showsDetails && detailsSessionID == id
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
