import CoreLocation

@MainActor
final class MappingLocationAuthorization: GardenLocationAuthorizing {
    private let manager = CLLocationManager()

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
}
