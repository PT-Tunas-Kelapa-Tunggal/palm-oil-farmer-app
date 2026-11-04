import Foundation
import Observation

/// Registration writes go through the shared application state during migration.
@MainActor
protocol GardenRegistrationSaving {
    func saveGarden(_ garden: Garden, completingDraft draftID: UUID?) -> Bool
    func saveLocationDraft(_ draft: GardenDraft) -> Bool
}

enum GardenMappingEvent {
    case showDetails, confirmExit, close, searchAgain, savedDraft
}

@MainActor
@Observable
final class GardenBoundaryViewModel {
    let location: GardenLocation
    private(set) var boundary = GardenBoundary()
    private(set) var isConfirmingPhoto: Bool
    private var didSaveDraft = false
    private let allowsLocationDrafts: Bool
    private let saving: any GardenRegistrationSaving
    private let authorization: any GardenLocationAuthorizing
    private let onEvent: (GardenMappingEvent) -> Void
    private let isActive: () -> Bool

    init(location: GardenLocation, saving: any GardenRegistrationSaving,
         authorization: any GardenLocationAuthorizing, allowsLocationDrafts: Bool,
         isActive: @escaping () -> Bool = { true },
         onEvent: @escaping (GardenMappingEvent) -> Void) {
        self.location = location
        self.saving = saving
        self.authorization = authorization
        self.allowsLocationDrafts = allowsLocationDrafts
        isConfirmingPhoto = location.source == .photo
        self.onEvent = onEvent
        self.isActive = isActive
    }

    var canSaveLocationDraft: Bool {
        isActive() && allowsLocationDrafts && location.source == .search && boundary.points.isEmpty
            && !isConfirmingPhoto && !didSaveDraft
    }

    func requestLocationAuthorization() { authorization.requestAuthorization() }
    func confirmPhoto() {
        guard isActive() else { return }
        isConfirmingPhoto = false
    }

    func addPoint(_ point: GardenCoordinate) {
        guard isActive(), !isConfirmingPhoto, !boundary.points.contains(point) else { return }
        boundary.points.append(point)
    }

    func movePoint(at index: Int, to point: GardenCoordinate) {
        guard isActive(), !isConfirmingPhoto, boundary.points.indices.contains(index) else { return }
        boundary.points[index] = point
    }

    func undo() { if isActive() { _ = boundary.points.popLast() } }
    func clear() { if isActive() { boundary.points.removeAll() } }

    func confirmBoundary() {
        guard isActive(), !isConfirmingPhoto, boundary.isValid else { return }
        onEvent(.showDetails)
    }

    func close() {
        guard isActive() else { return }
        onEvent(boundary.points.isEmpty ? .close : .confirmExit)
    }

    func searchAgain() {
        guard isActive(), isConfirmingPhoto else { return }
        onEvent(.searchAgain)
    }

    @discardableResult
    func saveDraft() -> Bool {
        guard canSaveLocationDraft, saving.saveLocationDraft(GardenDraft(location: location)) else { return false }
        didSaveDraft = true
        onEvent(.savedDraft)
        return true
    }
}
