import CloudKit
import CoreLocation
import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct CloudKitReviewTests {
    @Test func submissionUsesTheOperatorRecordContract() async throws {
        let garden = garden()
        let repository = ReviewRepositorySpy()
        let service = ReviewService.cloudKit(repository: repository)
        let review = try await service.submit(garden,
            ReviewContactDetails(name: "Petani Uji", phone: "081234567890", address: "Desa Uji"))
        let request = try #require(repository.submittedRequest)
        let dto = try PlantationDomainMapper().toDTO(from: request)
        let record = PlantationRecordCKAdapter.toCKRecord(from: dto)

        #expect(record.recordType == "PlantationScanRequest")
        #expect(record.recordID.recordName == review.requestID)
        #expect(record["gardenID"] as? String == garden.id.uuidString)
        #expect(record["farmerName"] as? String == "Petani Uji")
        #expect(record["farmerPhone"] as? String == "081234567890")
        #expect(record["farmerAddress"] as? String == "Desa Uji")
        #expect(record["gardenName"] as? String == garden.name)
        #expect(record["locationName"] as? String == garden.locationName)
        #expect(record["areaHectares"] as? Double == garden.boundary.areaHectares)
        #expect(record["statusCode"] as? Int == 0)
        #expect(record["submittedAt"] as? Date == request.timeline.submittedAt)
        #expect(record["resultJSON"] == nil)
        #expect(record["orthomosaicAsset"] == nil)

        let boundary = try JSONDecoder().decode([CoordinatePointDTO].self, from: Data(dto.boundaryJSON.utf8))
        #expect(boundary.count == garden.boundary.points.count)
        #expect(boundary.first?.lat == 1.1)
        #expect(boundary.first?.lon == 104.4)
        let agronomy = try JSONDecoder().decode(AgronomicProfileDTO.self, from: Data(dto.agronomicJSON.utf8))
        #expect(agronomy.year == 2016)
        #expect(agronomy.month == 7)
        #expect(agronomy.soil == "Gambut")
        #expect(agronomy.fertilizers.first?.id == garden.fertilizerRecords?.first?.id.uuidString)
        #expect(agronomy.fertilizers.first?.bagKg == 50)
        #expect(agronomy.fertilizers.first?.bags == 4)
        #expect(agronomy.fertilizers.first?.dosePerTree == 2.5)
        #expect(agronomy.harvest?.freq == 2)
        #expect(agronomy.harvest?.weightKg == 800)
        #expect(review.status == .submitted)
        #expect(review.report == nil)
        #expect(review.isLocalSimulation != true)
    }

    @Test func operatorResultIsReadAndPersistedWithTheGarden() async throws {
        let garden = garden()
        let record = operatorRecord(for: garden.id)
        let request = try PlantationDomainMapper().toDomain(from: PlantationRecordCKAdapter.toDTO(from: record))
        let repository = ReviewRepositorySpy()
        repository.fetchedRequest = request
        let review = try #require(try await ReviewService.cloudKit(repository: repository).refresh(garden))

        #expect(repository.fetchedGardenID == garden.id)
        #expect(review.requestID == record.recordID.recordName)
        #expect(review.status == .completed)
        #expect(review.entries.filter(\.isReached).count == 4)
        #expect(review.report?.nutrients.first?.current == 0.4)
        #expect(review.report?.nutrients.first?.target == 0.8)
        #expect(review.report?.totalCost == "Rp 500.000")
        #expect(review.report?.areas.first?.id == "AA")
        #expect(review.report?.areas.first?.periods.first?.lines.first?.dosage == "2 kg/pohon")

        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "gardens.json")
        let store = GardenStore(fileURL: url)
        #expect(store.add(garden))
        #expect(store.updateReview(review, for: garden.id))
        let reopened = try #require(GardenStore(fileURL: url).gardens.first)
        #expect(reopened.review?.requestID == review.requestID)
        #expect(reopened.review?.report?.totalCost == "Rp 500.000")
        #expect(reopened.harvestRecord?.latestWeightKg == 800)
    }

    @Test func unfinishedOperatorReviewDoesNotCreateASampleReport() async throws {
        let garden = garden()
        let record = operatorRecord(for: garden.id)
        record["statusCode"] = 1 as CKRecordValue
        record["resultJSON"] = nil
        record["completedAt"] = nil
        let request = try PlantationDomainMapper().toDomain(from: PlantationRecordCKAdapter.toDTO(from: record))
        let repository = ReviewRepositorySpy()
        repository.fetchedRequest = request
        let review = try #require(try await ReviewService.cloudKit(repository: repository).refresh(garden))
        #expect(review.status == .scheduled)
        #expect(review.entries.filter(\.isReached).count == 2)
        #expect(review.report == nil)
        #expect(review.isLocalSimulation != true)
    }

    @Test func noRemoteReviewReturnsNil() async throws {
        let repository = ReviewRepositorySpy()
        let review = try await ReviewService.cloudKit(repository: repository).refresh(garden())
        #expect(review == nil)
    }

    @Test func cloudKitFailureRemainsAFailure() async {
        let repository = ReviewRepositorySpy()
        repository.error = CKError(.networkUnavailable)
        let service = ReviewService.cloudKit(repository: repository)
        do {
            _ = try await service.submit(garden(), ReviewContactDetails(name: "Uji", phone: "081234567890", address: "Uji"))
            Issue.record("A CloudKit failure must not become a simulated successful submission.")
        } catch {
            #expect((error as? CKError)?.code == .networkUnavailable)
        }
        do {
            _ = try await service.refresh(garden())
            Issue.record("A failed refresh must not be treated as an empty server response.")
        } catch {
            #expect((error as? CKError)?.code == .networkUnavailable)
        }
    }

    private func garden() -> Garden {
        Garden(id: UUID(), name: "Kebun Uji", locationName: "Bintan",
            boundary: GardenBoundary(points: [
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1.1, longitude: 104.4)),
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1.1, longitude: 104.401)),
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1.101, longitude: 104.401)),
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1.101, longitude: 104.4))
            ]), plantingYear: 2016, soilType: .peat, plantingMonth: 7,
            fertilizerRecords: [FertilizerRecord(name: "NPK", bagWeightKg: 50, bagCount: 4, doseKgPerTree: 2.5)],
            harvestRecord: HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 800))
    }

    // A record written with the existing operator field names and JSON, independent of the app encoder.
    private func operatorRecord(for gardenID: UUID) -> CKRecord {
        let record = CKRecord(recordType: "PlantationScanRequest", recordID: CKRecord.ID(recordName: UUID().uuidString))
        let fields: [String: CKRecordValue] = [
            "farmerName": "Petani Uji" as CKRecordValue,
            "farmerPhone": "081234567890" as CKRecordValue,
            "farmerAddress": "Desa Uji" as CKRecordValue,
            "gardenID": gardenID.uuidString as CKRecordValue,
            "gardenName": "Kebun Uji" as CKRecordValue,
            "locationName": "Bintan" as CKRecordValue,
            "areaHectares": 1.2 as CKRecordValue,
            "boundaryJSON": #"[{"lat":1.1,"lon":104.4},{"lat":1.1,"lon":104.401},{"lat":1.101,"lon":104.401}]"# as CKRecordValue,
            "agronomicJSON": #"{"year":2016,"month":7,"soil":"Gambut","fertilizers":[],"harvest":{"freq":2,"weightKg":800}}"# as CKRecordValue,
            "statusCode": 3 as CKRecordValue,
            "submittedAt": Date(timeIntervalSinceReferenceDate: 800_000_000) as CKRecordValue,
            "scheduledFor": Date(timeIntervalSinceReferenceDate: 800_086_400) as CKRecordValue,
            "inReviewAt": Date(timeIntervalSinceReferenceDate: 800_172_800) as CKRecordValue,
            "completedAt": Date(timeIntervalSinceReferenceDate: 800_259_200) as CKRecordValue,
            "operatorNotes": "Selesai diperiksa" as CKRecordValue,
            "resultJSON": #"{"completedAt":800259200,"nutrients":[{"name":"N","current":0.4,"target":0.8}],"costs":[{"name":"NPK","quantity":"100 kg","cost":"Rp 500.000"}],"totalCostFormatted":"Rp 500.000","areas":[{"areaID":"AA","periods":[{"title":"Periode 1","dateRange":"November 2026","lines":[{"name":"NPK","total":"100 kg","dosage":"2 kg/pohon"}]}]}]}"# as CKRecordValue
        ]
        for (key, value) in fields { record[key] = value }
        return record
    }
}

@MainActor
private final class ReviewRepositorySpy: FarmerReviewRepository {
    var submittedRequest: PlantationReviewRequest?
    var fetchedGardenID: UUID?
    var fetchedRequest: PlantationReviewRequest?
    var error: Error?

    func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest {
        if let error { throw error }
        submittedRequest = request
        return request
    }

    func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? {
        if let error { throw error }
        fetchedGardenID = gardenID
        return fetchedRequest
    }

    func fetchMyRequests() async throws -> [PlantationReviewRequest] { [] }
    func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest> {
        AsyncStream { $0.finish() }
    }
}
