import CoreLocation

/// (2) Real implementation of `GardenLocationAuthorizing` (CoreLocation permission prompt).
@MainActor
final class MappingLocationAuthorization: GardenLocationAuthorizing {
    private let manager = CLLocationManager()

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
}
