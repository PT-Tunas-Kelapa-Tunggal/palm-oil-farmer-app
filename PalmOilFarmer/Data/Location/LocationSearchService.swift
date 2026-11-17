import MapKit

/// MapKit stays at the feature's data boundary; views can inject a search closure.
enum LocationSearchService {
    @MainActor
    static func search(_ query: String) async throws -> [GardenLocation] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "\(query), Indonesia"
        request.resultTypes = [.address, .pointOfInterest]
        let response = try await MKLocalSearch(request: request).start()
        try Task.checkCancellation()
        return response.mapItems.map { item in
            GardenLocation(
                name: item.name ?? query,
                subtitle: item.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true) ?? "Indonesia",
                coordinate: GardenCoordinate(item.location.coordinate)
            )
        }
    }

    /// Names the device location so drafts read like a place. Falls back to a generic label offline.
    @MainActor
    static func location(at coordinate: CLLocationCoordinate2D) async -> GardenLocation {
        let fallback = GardenLocation(name: "Lokasi saat ini", subtitle: "", coordinate: GardenCoordinate(coordinate))
        guard let request = MKReverseGeocodingRequest(
            location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        ), let item = try? await request.mapItems.first else { return fallback }
        return GardenLocation(
            name: item.name ?? fallback.name,
            subtitle: item.addressRepresentations?.cityWithContext ?? "",
            coordinate: GardenCoordinate(coordinate)
        )
    }
}
