import Foundation
import Combine

@MainActor
final class FertilizerRecommendationsResultViewModel: ObservableObject {
    struct ProductRow: Identifiable {
        let id: String
        let title: String
        let nutrient: String
        let zoneMass: String
        let perPalmMass: String
    }

    struct ZoneRow: Identifiable {
        let id: String
        let treeCount: String
        let area: String
        let nutrientBoosts: [String]
        let products: [ProductRow]
    }

    @Published private(set) var farmTitle: String
    @Published private(set) var locationLabel: String
    @Published private(set) var summaryZoneCount: String
    @Published private(set) var summaryTreeCount: String
    @Published private(set) var annualNutrientBoosts: [String]
    @Published private(set) var annualProductBoosts: [ProductRow]
    @Published private(set) var zones: [ZoneRow]

    init(recommendation: FertilizerRecommendationsResult) {
        farmTitle = recommendation.farm.name
        locationLabel = recommendation.farm.locationLabel
        summaryZoneCount = Self.count(recommendation.annualSummary.zoneCount)
        summaryTreeCount = Self.count(recommendation.annualSummary.treeCount)
        annualNutrientBoosts = Self.nutrients(recommendation.annualSummary.nutrientBoostsKg)
        annualProductBoosts = recommendation.annualSummary.productBoosts.map {
            ProductRow(id: $0.id, title: Self.productName($0.product.rawValue),
                       nutrient: $0.nutrient.rawValue, zoneMass: Self.kilograms($0.annualProductMassKg),
                       perPalmMass: "")
        }
        zones = recommendation.zones.map { zone in
            ZoneRow(
                id: zone.id,
                treeCount: Self.count(zone.treeCount),
                area: "\(Self.number(zone.areaHectares)) ha",
                nutrientBoosts: Self.nutrients(zone.nutrientBoostsKg),
                products: zone.products.map {
                    ProductRow(id: "\(zone.id)-\($0.id)", title: Self.productName($0.product.rawValue),
                               nutrient: $0.nutrient.rawValue,
                               zoneMass: Self.kilograms($0.annualProductMassKg),
                               perPalmMass: Self.kilograms($0.annualProductMassKgPerPalm))
                }
            )
        }
    }

    private static func count(_ value: Int) -> String {
        value.formatted(.number)
    }

    private static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    private static func kilograms(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...3)))) kg"
    }

    private static func nutrients(_ values: [FertilizerRecommendationsResult.Nutrient: Double]) -> [String] {
        values.keys.sorted { $0.rawValue < $1.rawValue }.map { nutrient in
            "\(nutrient.rawValue): \(kilograms(values[nutrient] ?? 0))"
        }
    }

    private static func productName(_ identifier: String) -> String {
        identifier.replacingOccurrences(of: "_", with: " ")
    }
}
