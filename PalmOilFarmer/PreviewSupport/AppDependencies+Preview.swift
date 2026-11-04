#if DEBUG
import Foundation

extension AppDependencies {
    static func preview() -> AppDependencies {
        AppDependencies(
            modelContainer: AppConfiguration.makeModelContainer(inMemory: true),
            reviewRepository: PreviewFarmerReviewRepository(),
            registrationServices: {
                GardenRegistrationServices(locations: PreviewLocationRepository(), photos: PreviewPhotoRepository())
            },
            mappingAuthorization: { PreviewMappingAuthorization() }
        )
    }
}

private struct PreviewMappingAuthorization: GardenLocationAuthorizing {
    func requestAuthorization() {}
}

private struct PreviewLocationRepository: GardenLocationRepository {
    func search(_ query: String) async throws -> [GardenLocation] { [] }
    func currentLocation() async throws -> GardenLocation { throw ReviewServiceError.unavailable }
}

private struct PreviewPhotoRepository: GardenPhotoRepository {
    func loadPhotos() async -> GardenPhotoLibrarySnapshot {
        GardenPhotoLibrarySnapshot(access: .allowed, photos: [])
    }
    func thumbnails(for photoID: String) -> AsyncStream<Data> { AsyncStream { $0.finish() } }
}

private struct PreviewFarmerReviewRepository: FarmerReviewRepository {
    func submitRequest(_ request: PlantationReviewRequest) async throws -> PlantationReviewRequest {
        throw ReviewServiceError.unavailable
    }

    func fetchRequest(for gardenID: UUID) async throws -> PlantationReviewRequest? { nil }
    func fetchMyRequests() async throws -> [PlantationReviewRequest] { [] }

    nonisolated func observeRequestUpdates(for gardenID: UUID) -> AsyncStream<PlantationReviewRequest> {
        AsyncStream { $0.finish() }
    }
}
#endif
