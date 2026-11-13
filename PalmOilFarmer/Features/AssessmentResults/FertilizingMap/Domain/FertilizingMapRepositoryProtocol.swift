import Foundation

public protocol FertilizingMapRepositoryProtocol: Sendable {
    func fetchMap(for gardenId: String) async throws -> FertilizingMapItem
    func selectFertilizer(fertilizerId: String, for gardenId: String) async throws -> FertilizingMapItem
    func markAsFertilized(for gardenId: String, isDone: Bool) async throws -> FertilizingMapItem
}

public struct DummyFertilizingMapRepository: FertilizingMapRepositoryProtocol {
    public init() {}

    public func fetchMap(for gardenId: String) async throws -> FertilizingMapItem {
        let dolomit = FertilizerPeriodOption(
            id: "dolomit",
            name: "Dolomit",
            timingSubtitle: "Awal periode",
            totalDose: "400 kg",
            perTreeDose: "3,5 kg",
            defaultDivision: .perZona
        )
        let npk = FertilizerPeriodOption(
            id: "npk",
            name: "NPK 15-15-15",
            timingSubtitle: "14 hari setelah Dolomit",
            totalDose: "120 kg",
            perTreeDose: "0,5 kg",
            defaultDivision: .wholeFarm
        )
        let urea = FertilizerPeriodOption(
            id: "urea",
            name: "Urea",
            timingSubtitle: "Pemupukan 1, Januari–Februari 2027",
            totalDose: "100 kg",
            perTreeDose: "1,5 kg",
            defaultDivision: .perZona
        )

        let mapFixture = await DummyFarmGreenIndexFixture.makeItem()
        let orthomosaic = mapFixture.orthomosaic
        let sampleZones = (orthomosaic?.zones ?? []).map { zone in
            let minX = zone.boundingBox.map(\.x).min() ?? 0
            let maxX = zone.boundingBox.map(\.x).max() ?? 0
            let minY = zone.boundingBox.map(\.y).min() ?? 0
            let maxY = zone.boundingBox.map(\.y).max() ?? 0
            let width = Double(max(orthomosaic?.imagePixelWidth ?? 1, 1))
            let height = Double(max(orthomosaic?.imagePixelHeight ?? 1, 1))
            let doseKg = zone.id <= 2 ? 25.0 : 32.0
            return FertilizingZoneDetail(
                id: Int(zone.id),
                name: "Zona \(zone.id)",
                doseKg: doseKg,
                relativeX: CGFloat((minX + maxX) / 2 / width),
                relativeY: CGFloat((minY + maxY) / 2 / height)
            )
        }

        return FertilizingMapItem(
            gardenId: gardenId,
            gardenName: "Kebun Kelapa Sawit",
            selectedFertilizer: dolomit,
            availableFertilizers: [dolomit, npk, urea],
            zones: sampleZones,
            isMarkedDone: false,
            orthomosaic: orthomosaic
        )
    }

    public func selectFertilizer(fertilizerId: String, for gardenId: String) async throws -> FertilizingMapItem {
        var item = try await fetchMap(for: gardenId)
        if let match = item.availableFertilizers.first(where: { $0.id == fertilizerId }) {
            item.selectedFertilizer = match
        }
        return item
    }

    public func markAsFertilized(for gardenId: String, isDone: Bool) async throws -> FertilizingMapItem {
        var item = try await fetchMap(for: gardenId)
        item.isMarkedDone = isDone
        return item
    }
}
