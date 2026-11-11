import Foundation

/// (1) Repository protocol: finds the garden location. Real impl: `MapKitGardenLocationRepository`,
/// canvas/offline impl: `DummyGardenLocationRepository`.
/// Output model (4) `GardenLocation` stays in the app-wide `Domain/Gardens`, because drafts,
/// the garden list and navigation share it.
@MainActor
protocol GardenLocationRepository {
    func search(_ query: String) async throws -> [GardenLocation]
    func currentLocation() async throws -> GardenLocation
    /// Names a coordinate (e.g. a photo's GPS). Never fails: falls back to a generic label offline.
    func location(at coordinate: GardenCoordinate) async -> GardenLocation
}
