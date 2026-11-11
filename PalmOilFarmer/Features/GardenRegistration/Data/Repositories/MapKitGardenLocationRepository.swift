import CoreLocation
import Foundation

/// (2) Real repository: MapKit search + device GPS, mapped by `GardenLocationMapper`.
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

    func location(at coordinate: GardenCoordinate) async -> GardenLocation {
        await LocationSearchService.location(
            at: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        )
    }
}
