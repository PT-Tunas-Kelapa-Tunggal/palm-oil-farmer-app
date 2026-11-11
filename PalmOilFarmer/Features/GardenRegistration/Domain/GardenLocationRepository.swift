import Foundation

/// Finds the garden location.
@MainActor
protocol GardenLocationRepository {
    func search(_ query: String) async throws -> [GardenLocation]
    func currentLocation() async throws -> GardenLocation
    /// Names a coordinate (e.g. a photo's GPS). Never fails: falls back to a generic label offline.
    func location(at coordinate: GardenCoordinate) async -> GardenLocation
}
