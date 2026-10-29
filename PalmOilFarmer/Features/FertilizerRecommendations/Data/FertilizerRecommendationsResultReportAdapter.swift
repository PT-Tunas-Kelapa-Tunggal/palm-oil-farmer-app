import Foundation

enum FertilizerRecommendationsResultReportAdapter {
    /// Adapts the JSON-backed domain result to the existing recommendation screen model.
    /// The source payload has annual allocations, but no soil projection or prices.
    static func makeReport(
        from result: FertilizerRecommendationsResult,
        for garden: Garden
    ) -> FertilizerRecommendationReport {
        let localGeometry = FertilizerRecommendationReport.local(for: garden)
        let supplementalNutrientComparison = supplementalProjections(from: garden, result: result)
        let nutrientComparison = result.recommendedNPKMg.flatMap { recommendation -> [NutrientProjection]? in
            guard let history = historyCompositionPerBag(
                from: garden,
                comparisonBagWeightKg: recommendation.comparisonBasisBagWeightKg
            ) else { return nil }
            let recommended = recommendation.composition.elementalAmounts(
                forBagWeightKg: recommendation.comparisonBasisBagWeightKg
            )
            let nutrients: [(String, Double, Double)] = [
                ("N", history.nitrogenKg, recommended.nitrogenKg),
                ("P", history.phosphorusKg, recommended.phosphorusKg),
                ("K", history.potassiumKg, recommended.potassiumKg),
                ("Mg", history.magnesiumKg, recommended.magnesiumKg)
            ]
            return nutrients.compactMap { item in
                let (name, current, target) = item
                guard target > 0 else { return nil }
                let ratio = current / target
                let status: String
                if ratio > 1.05 {
                    status = "Berlebih"
                } else if ratio < 0.5 {
                    status = "Sangat kurang"
                } else if ratio < 0.95 {
                    status = "Kurang"
                } else {
                    status = "Sesuai"
                }
                let displayStatus = name == "Mg" && status == "Sangat kurang"
                    ? "Sangat kurang\n(opsional)"
                    : status
                return NutrientProjection(name: name, current: ratio, target: 1, requirement: 1,
                                          status: displayStatus)
            }
        } ?? []
        let areas = result.zones.map { zone in
            let lines = zone.products.map { product in
                FertilizerAllocationLine(
                    name: product.product.rawValue.replacingOccurrences(of: "_", with: " "),
                    total: "\(kilograms(product.annualProductMassKg)) per area / tahun",
                    dosage: "\(kilograms(product.annualProductMassKgPerPalm)) / pohon / tahun"
                )
            }
            return FertilizerAllocationArea(
                id: zone.id,
                mapImage: nil,
                periods: [FertilizerAllocationPeriod(
                    title: "Alokasi tahunan · Area \(zone.id)",
                    dateRange: "\(zone.areaHectares.formatted(.number.precision(.fractionLength(0...2)))) ha · \(zone.treeCount) pohon",
                    lines: lines
                )],
                mapPoint: zone.centerPoint.map {
                    FertilizerMapPoint(x: $0.normalizedX, y: $0.normalizedY)
                }
            )
        }

        return FertilizerRecommendationReport(
            gardenName: garden.name,
            locationName: result.farm.locationLabel,
            boundary: garden.boundary,
            outline: localGeometry.outline,
            nutrients: nutrientComparison,
            costs: [],
            totalCost: "",
            areas: areas,
            nutrientSummary: result.compoundNPKInsight ?? result.nutrientComparisonInsight ?? result.recommendedNPKMg.map {
                "Perbandingan hara elemental per \(formatWeight($0.comparisonBasisBagWeightKg)) kg: NPK riwayat dibanding \($0.name). P, K, dan Mg dihitung dari P₂O₅, K₂O, dan MgO."
            },
            singleFertilizerSummary: result.singleFertilizerInsight,
            supplementalNutrientProjections: supplementalNutrientComparison,
            nutrientMapImageName: result.zoneImage,
            nutrientChartTitle: result.recommendedNPKMg.map { _ in "Komposisi NPK dibanding rekomendasi" },
            nutrientChartEyebrow: result.recommendedNPKMg.map { _ in "Komposisi pupuk majemuk (NPK) · per 50 kg" },
            nutrientChartCaption: result.recommendedNPKMg.map { _ in "Grafik ini membandingkan komposisi NPK pada label dengan formula rekomendasi." },
            currentNutrientLabel: "NPK riwayat",
            targetNutrientLabel: "Rekomendasi NPKMg",
            nutrientRequirementLabel: "Patokan"
        )
    }

