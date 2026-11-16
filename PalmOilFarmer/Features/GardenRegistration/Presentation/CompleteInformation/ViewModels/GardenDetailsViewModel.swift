import Foundation
import Observation

/// "Data Kebun" / "Edit Kebun" sheet: form fields, saving, and the sheet's own presentation state
/// ("Tahun Tanam" picker, closing).
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
    var showsPlantingDate = false
    private(set) var isFinished = false
    /// Kartu konfirmasi "Buang" di tombol X sedang terbuka.
    var showsExitConfirmation = false
    let boundary: GardenBoundary

    private let locationName: String
    private let originalGarden: Garden?
    private let onSave: (Garden) -> Bool
    private let onSaved: () -> Void
    private let makeID: () -> UUID
    private let now: () -> Date
    private let isActive: () -> Bool
    private let closesAfterSaving: Bool
    private let initialForm: FormSnapshot

    /// Isi form pada satu saat; dibandingkan dengan keadaan awal untuk tahu ada perubahan atau tidak.
    private struct FormSnapshot: Equatable {
        var name: String
        var plantingYear: Int?
        var plantingMonth: Int
        var soilType: SoilType?
    }

    /// - Parameter closesAfterSaving: close the sheet itself after a successful save. The boundary
    ///   map closes it instead (it waits for the dismissal), so registration passes `false`.
    init(locationName: String, boundary: GardenBoundary, editing garden: Garden? = nil,
         makeID: @escaping () -> UUID = { UUID() }, now: @escaping () -> Date = { .now },
         isActive: @escaping () -> Bool = { true }, closesAfterSaving: Bool = false,
         onSave: @escaping (Garden) -> Bool, onSaved: @escaping () -> Void) {
        self.locationName = locationName
        self.boundary = boundary
        originalGarden = garden
        name = garden?.name ?? ""
        plantingYear = garden?.plantingYear
        // Older gardens without a stored month retain the existing October fallback.
        let defaultMonth = garden == nil ? Calendar.current.component(.month, from: now()) : 10
        let storedMonth = garden?.plantingMonth ?? defaultMonth
        let month = (1...12).contains(storedMonth) ? storedMonth : defaultMonth
        plantingMonth = month
        soilType = garden?.soilType
        initialForm = FormSnapshot(name: garden?.name ?? "", plantingYear: garden?.plantingYear,
                                   plantingMonth: month, soilType: garden?.soilType)
        self.makeID = makeID
        self.now = now
        self.isActive = isActive
        self.closesAfterSaving = closesAfterSaving
        self.onSave = onSave
        self.onSaved = onSaved
    }

    var isEditing: Bool { originalGarden != nil }

    func openPlantingDate() {
        guard !isFinished, !showsPlantingDate else { return }
        showsPlantingDate = true
    }

    /// Ada isian yang berubah dan belum disimpan.
    var hasUnsavedChanges: Bool {
        !hasSaved && FormSnapshot(name: name, plantingYear: plantingYear,
                                  plantingMonth: plantingMonth, soilType: soilType) != initialForm
    }

    func close() { isFinished = true }

    /// Ketukan pada tombol X: tanya dulu kalau ada perubahan, kalau tidak langsung tutup.
    func requestClose() {
        guard !isFinished else { return }
        if hasUnsavedChanges {
            showsExitConfirmation = true
        } else {
            close()
        }
    }

    /// Tombol "Buang" pada kartu konfirmasi.
    func discardAndClose() {
        showsExitConfirmation = false
        close()
    }

    @discardableResult
    func save() -> Bool {
        guard !hasSaved else { return true }
        guard !isFinished, isActive() else { return false }
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
        if closesAfterSaving { close() }
        onSaved()
        return true
    }
}
