import Foundation

@MainActor
final class MapKitGardenLocationRepository: GardenLocationRepository {
    func search(_ query: String) async throws -> [GardenLocation] {
        try await LocationSearchService.search(query)
    }

    func currentLocation() async throws -> GardenLocation {
        let provider = CurrentLocationProvider()
        let coordinate = try await provider.coordinate()
        try Task.checkCancellation()
        var location = await LocationSearchService.location(at: coordinate)
        location.source = .currentLocation
        try Task.checkCancellation()
        return location
    }
}