    private static func historyCompositionPerBag(
        from garden: Garden,
        comparisonBagWeightKg: Double
    ) -> ElementalNutrientAmounts? {
        let records = (garden.fertilizerRecords ?? []).compactMap { record -> (ElementalNutrientAmounts, Double)? in
            guard FertilizerCatalogue.supplementalNutrients[record.name] == nil else { return nil }
            guard let composition = record.npkComposition ?? FertilizerCatalogue.presetCompositions[record.name],
                  record.bagWeightKg.isFinite, record.bagWeightKg > 0,
                  record.bagCount > 0 else { return nil }
            let purchasedMass = record.bagWeightKg * Double(record.bagCount)
            let amounts = composition.elementalAmounts(forBagWeightKg: comparisonBagWeightKg)
            return (amounts, purchasedMass)
        }
        guard !records.isEmpty else { return nil }

        // Compare each nutrient using only products that supply that nutrient. A Mg
        // amendment should raise Mg without diluting the N, P, or K values from NPK.
        func weightedAverage(_ value: (ElementalNutrientAmounts) -> Double) -> Double {
            let contributors = records.filter { value($0.0) > 0 }
            let contributorMass = contributors.reduce(0) { $0 + $1.1 }
            guard contributorMass > 0 else { return 0 }
            return contributors.reduce(0) { $0 + value($1.0) * $1.1 } / contributorMass
        }

        return ElementalNutrientAmounts(
            nitrogenKg: weightedAverage(\.nitrogenKg),
            phosphorusKg: weightedAverage(\.phosphorusKg),
            potassiumKg: weightedAverage(\.potassiumKg),
            magnesiumKg: weightedAverage(\.magnesiumKg)
        )
    }

    private static func supplementalProjections(
        from garden: Garden,
        result: FertilizerRecommendationsResult
    ) -> [NutrientProjection] {
        let treeCount = Double(result.annualSummary.treeCount)
        guard treeCount > 0 else { return [] }
        let records = garden.fertilizerRecords ?? []

        // Each JSON product allocation pairs its recommended product mass with the
        // nutrient boost it supplies. Use that ratio for matching products in history.
        let nutrientPerKgByProduct = FertilizerCatalogue.pulseCheckProductIDs.compactMap { product -> (String, Double)? in
            let allocations = result.zones.compactMap { zone in
                zone.products.first(where: { $0.product.rawValue == product.id })
            }
            let productMass = allocations.reduce(0) { $0 + $1.annualProductMassKg }
            let nutrientBoost = allocations.reduce(0) { $0 + $1.annualNutrientBoostKg }
            guard productMass > 0 else { return nil }
            return (product.name, nutrientBoost / productMass)
        }

        return [FertilizerRecommendationsResult.Nutrient.nitrogen, .magnesium].compactMap { nutrient in
            let targetPerTree = (result.annualSummary.nutrientBoostsKg[nutrient] ?? 0) / treeCount
            guard targetPerTree > 0 else { return nil }

            let productSources = nutrientPerKgByProduct.filter { source in
                guard let role = FertilizerCatalogue.supplementalNutrients[source.0] else { return false }
                switch (role, nutrient) {
                case (.nitrogen, .nitrogen), (.magnesium, .magnesium): return true
                default: return false
                }
            }
            let historyRecords = records.filter { record in
                productSources.contains(where: { $0.0 == record.name })
            }
            let actualPerTree = productSources.reduce(0.0) { total, source in
                let dosePerTree = historyRecords
                    .filter { $0.name == source.0 && $0.doseKgPerTree.isFinite && $0.doseKgPerTree > 0 }
                    .reduce(0) { $0 + $1.doseKgPerTree }
                return total + dosePerTree * source.1
            }
            let ratio = actualPerTree / targetPerTree
            let statusText = status(for: ratio)
            return NutrientProjection(name: nutrient.rawValue, current: ratio,
                                      currentAvailable: true, target: 1, requirement: 1,
                                      status: statusText)
        }
    }

    private static func status(for ratio: Double) -> String {
        if ratio > 1.05 { return "Berlebih" }
        if ratio < 0.5 { return "Sangat kurang" }
        if ratio < 0.95 { return "Kurang" }
        return "Sesuai"
    }

    private static func kilograms(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...3)))) kg"
    }

    private static func formatWeight(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

}
