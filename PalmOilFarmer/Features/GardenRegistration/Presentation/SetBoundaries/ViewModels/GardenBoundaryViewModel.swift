import Foundation
import Observation

enum GardenMappingEvent {
    case showDetails, confirmExit, close, searchAgain, savedDraft
}

@MainActor
@Observable
final class GardenBoundaryViewModel {
    let location: GardenLocation
    private(set) var boundary = GardenBoundary()
    var isClosed: Bool { boundary.points.count >= GardenBoundary.minimumMappingPointCount }
    var canConfirmBoundary: Bool { isActive() && !isConfirmingPhoto && boundary.isReadyForMapping }
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
        guard isActive(), !isConfirmingPhoto, boundary.points.indices.contains(index),
              boundary.points[index] != point else { return }
        boundary.points[index] = point
    }

    func undo() {
        guard isActive() else { return }
        _ = boundary.points.popLast()
    }

    func clear() {
        guard isActive() else { return }
        boundary.points.removeAll()
    }

    func confirmBoundary() {
        guard canConfirmBoundary else { return }
        onEvent(.showDetails)
    }

    func close() {
        guard isActive() else { return }
        onEvent(boundary.points.isEmpty ? .close : .confirmExit)
    }

    func searchAgain() {
        guard isActive(), boundary.points.isEmpty else { return }
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
