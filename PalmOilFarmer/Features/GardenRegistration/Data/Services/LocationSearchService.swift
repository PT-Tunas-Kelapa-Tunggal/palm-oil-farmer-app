import MapKit

/// MapKit stays at the feature's data boundary. Raw `MKMapItem`s are turned into
/// `GardenLocation` by `GardenLocationMapper`.
enum LocationSearchService {
    @MainActor
    static func search(_ query: String) async throws -> [GardenLocation] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(query), Indonesia"
        request.resultTypes = [.address, .pointOfInterest]
        let response = try await MKLocalSearch(request: request).start()
        try Task.checkCancellation()
        return response.mapItems.map { GardenLocationMapper.location(from: $0, fallbackName: query) }
    }

    /// Names the device location so drafts read like a place. Falls back to a generic label offline.
    @MainActor
    static func location(at coordinate: CLLocationCoordinate2D) async -> GardenLocation {
        guard let request = MKReverseGeocodingRequest(
            location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        ) else { return GardenLocationMapper.location(from: nil, at: coordinate) }
        let item = try? await request.mapItems.first
        return GardenLocationMapper.location(from: item, at: coordinate)
    }
}
