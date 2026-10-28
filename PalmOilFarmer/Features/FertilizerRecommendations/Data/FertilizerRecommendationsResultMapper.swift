import Foundation

/// Decodes the pulse-check JSON contract and maps transport values into feature domain values.
enum FertilizerRecommendationsResultMapper {
    static func decode(_ data: Data) throws -> FertilizerRecommendationsResult {
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        return map(payload)
    }

    static func map(_ payload: Payload) -> FertilizerRecommendationsResult {
        FertilizerRecommendationsResult(
            farm: .init(
                name: payload.farm.name,
                locationLabel: payload.farm.locationLabel,
                sourceImage: payload.farm.sourceImage
            ),
            annualSummary: .init(
                zoneCount: payload.annualBoostSummary.zoneCount,
                treeCount: payload.annualBoostSummary.treeCount,
                nutrientBoostsKg: nutrientValues(payload.annualBoostSummary.elementalNutrientBoostKg),
                productBoosts: payload.annualBoostSummary.productMassBoostKgByProduct.map {
                    .init(product: .init(rawValue: $0.product), nutrient: .init(rawValue: $0.nutrient),
                          annualProductMassKg: $0.annualBoostProductMassKg)
                }
            ),
            zones: payload.areaAllocations.map { zone in
                .init(
                    id: zone.areaID,
                    treeCount: zone.treeCountForPerPalmCalculation,
                    areaHectares: zone.areaHa,
                    nutrientBoostsKg: nutrientValues(zone.annualNutrientBoostKgPerZone),
                    products: zone.annualProductBoostAllocations.map {
                        .init(product: .init(rawValue: $0.product), nutrient: .init(rawValue: $0.nutrient),
                              annualNutrientBoostKg: $0.annualNutrientBoostKgPerZone,
                              annualProductMassKg: $0.annualBoostProductMassKgPerZone,
                              annualProductMassKgPerPalm: $0.annualBoostProductMassKgPerPalm)
                    }
                )
            }
        )
    }

    private static func nutrientValues(_ values: [String: Double]) -> [FertilizerRecommendationsResult.Nutrient: Double] {
        Dictionary(uniqueKeysWithValues: values.map { (FertilizerRecommendationsResult.Nutrient(rawValue: $0.key), $0.value) })
    }

    // MARK: Payload DTOs

    struct Payload: Decodable {
        let farm: FarmDTO
        let annualBoostSummary: AnnualBoostSummaryDTO
        let areaAllocations: [AreaAllocationDTO]

        enum CodingKeys: String, CodingKey {
            case farm
            case annualBoostSummary = "annual_boost_summary"
            case areaAllocations = "area_allocations"
        }
    }

    struct FarmDTO: Decodable {
        let name: String
        let locationLabel: String
        let sourceImage: String
        enum CodingKeys: String, CodingKey {
            case name
            case locationLabel = "location_label"
            case sourceImage = "source_image"
        }
    }

    struct AnnualBoostSummaryDTO: Decodable {
        let zoneCount: Int
        let treeCount: Int
        let elementalNutrientBoostKg: [String: Double]
        let productMassBoostKgByProduct: [ProductBoostDTO]
        enum CodingKeys: String, CodingKey {
            case zoneCount = "zone_count"
            case treeCount = "tree_count"
            case elementalNutrientBoostKg = "elemental_nutrient_boost_kg"
            case productMassBoostKgByProduct = "product_mass_boost_kg_by_product"
        }
    }

    struct ProductBoostDTO: Decodable {
        let product: String
        let nutrient: String
        let annualBoostProductMassKg: Double
        enum CodingKeys: String, CodingKey {
            case product, nutrient
            case annualBoostProductMassKg = "annual_boost_product_mass_kg"
        }
    }

    struct AreaAllocationDTO: Decodable {
        let areaID: String
        let treeCountForPerPalmCalculation: Int
        let areaHa: Double
        let annualNutrientBoostKgPerZone: [String: Double]
        let annualProductBoostAllocations: [ProductAllocationDTO]
        enum CodingKeys: String, CodingKey {
            case areaID = "area_id"
            case treeCountForPerPalmCalculation = "tree_count_for_per_palm_calculation"
            case areaHa = "area_ha"
            case annualNutrientBoostKgPerZone = "annual_nutrient_boost_kg_per_zone"
            case annualProductBoostAllocations = "annual_product_boost_allocations"
        }
    }

    struct ProductAllocationDTO: Decodable {
        let product: String
        let nutrient: String
        let annualNutrientBoostKgPerZone: Double
        let annualBoostProductMassKgPerZone: Double
        let annualBoostProductMassKgPerPalm: Double
        enum CodingKeys: String, CodingKey {
            case product, nutrient
            case annualNutrientBoostKgPerZone = "annual_nutrient_boost_kg_per_zone"
            case annualBoostProductMassKgPerZone = "annual_boost_product_mass_kg_per_zone"
            case annualBoostProductMassKgPerPalm = "annual_boost_product_mass_kg_per_palm"
        }
    }
}
