import CoreLocation

@MainActor
final class CurrentLocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func coordinate() async throws -> CLLocationCoordinate2D {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                if Task.isCancelled {
                    finish(.failure(CancellationError()))
                    return
                }
                requestLocationIfAuthorized()
                guard self.continuation != nil else { return }
                timeoutTask = Task {
                    do {
                        try await Task.sleep(for: .seconds(30))
                        finish(.failure(CLError(.locationUnknown)))
                    } catch {}
                }
            }
        } onCancel: {
            Task { @MainActor in
                self.finish(.failure(CancellationError()))
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        requestLocationIfAuthorized()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        finish(.success(location.coordinate))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(.failure(error))
    }

    private func requestLocationIfAuthorized() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
        case .denied, .restricted: finish(.failure(CLError(.denied)))
        @unknown default: finish(.failure(CLError(.denied)))
        }
    }

    private func finish(_ result: Result<CLLocationCoordinate2D, Error>) {
        timeoutTask?.cancel()
        timeoutTask = nil
        manager.stopUpdatingLocation()
        let pending = continuation
        continuation = nil
        pending?.resume(with: result)
    }
}
