import CloudKit
import Foundation

public final class CloudKitFarmerReviewRepository: FarmerReviewRepository, @unchecked Sendable {
    public static let shared = CloudKitFarmerReviewRepository()

    private let containerIdentifier: String
    private let database: CKDatabase
    private let domainMapper = PlantationDomainMapper()

    public init(database: CKDatabase? = nil, containerIdentifier: String = AppConfiguration.cloudKitContainerIdentifier) {
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
        let predicate = NSPredicate(format: "%K == %@", PlantationRecordCKAdapter.Field.gardenID, gardenID.uuidString)
        let query = CKQuery(recordType: PlantationRecordCKAdapter.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let (matchResults, _) = try await database.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 1)
        guard let firstResult = matchResults.first else { return nil }
        let record = try firstResult.1.get()
        let dto = try PlantationRecordCKAdapter.toDTO(from: record)
        return try domainMapper.toDomain(from: dto)
    }

    public func fetchMyRequests() async throws -> [PlantationReviewRequest] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: PlantationRecordCKAdapter.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let (matchResults, _) = try await database.records(matching: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: 50)
        var requests: [PlantationReviewRequest] = []
        for result in matchResults {
            if let record = try? result.1.get(),
               let dto = try? PlantationRecordCKAdapter.toDTO(from: record),
               let domain = try? domainMapper.toDomain(from: dto) {
                requests.append(domain)
            }
        }
        return requests
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
