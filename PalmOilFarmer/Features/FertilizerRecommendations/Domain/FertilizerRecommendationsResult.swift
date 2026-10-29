import Foundation

/// Agronomic result consumed by FertilizerRecommendations. Quantities are kilograms
/// unless the property name says otherwise. This model intentionally contains only
/// values present in the pulse-check payload; it does not infer prices or projections.
struct FertilizerRecommendationsResult: Equatable {
    let farm: Farm
    let zoneImage: String?
    let annualSummary: AnnualSummary
    let zones: [ZoneAllocation]
    let recommendedNPKMg: RecommendedNPKMg?
    let nutrientComparisonInsight: String?
    let compoundNPKInsight: String?
    let singleFertilizerInsight: String?

    struct RecommendedNPKMg: Equatable {
        let name: String
        let composition: NPKComposition
        let comparisonBasisBagWeightKg: Double
    }

    struct Farm: Equatable {
        let name: String
        let locationLabel: String
        let sourceImage: String
    }

    struct AnnualSummary: Equatable {
        let zoneCount: Int
        let treeCount: Int
        let nutrientBoostsKg: [Nutrient: Double]
        let productBoosts: [ProductBoost]
    }

    struct ZoneAllocation: Equatable, Identifiable {
        let id: String
        let centerPoint: CenterPoint?
        let treeCount: Int
        let areaHectares: Double
        let nutrientBoostsKg: [Nutrient: Double]
        let products: [ProductAllocation]
    }

    struct CenterPoint: Equatable {
        let normalizedX: Double
        let normalizedY: Double
    }

    struct ProductBoost: Equatable, Identifiable {
        let product: Product
        let nutrient: Nutrient
        let annualProductMassKg: Double
        var id: String { product.rawValue }
    }

    struct ProductAllocation: Equatable, Identifiable {
        let product: Product
        let nutrient: Nutrient
        let annualNutrientBoostKg: Double
        let annualProductMassKg: Double
        let annualProductMassKgPerPalm: Double
        var id: String { product.rawValue }
    }

    struct Nutrient: Equatable, Hashable, RawRepresentable {
        let rawValue: String
        init(rawValue: String) { self.rawValue = rawValue }

        static let nitrogen = Self(rawValue: "N")
        static let magnesium = Self(rawValue: "Mg")
        static let phosphorus = Self(rawValue: "P")
        static let potassium = Self(rawValue: "K")
        static let calcium = Self(rawValue: "Ca")
        static let sulfur = Self(rawValue: "S")
    }

    /// Keep source identifiers intact so product names can be localized or decorated
    /// independently by the presentation layer.
    struct Product: Equatable, Hashable, RawRepresentable {
        let rawValue: String
        init(rawValue: String) { self.rawValue = rawValue }
    }
}
