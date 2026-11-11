import Foundation
import SwiftData
@testable import PalmOilFarmer

@MainActor
func makeTestGardenStore(
    in container: ModelContainer,
    repository: (any FarmerReviewRepository)? = nil
) -> GardenStore {
    AppDependencies(
        modelContainer: container,
        reviewRepository: repository ?? ReviewRepositoryStub(),
        registrationServices: makeTestRegistrationServices,
        mappingAuthorization: makeTestMappingAuthorization
    ).gardenStore
}

@MainActor
func makeTestMappingAuthorization() -> any GardenLocationAuthorizing { MappingAuthorizationStub() }

@MainActor
final class MappingAuthorizationStub: GardenLocationAuthorizing {
    var requestCount = 0
    func requestAuthorization() { requestCount += 1 }
}

@MainActor
func makeTestRegistrationServices() -> GardenRegistrationServices {
    GardenRegistrationServices(locations: LocationRepositoryStub(), photos: PhotoRepositoryStub())
}

@MainActor
final class LocationRepositoryStub: GardenLocationRepository {
    enum Failure: Error { case unavailable }
    var queries: [String] = []
    var searchResult: [GardenLocation] = []
    var searchError: Error?
    var currentResult: GardenLocation?
    var currentError: Error?
    var currentRequests = 0

    func search(_ query: String) async throws -> [GardenLocation] {
        queries.append(query)
        if let searchError { throw searchError }
        return searchResult
    }
    func currentLocation() async throws -> GardenLocation {
        currentRequests += 1
        if let currentError { throw currentError }
        guard let currentResult else { throw Failure.unavailable }
        return currentResult
    }
    func location(at coordinate: GardenCoordinate) async -> GardenLocation {
        GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun", coordinate: coordinate, source: .photo)
    }
}

@MainActor
final class PhotoRepositoryStub: GardenPhotoRepository {
    var snapshot = GardenPhotoLibrarySnapshot(access: .allowed, photos: [])
    var loadCount = 0
    var thumbnailIDs: [String] = []
    var thumbnailUpdates: [Data] = []

    func loadPhotos() async -> GardenPhotoLibrarySnapshot {
        loadCount += 1
        return snapshot
    }
    func thumbnails(for photoID: String) -> AsyncStream<Data> {
        thumbnailIDs.append(photoID)
        return AsyncStream { continuation in
            for data in thumbnailUpdates { continuation.yield(data) }
            continuation.finish()
        }
    }
}

@MainActor
struct ReviewRepositoryStub: FarmerReviewRepository {
    enum Failure: Error { case rejected }
    var requests: [PlantationReviewRequest] = []
    var rejectsSubmission = false

    func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest {
        if rejectsSubmission { throw Failure.rejected }
        return request
    }

    func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? {
        requests.first { $0.garden.id == gardenID }
    }

    func fetchMyRequests() async throws -> [PlantationReviewRequest] {
        requests
    }

    nonisolated func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest> {
        AsyncStream { $0.finish() }
    }
}
