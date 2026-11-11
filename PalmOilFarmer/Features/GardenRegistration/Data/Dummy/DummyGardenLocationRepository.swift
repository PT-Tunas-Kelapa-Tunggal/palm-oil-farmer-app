#if DEBUG
import Foundation

/// Dummy repository for canvas previews and offline demos.
/// Never touches MapKit or GPS, so previews render instantly and the same way every time.
@MainActor
struct DummyGardenLocationRepository: GardenLocationRepository {
    enum Scenario { case results, noResults, offline }

    let scenario: Scenario

    init(_ scenario: Scenario = .results) {
        self.scenario = scenario
    }

    func search(_ query: String) async throws -> [GardenLocation] {
        switch scenario {
        case .results: Self.sampleResults
        case .noResults: []
        case .offline: throw URLError(.notConnectedToInternet)
        }
    }

    func currentLocation() async throws -> GardenLocation {
        guard scenario != .offline else { throw URLError(.notConnectedToInternet) }
        return Self.sampleCurrentLocation
    }

    func location(at coordinate: GardenCoordinate) async -> GardenLocation {
        GardenLocation(name: "Malang Rapat", subtitle: "Gunung Kijang, Bintan", coordinate: coordinate, source: .photo)
    }

    static var sampleResults: [GardenLocation] {
        [
            GardenLocation(name: "SMKN 1 Gunung Kijang", subtitle: "Kawal, Gunung Kijang, Bintan",
                           coordinate: GardenCoordinate(latitude: 1.106115, longitude: 104.119121)),
            GardenLocation(name: "Masjid Al-Ikhlas Malang Rapat", subtitle: "Malang Rapat, Gunung Kijang, Bintan",
                           coordinate: GardenCoordinate(latitude: 1.104950, longitude: 104.121010)),
            GardenLocation(name: "Simpang Kawal", subtitle: "Gunung Kijang, Bintan, Kepulauan Riau",
                           coordinate: GardenCoordinate(latitude: 1.098300, longitude: 104.128400))
        ]
    }

    static var sampleCurrentLocation: GardenLocation {
        GardenLocation(name: "Malang Rapat", subtitle: "Gunung Kijang, Bintan",
                       coordinate: GardenCoordinate(latitude: 1.104950, longitude: 104.121010),
                       source: .currentLocation)
    }
}
#endif
