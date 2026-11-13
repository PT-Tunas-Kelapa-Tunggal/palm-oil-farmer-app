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

        let sampleZones = [
            FertilizingZoneDetail(id: 1, name: "Zona 1", doseKg: 25, relativeX: 0.23, relativeY: 0.32),
            FertilizingZoneDetail(id: 2, name: "Zona 2", doseKg: 25, relativeX: 0.50, relativeY: 0.32),
            FertilizingZoneDetail(id: 3, name: "Zona 3", doseKg: 32, relativeX: 0.77, relativeY: 0.32),
            FertilizingZoneDetail(id: 4, name: "Zona 4", doseKg: 32, relativeX: 0.23, relativeY: 0.68),
            FertilizingZoneDetail(id: 5, name: "Zona 5", doseKg: 32, relativeX: 0.50, relativeY: 0.72),
            FertilizingZoneDetail(id: 6, name: "Zona 6", doseKg: 32, relativeX: 0.77, relativeY: 0.68)
        ]

        return FertilizingMapItem(
            gardenId: gardenId,
            gardenName: "Kebun Kelapa Sawit",
            selectedFertilizer: dolomit,
            availableFertilizers: [dolomit, npk, urea],
            zones: sampleZones,
            isMarkedDone: false
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
