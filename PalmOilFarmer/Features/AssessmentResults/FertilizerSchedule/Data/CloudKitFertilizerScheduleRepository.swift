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

        let periods = items.map { period in
            FertilizerPeriod(
                id: UUID(),
                sequence: period.order,
                startDate: period.startDate,
                endDate: period.endDate,
                steps: period.fertilizers.map { fertilizer in
                    FertilizerStep(
                        id: UUID(),
                        order: fertilizer.step,
                        name: Self.isNPK(fertilizer.fertilizerType)
                            ? (selectedNPKType?.rawValue ?? fertilizer.fertilizerType.rawValue)
                            : fertilizer.fertilizerType.rawValue,
                        quantityKg: fertilizer.amountPerRoundKg,
                        gapBefore: nil,
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
}
