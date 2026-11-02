import Foundation
import Observation

@MainActor
@Observable
final class AreaAllocationViewModel {
    private(set) var allocations: [AreaAllocation]
    private(set) var selectedFertilizer: String
    var selectedLine: AreaAllocation.Line?
    var errorMessage: String?

    private let gardenID: UUID
    private let repository: ReviewResultRepository

    /// Fails when there is no allocation, so `allocation` always has a value.
    init?(
        gardenID: UUID,
        allocations: [AreaAllocation],
        initialFertilizer: String? = nil,
        initialSelectedLine: AreaAllocation.Line? = nil,
        repository: ReviewResultRepository
    ) {
        guard let first = allocations.first else { return nil }
        self.gardenID = gardenID
        self.allocations = allocations
        self.repository = repository
        selectedFertilizer = initialFertilizer ?? first.selectedFertilizer
        selectedLine = initialSelectedLine
    }

    var allocation: AreaAllocation {
        allocations.first { $0.selectedFertilizer == selectedFertilizer } ?? allocations[0]
    }

    func selectFertilizer(_ name: String) {
        guard allocations.contains(where: { $0.selectedFertilizer == name }) else { return }
        selectedFertilizer = name
    }

    func select(_ line: AreaAllocation.Line) {
        selectedLine = line
    }

    /// Updates the screen only after the record is saved. A nil `areaID` means the whole garden.
    func markFertilized(areaID: Int?) async {
        let fertilizer = selectedFertilizer
        do {
            try await repository.markFertilized(areaID: areaID, fertilizer: fertilizer, gardenID: gardenID)
            allocations = allocations.map {
                $0.selectedFertilizer == fertilizer ? $0.markingFertilized(areaID: areaID) : $0
            }
            selectedLine = nil
            errorMessage = nil
        } catch {
            errorMessage = "Status pemupukan belum tersimpan. Periksa koneksi internet, lalu coba lagi."
        }
    }
}
