import Foundation

/// Asks for location permission before mapping.
@MainActor
protocol GardenLocationAuthorizing {
    func requestAuthorization()
}
