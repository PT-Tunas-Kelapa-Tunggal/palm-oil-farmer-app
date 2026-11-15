import CloudKit
import Foundation

public final class CloudKitFarmerReviewRepository: FarmerReviewRepository, @unchecked Sendable {
    private let containerIdentifier: String
    private let database: CKDatabase
    private let domainMapper = PlantationDomainMapper()

    public init(database: CKDatabase? = nil, containerIdentifier: String) {
        self.containerIdentifier = containerIdentifier
        if let database {
            self.database = database
        } else {
            let container = CKContainer(identifier: containerIdentifier)
            self.database = container.publicCloudDatabase
        }
    }

    public func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest {
        let dto = try domainMapper.toDTO(from: request)
        let record = PlantationRecordCKAdapter.toCKRecord(from: dto)
        let savedRecord = try await database.save(record)
        let savedDTO = try PlantationRecordCKAdapter.toDTO(from: savedRecord)
        return try domainMapper.toDomain(from: savedDTO)
    }

    public func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? {
        let recordID = CKRecord.ID(recordName: gardenID.uuidString)
        do {
            let record = try await database.record(for: recordID)
            let reader = ScanRequestRecord(record)
            return domainMapper.toDomain(from: reader, gardenID: gardenID)
        } catch let error as CKError where error.code == .unknownItem {
            return try await fetchLegacyRequest(for: gardenID)
        } catch {
            if let legacy = try? await fetchLegacyRequest(for: gardenID) {
                return legacy
            }
            throw error
        }
    }

    private func fetchLegacyRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? {
        do {
            let predicate = NSPredicate(format: "%K == %@", PlantationRecordCKAdapter.Field.gardenID, gardenID.uuidString)
            let query = CKQuery(recordType: PlantationRecordCKAdapter.recordType, predicate: predicate)
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let (matchResults, _) = try await database.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1)
            guard let firstResult = matchResults.first else { return nil }
            let record = try firstResult.1.get()
            let dto = try PlantationRecordCKAdapter.toDTO(from: record)
            return try domainMapper.toDomain(from: dto)
        } catch {
            return nil
        }
    }

    public func fetchMyRequests() async throws -> [PlantationReviewRequest] {
        let query = CKQuery(recordType: RecordKeys.recordType, predicate: NSPredicate(value: true))

        let (firstPage, firstCursor) = try await database.records(
            matching: query,
            inZoneWith: nil,
            desiredKeys: nil,
            resultsLimit: 100
        )

        var records = firstPage
        var cursor = firstCursor
        while let nextCursor = cursor {
            let (nextPage, nextCursor) = try await database.records(
                continuingMatchFrom: nextCursor,
                desiredKeys: nil,
                resultsLimit: 100
            )
            records.append(contentsOf: nextPage)
            cursor = nextCursor
        }

        return records.compactMap { result in
            guard let record = try? result.1.get() else { return nil }

            // Current records use the shared CloudKit contract. Older app records
            // may also have UUID record names, so identify them by their fields first.
            if record[RecordKeys.iOSOwned.farmName] != nil,
               let requestID = UUID(uuidString: record.recordID.recordName) {
                return domainMapper.toDomain(from: ScanRequestRecord(record), gardenID: requestID)
            }
            if let dto = try? PlantationRecordCKAdapter.toDTO(from: record),
               let request = try? domainMapper.toDomain(from: dto) {
                return request
            }
            guard let requestID = UUID(uuidString: record.recordID.recordName) else { return nil }
            return domainMapper.toDomain(from: ScanRequestRecord(record), gardenID: requestID)
        }
    }

    /// Fetches all submitted requests mapped to Garden domain models for display.
    func fetchMyGardens() async throws -> [Garden] {
        let requests = try await fetchMyRequests()
        return requests.map { domainMapper.toGarden(from: $0) }
    }

    /// Fetches a specific garden's latest submitted review state from CloudKit.
    func fetchGarden(for gardenID: UUID) async throws -> Garden? {
        guard let request = try await fetchRequest(for: gardenID) else { return nil }
        return domainMapper.toGarden(from: request)
    }

    public func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    if let latest = try? await self.fetchRequest(for: gardenID) {
                        continuation.yield(latest)
                        if latest.status == .completed {
                            continuation.finish()
                            return
                        }
                    }
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // Poll every 5s
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
