import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class BlockLocationSession {
    private(set) var location: CLLocation?
    private(set) var message = "Tekan Mulai untuk menggunakan lokasi."
    private(set) var needsSettings = false
    private(set) var reducedAccuracy = false
    private var runID = UUID()

    /// Owned by the map's structured .task; cancellation ends the location session.
    func run() async {
        let currentRun = UUID()
        runID = currentRun
        location = nil
        needsSettings = false
        reducedAccuracy = false
        message = "Mencari posisi GPS…"
        let authorization = CLServiceSession(authorization: .whenInUse)
        defer {
            authorization.invalidate()
            if runID == currentRun { location = nil }
        }
        do {
            for try await update in CLLocationUpdate.liveUpdates(.otherNavigation) {
                try Task.checkCancellation()
                guard runID == currentRun else { return }
                if update.authorizationDenied || update.authorizationDeniedGlobally || update.authorizationRestricted {
                    location = nil
                    needsSettings = true
                    message = "Akses lokasi tidak tersedia. Periksa izin lokasi di Pengaturan."
                    continue
                }
                needsSettings = false
                reducedAccuracy = update.accuracyLimited
                guard let fix = update.location, Self.isUsable(fix, now: .now) else {
                    message = "Menunggu posisi GPS terbaru…"
                    continue
                }
                if let previous = location, fix.timestamp <= previous.timestamp { continue }
                location = fix
                message = reducedAccuracy
                    ? "Aktifkan Lokasi Tepat di Pengaturan untuk panduan antar blok."
                    : "Posisi diperbarui"
            }
        } catch is CancellationError {
            // Leaving the screen or backgrounding the app intentionally stops tracking.
        } catch {
            message = "Lokasi terputus. Hentikan lalu mulai kembali."
        }
    }

    static func isUsable(_ fix: CLLocation, now: Date) -> Bool {
        let age = now.timeIntervalSince(fix.timestamp)
        return CLLocationCoordinate2DIsValid(fix.coordinate)
            && fix.coordinate.latitude.isFinite && fix.coordinate.longitude.isFinite
            && fix.horizontalAccuracy.isFinite && fix.horizontalAccuracy >= 0
            && age >= -2 && age <= 15
    }

    func freshLocation(at date: Date) -> CLLocation? {
        guard let location, Self.isUsable(location, now: date) else { return nil }
        return location
    }

    static func distance(from location: CLLocation, to zone: GardenBlock) -> Double {
        location.distance(from: CLLocation(latitude: zone.destination.latitude,
                                          longitude: zone.destination.longitude))
    }

    static func bearing(from origin: CLLocationCoordinate2D, to target: CLLocationCoordinate2D) -> Double {
        let lat1 = origin.latitude * .pi / 180
        let lat2 = target.latitude * .pi / 180
        let delta = (target.longitude - origin.longitude) * .pi / 180
        let y = sin(delta) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(delta)
        return (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
}
