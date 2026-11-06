import Foundation

enum GardenProfileEditorField: Hashable {
    enum Nutrient: CaseIterable {
        case nitrogen, phosphorus, potassium, magnesium
    }

    case harvestFrequency
    case monthlyHarvestWeight
    case fertilizationFrequency
    case fertilizerType(UUID)
    case fertilizerDose(UUID)
    case fertilizerNutrient(UUID, Nutrient)
}

struct GardenProfileValidationIssue: Equatable {
    let field: GardenProfileEditorField?
    let message: String
}
