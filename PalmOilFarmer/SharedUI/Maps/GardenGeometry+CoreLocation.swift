import CoreLocation

// CoreLocation/MapKit adapter for the UI: map views need CLLocationCoordinate2D.
// Lives in SharedUI (not Data) so Presentation never depends on the Data layer,
// and outside Domain so Domain stays pure Foundation.
extension GardenCoordinate {
    init(_ coordinate: CLLocationCoordinate2D) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
    }

    var mapCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension GardenBoundary {
    var coordinates: [CLLocationCoordinate2D] {
        points.map(\.mapCoordinate)
    }

    var perimeterMeters: Double {
        guard points.count > 1 else { return 0 }
        return points.indices.reduce(0) { total, index in
            let next = points[(index + 1) % points.count]
            let current = points[index]
            return total + CLLocation(latitude: current.latitude, longitude: current.longitude)
                .distance(from: CLLocation(latitude: next.latitude, longitude: next.longitude))
        }
    }
}
