import SwiftUI
import MapKit

/// Creates a geographic example before MapKit attaches its view or loads imagery.
struct BoundaryDrawingGuideLayout {
    let mapRect: MKMapRect
    let coordinates: [CLLocationCoordinate2D]

    init(
        center: CLLocationCoordinate2D, longitudeDelta: Double, viewport: CGSize,
        obscuredBottomHeight: CGFloat = 0
    ) {
        let centerPoint = MKMapPoint(center)
        let westernPoint = MKMapPoint(CLLocationCoordinate2D(
            latitude: center.latitude, longitude: center.longitude - longitudeDelta / 2
        ))
        let width = max(1, abs(centerPoint.x - westernPoint.x) * 2)
        let height = width * max(1, viewport.height) / max(1, viewport.width)
        let rect = MKMapRect(
            x: centerPoint.x - width / 2, y: centerPoint.y - height / 2,
            width: width, height: height
        )
        mapRect = rect
        let visibleFraction = max(1, viewport.height - max(0, obscuredBottomHeight)) / max(1, viewport.height)
        coordinates = [
            CGPoint(x: 0.18, y: 0.25), CGPoint(x: 0.34, y: 0.80),
            CGPoint(x: 0.88, y: 0.80), CGPoint(x: 0.72, y: 0.18)
        ].map { point in
            MKMapPoint(x: rect.minX + point.x * rect.width,
                       y: rect.minY + point.y * visibleFraction * rect.height).coordinate
        }
    }
}
