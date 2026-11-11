import Foundation

/// (1) Asks for location permission before mapping. Real impl: `MappingLocationAuthorization`.
@MainActor
protocol GardenLocationAuthorizing {
    func requestAuthorization()
}
