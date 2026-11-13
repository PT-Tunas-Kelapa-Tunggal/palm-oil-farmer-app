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
                        name: fertilizer.fertilizerType.rawValue,
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
}
