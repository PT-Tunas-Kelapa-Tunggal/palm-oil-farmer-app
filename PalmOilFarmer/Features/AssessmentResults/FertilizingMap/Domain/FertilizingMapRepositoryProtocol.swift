import Foundation

public protocol FertilizingMapRepositoryProtocol: Sendable {
    func fetchMap(for gardenId: String) async throws -> FertilizingMapItem
    func selectFertilizer(fertilizerId: String, for gardenId: String) async throws -> FertilizingMapItem
    func markAsFertilized(for gardenId: String, isDone: Bool) async throws -> FertilizingMapItem
}

public struct DummyFertilizingMapRepository: FertilizingMapRepositoryProtocol {
    public init() {}

    public func fetchMap(for gardenId: String) async throws -> FertilizingMapItem {
        await makeMap(for: gardenId, selectedFertilizerID: "dolomit", isMarkedDone: false)
    }

    public func selectFertilizer(fertilizerId: String, for gardenId: String) async throws -> FertilizingMapItem {
        await makeMap(for: gardenId, selectedFertilizerID: fertilizerId, isMarkedDone: false)
    }

    public func markAsFertilized(for gardenId: String, isDone: Bool) async throws -> FertilizingMapItem {
        await makeMap(for: gardenId, selectedFertilizerID: "dolomit", isMarkedDone: isDone)
    }

    private func makeMap(
        for gardenId: String,
        selectedFertilizerID: String,
        isMarkedDone: Bool
    ) async -> FertilizingMapItem {
        let fixture = FertilizerMapAnalysisFixture.load()
        let fertilizerOptions = fixture?.fertilizers ?? Self.fallbackFertilizers
        let selectedFertilizer = fertilizerOptions.first(where: { $0.id == selectedFertilizerID })
            ?? fertilizerOptions[0]
        let mapFixture = DummyFarmGreenIndexFixture.makeItem()
        let orthomosaic = mapFixture.orthomosaic
        let doseByZone = fixture?.zoneDoses(for: selectedFertilizer.id)
            ?? Dictionary(uniqueKeysWithValues: (orthomosaic?.zones ?? []).map { (Int($0.id), $0.id <= 2 ? 25.0 : 32.0) })
        let zones = (orthomosaic?.zones ?? []).map { zone in
            let minX = zone.boundingBox.map(\.x).min() ?? 0
            let maxX = zone.boundingBox.map(\.x).max() ?? 0
            let minY = zone.boundingBox.map(\.y).min() ?? 0
            let maxY = zone.boundingBox.map(\.y).max() ?? 0
            let width = Double(max(orthomosaic?.imagePixelWidth ?? 1, 1))
            let height = Double(max(orthomosaic?.imagePixelHeight ?? 1, 1))
            return FertilizingZoneDetail(
                id: Int(zone.id),
                name: "Zona \(zone.id)",
                doseKg: doseByZone[Int(zone.id)] ?? 0,
                relativeX: CGFloat((minX + maxX) / 2 / width),
                relativeY: CGFloat((minY + maxY) / 2 / height)
            )
        }

        return FertilizingMapItem(
            gardenId: gardenId,
            gardenName: mapFixture.gardenName,
            selectedFertilizer: selectedFertilizer,
            availableFertilizers: fertilizerOptions,
            zones: zones,
            isMarkedDone: isMarkedDone,
            orthomosaic: orthomosaic
        )
    }

    private static let fallbackFertilizers = [
        FertilizerPeriodOption(id: "dolomit", name: "Dolomit", timingSubtitle: "Awal periode", totalDose: "400 kg", perTreeDose: "3,5 kg", defaultDivision: .perZona),
        FertilizerPeriodOption(id: "npk", name: "NPK 15-15-15", timingSubtitle: "14 hari setelah Dolomit", totalDose: "120 kg", perTreeDose: "0,5 kg", defaultDivision: .wholeFarm),
        FertilizerPeriodOption(id: "urea", name: "Urea", timingSubtitle: "Pemupukan 1, Januari–Februari 2027", totalDose: "100 kg", perTreeDose: "1,5 kg", defaultDivision: .perZona)
    ]
}

/// Reads fertilizer amounts from the analysis JSON bundled alongside the map fixture.
private struct FertilizerMapAnalysisFixture {
    private let doses: [String: [Int: Double]]
    let fertilizers: [FertilizerPeriodOption]

    static func load() -> FertilizerMapAnalysisFixture? {
        guard let url = Bundle.main.url(forResource: "oil_palm_zones_vari", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let zones = root["zones"] as? [[String: Any]],
              let totalTrees = (root["metadata"] as? [String: Any])?["detected_tree_count"] as? Int,
              totalTrees > 0 else { return nil }

        let productIDs = [
            "dolomit": "dolomite_Mg_cheaper",
            "urea": "urea_N_expensive"
        ]
        var zoneDoses = [String: [Int: Double]]()
        for (fertilizerID, productID) in productIDs {
            for entry in root["fertilizer_product_bag_estimates"] as? [[String: Any]] ?? [] {
                guard entry["product"] as? String == productID,
                      let zoneID = entry["zone_id"] as? Int,
                      let amount = entry["base_plus_supplement_product_kg_per_zone_per_year"] as? Double else { continue }
                zoneDoses[fertilizerID, default: [:]][zoneID] = amount
            }
        }

        // The NPK baseline expresses dose per palm and application; multiply by its
        // annual application count and each zone's detected-tree count.
        let comparison = (root["combined_fertilizer_calculations"] as? [String: Any])?["field_wide_npk_baseline_comparison"] as? [String: Any]
        let blend = comparison?["user_blend"] as? [String: Any]
        let npkTotal = blend?["npk_product_kg_farm_per_year"] as? Double ?? 0
        let npkPerTree = npkTotal / Double(totalTrees)
        zoneDoses["npk"] = Dictionary(uniqueKeysWithValues: zones.compactMap { zone in
            guard let id = zone["zone_id"] as? Int,
                  let treeCount = zone["tree_count"] as? Int else { return nil }
            return (id, npkPerTree * Double(treeCount))
        })

        let totals = [
            "dolomit": zoneDoses["dolomit", default: [:]].values.reduce(0, +),
            "npk": npkTotal,
            "urea": zoneDoses["urea", default: [:]].values.reduce(0, +)
        ]
        let perTree = ["dolomit": totals["dolomit", default: 0] / Double(totalTrees), "npk": npkPerTree, "urea": totals["urea", default: 0] / Double(totalTrees)]
        let format: (Double) -> String = { value in
            "\(value.formatted(.number.precision(.fractionLength(0...1)))) kg"
        }
        let options = [
            FertilizerPeriodOption(id: "dolomit", name: "Dolomit", timingSubtitle: "Awal periode", totalDose: format(totals["dolomit", default: 0]), perTreeDose: format(perTree["dolomit", default: 0]), defaultDivision: .perZona),
            FertilizerPeriodOption(id: "npk", name: "NPK 15-15-15", timingSubtitle: "14 hari setelah Dolomit", totalDose: format(npkTotal), perTreeDose: format(npkPerTree), defaultDivision: .wholeFarm),
            FertilizerPeriodOption(id: "urea", name: "Urea", timingSubtitle: "Pemupukan 1, Januari–Februari 2027", totalDose: format(totals["urea", default: 0]), perTreeDose: format(perTree["urea", default: 0]), defaultDivision: .perZona)
        ]
        return FertilizerMapAnalysisFixture(doses: zoneDoses, fertilizers: options)
    }

    func zoneDoses(for fertilizerID: String) -> [Int: Double] {
        doses[fertilizerID] ?? [:]
    }
}
