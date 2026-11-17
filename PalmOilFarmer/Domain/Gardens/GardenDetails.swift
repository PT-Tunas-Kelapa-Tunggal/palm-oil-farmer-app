import Foundation

/// Required garden details shared by registration and editing.
/// Validation deliberately preserves the existing form's rules.
struct GardenDetails {
    let name: String
    let plantingYear: Int
    let soilType: SoilType

    init?(name: String, plantingYear: Int?, soilType: SoilType?) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let plantingYear, let soilType else { return nil }
        self.name = trimmedName
        self.plantingYear = plantingYear
        self.soilType = soilType
    }
}
