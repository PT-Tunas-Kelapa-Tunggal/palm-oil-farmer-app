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
}
