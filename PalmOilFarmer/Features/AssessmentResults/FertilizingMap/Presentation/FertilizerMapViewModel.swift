import Foundation
import Observation

@Observable
@MainActor
public final class FertilizingMapViewModel {
    public enum ActiveModalSheet: String, Identifiable {
        case chooseFertilizer
        case chooseAreaDivision

        public var id: String { rawValue }
    }

    private let repository: any FertilizingMapRepositoryProtocol

    public let gardenId: String
    public var item: FertilizingMapItem?
    public var selectedZone: FertilizingZoneDetail?
    public var areaDivision: AreaDivisionMode = .perZona
    public var isInPeriod: Bool = true
    public var activeModalSheet: ActiveModalSheet?
    public var isLoading: Bool = false
    public var errorMessage: String?

    private let initialFertilizerName: String?

    public init(
        repository: any FertilizingMapRepositoryProtocol = DummyFertilizingMapRepository(),
        gardenId: String = "garden-default",
        initialFertilizerName: String? = nil,
        isInPeriod: Bool = true,
        initialAreaDivision: AreaDivisionMode = .perZona
    ) {
        self.repository = repository
        self.gardenId = gardenId
        self.initialFertilizerName = initialFertilizerName
        self.isInPeriod = isInPeriod
        self.areaDivision = initialAreaDivision
    }

    public convenience init(
        repository: any FertilizingMapRepositoryProtocol = DummyFertilizingMapRepository(),
        gardenId: UUID,
        initialFertilizerName: String? = nil,
        isInPeriod: Bool = true,
        initialAreaDivision: AreaDivisionMode = .perZona
    ) {
        self.init(
            repository: repository,
            gardenId: gardenId.uuidString,
            initialFertilizerName: initialFertilizerName,
            isInPeriod: isInPeriod,
            initialAreaDivision: initialAreaDivision
        )
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            var loaded = try await repository.fetchMap(for: gardenId)
            if let initialName = initialFertilizerName,
               let match = loaded.availableFertilizers.first(where: {
                   $0.name.localizedCaseInsensitiveContains(initialName) || initialName.localizedCaseInsensitiveContains($0.name)
               }) {
                loaded = try await repository.selectFertilizer(fertilizerId: match.id, for: gardenId)
                if match.defaultDivision == .wholeFarm {
                    areaDivision = .wholeFarm
                }
            }
            item = loaded
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func selectFertilizer(_ option: FertilizerPeriodOption) async {
        do {
            var updated = try await repository.selectFertilizer(fertilizerId: option.id, for: gardenId)
            updated.isMarkedDone = item?.isMarkedDone ?? false
            item = updated
        } catch {
            errorMessage = error.localizedDescription
        }
        if option.defaultDivision == .wholeFarm {
            areaDivision = .wholeFarm
        } else if areaDivision == .wholeFarm {
            areaDivision = option.defaultDivision
        }
        activeModalSheet = nil
    }

    public func selectAreaDivision(_ mode: AreaDivisionMode) {
        areaDivision = mode
        activeModalSheet = nil
    }

    public func openFertilizerSelector() {
        activeModalSheet = .chooseFertilizer
    }

    public func openAreaDivisionSelector() {
        activeModalSheet = .chooseAreaDivision
    }

    public func closeActiveSheet() {
        activeModalSheet = nil
    }

    public func toggleMarkDone() async {
        guard let current = item else { return }
        let newStatus = !current.isMarkedDone
        do {
            var updated = try await repository.markAsFertilized(for: gardenId, isDone: newStatus)
            if updated.selectedFertilizer.id != current.selectedFertilizer.id {
                updated = try await repository.selectFertilizer(
                    fertilizerId: current.selectedFertilizer.id,
                    for: gardenId
                )
                updated.isMarkedDone = newStatus
            }
            item = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func selectZone(_ zone: FertilizingZoneDetail) {
        if selectedZone?.id == zone.id {
            selectedZone = nil
        } else {
            selectedZone = zone
        }
    }

    public func deselectZone() {
        selectedZone = nil
    }
}
