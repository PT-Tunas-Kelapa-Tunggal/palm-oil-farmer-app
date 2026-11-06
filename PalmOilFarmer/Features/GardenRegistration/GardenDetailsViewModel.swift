import Foundation
import Observation

@MainActor
@Observable
final class GardenDetailsViewModel {
    var name: String
    var plantingYear: Int?
    var plantingMonth: Int
    var soilType: SoilType?
    var showsSaveError = false
    private(set) var errorMessage = ""
    private(set) var hasSaved = false
    let boundary: GardenBoundary

    private let locationName: String
    private let originalGarden: Garden?
    private let onSave: (Garden) -> Bool
    private let onSaved: () -> Void
    private let makeID: () -> UUID
    private let now: () -> Date
    private let isActive: () -> Bool

    init(locationName: String, boundary: GardenBoundary, editing garden: Garden? = nil,
         makeID: @escaping () -> UUID = { UUID() }, now: @escaping () -> Date = { .now },
         isActive: @escaping () -> Bool = { true },
         onSave: @escaping (Garden) -> Bool, onSaved: @escaping () -> Void) {
        self.locationName = locationName
        self.boundary = boundary
        originalGarden = garden
        name = garden?.name ?? ""
        plantingYear = garden?.plantingYear
        // Older gardens without a stored month retain the existing October fallback.
        let defaultMonth = garden == nil ? Calendar.current.component(.month, from: now()) : 10
        let storedMonth = garden?.plantingMonth ?? defaultMonth
        plantingMonth = (1...12).contains(storedMonth) ? storedMonth : defaultMonth
        soilType = garden?.soilType
        self.makeID = makeID
        self.now = now
        self.isActive = isActive
        self.onSave = onSave
        self.onSaved = onSaved
    }

    var isEditing: Bool { originalGarden != nil }

    @discardableResult
    func save() -> Bool {
        guard !hasSaved else { return true }
        guard isActive() else { return false }
        guard let details = GardenDetails(name: name, plantingYear: plantingYear, soilType: soilType) else {
            errorMessage = "Lengkapi nama kebun, tahun tanam, dan jenis tanah terlebih dahulu."
            showsSaveError = true
            return false
        }
        errorMessage = "Data tidak dapat disimpan di perangkat. Coba lagi."
        var garden = Garden(id: originalGarden?.id ?? makeID(), name: details.name,
                            locationName: locationName, boundary: boundary,
                            plantingYear: details.plantingYear, soilType: details.soilType)
        garden.plantingMonth = plantingMonth
        garden.fertilizerRecords = originalGarden?.fertilizerRecords
        garden.harvestRecord = originalGarden?.harvestRecord
        garden.fertilizationFrequencyPerYear = originalGarden?.fertilizationFrequencyPerYear
        garden.review = originalGarden?.review
        garden.createdAt = originalGarden == nil ? now() : originalGarden?.createdAt
        showsSaveError = !onSave(garden)
        guard !showsSaveError else { return false }
        hasSaved = true
        onSaved()
        return true
    }
}
