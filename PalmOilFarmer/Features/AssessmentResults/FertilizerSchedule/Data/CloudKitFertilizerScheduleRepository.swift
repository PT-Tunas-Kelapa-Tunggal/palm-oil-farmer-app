import CloudKit
import Foundation

/// Loads the schedule attached to a garden's shared `PlantationScanRequest` record.
final class CloudKitFertilizerScheduleRepository: FertilizerScheduleRepositoryProtocol, @unchecked Sendable {
    private let database: CKDatabase

    init(containerIdentifier: String) {
        database = CKContainer(identifier: containerIdentifier).publicCloudDatabase
    }

    func fetchSchedule(gardenID: UUID) async throws -> FertilizerSchedule {
        let recordID = CKRecord.ID(recordName: gardenID.uuidString)
        let record = try await database.record(for: recordID)
        let reader = ScanRequestRecord(record)
        let items = try reader.fertilizationScheduling().get()
        let savedNPK = await SavedNPKSelectionStore.shared.selection(for: gardenID.uuidString)
        let selectedNPKType = savedNPK.flatMap(ContractFertilizerType.init(rawValue:))
        let needsByType = Dictionary(grouping: reader.fertilizerNeedPerZone().or([]), by: \.fertilizerType)
        let treeCount = reader.treeIdentification().or([]).count
        let treesPerZone = reader.fertilizingZone().or([]).reduce(into: [Int64: Int64]()) { counts, zone in
            counts[zone.id] = zone.treeCount
        }
        // The recommendation is annual; each scheduled application shows its share of that total.
        let roundsByType = items.flatMap(\.fertilizers).reduce(into: [ContractFertilizerType: Int]()) { counts, fertilizer in
            let type = Self.displayedType(for: fertilizer.fertilizerType, selectedNPKType: selectedNPKType)
            counts[type, default: 0] += 1
        }

        let periods = items.map { period in
            let orderedFertilizers = period.fertilizers.sorted { $0.step < $1.step }
            return FertilizerPeriod(
                id: UUID(),
                sequence: period.order,
                startDate: period.startDate,
                endDate: period.endDate,
                steps: orderedFertilizers.enumerated().map { index, fertilizer in
                    let type = Self.displayedType(for: fertilizer.fertilizerType, selectedNPKType: selectedNPKType)
                    let quantityKg: Double
                    if let needs = needsByType[type], let rounds = roundsByType[type], rounds > 0 {
                        quantityKg = Self.annualAmount(needs, treeCount: treeCount, treesPerZone: treesPerZone)
                            / Double(rounds)
                    } else {
                        quantityKg = fertilizer.amountPerRoundKg
                    }
                    return FertilizerStep(
                        id: UUID(),
                        order: fertilizer.step,
                        name: type.rawValue,
                        quantityKg: quantityKg,
                        gapBefore: index == 0 ? nil : Self.gap(
                            after: orderedFertilizers[index - 1].fertilizerType,
                            before: fertilizer.fertilizerType
                        ),
                        givenDate: fertilizer.doneAt
                    )
                }
            )
        }

        return FertilizerSchedule(
            gardenName: record[RecordKeys.iOSOwned.farmName] as? String ?? "Kebun",
            locationName: record[RecordKeys.iOSOwned.farmAddress] as? String ?? "",
            periods: periods
        )
    }

    private static func isNPK(_ type: ContractFertilizerType) -> Bool {
        switch type {
        case .npk, .npk15_15_15, .npk12_6_22_3, .npk13_6_27_4, .npk13_8_27_4, .npk16_16_16:
            true
        default:
            false
        }
    }

    private static func displayedType(
        for type: ContractFertilizerType, selectedNPKType: ContractFertilizerType?
    ) -> ContractFertilizerType {
        isNPK(type) ? (selectedNPKType ?? type) : type
    }

    private static func gap(
        after previous: ContractFertilizerType, before next: ContractFertilizerType
    ) -> FertilizerGap? {
        if previous == .dolomite && isNPK(next) {
            return FertilizerGap(minDays: 14, maxDays: 14)
        }
        if isNPK(previous) && next == .urea {
            return FertilizerGap(minDays: 1, maxDays: 7)
        }
        return nil
    }

    private static func annualAmount(
        _ needs: [FertilizerNeedItem], treeCount: Int, treesPerZone: [Int64: Int64]
    ) -> Double {
        needs.reduce(0) { total, need in
            let unit = need.dosageUnit.lowercased()
            let isPerTree = unit.contains("pohon") || unit.contains("tree")
            let count = need.zoneId.flatMap { treesPerZone[$0] }.map(Double.init) ?? Double(treeCount)
            let multiplier = isPerTree ? max(count, 1) : 1
            return total + max(0, need.recommendedDosagePerZonePerYear) * multiplier
        }
    }
}
