import Foundation

@MainActor
protocol GardenLocationRepository {
    func search(_ query: String) async throws -> [GardenLocation]
    func currentLocation() async throws -> GardenLocation
}
