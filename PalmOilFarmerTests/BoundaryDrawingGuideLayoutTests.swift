import CoreGraphics
import MapKit
import Testing
@testable import PalmOilFarmer

struct BoundaryDrawingGuideLayoutTests {
    @Test(arguments: [
        CGSize(width: 393, height: 852),
        CGSize(width: 852, height: 393)
    ])
    func exampleExistsBeforeMapViewIsReady(viewport: CGSize) throws {
        let layout = BoundaryDrawingGuideLayout(
            center: CLLocationCoordinate2D(latitude: -6.2, longitude: 106.8),
            longitudeDelta: 0.006,
            viewport: viewport
        )
        #expect(layout.coordinates.count == 4)
        #expect(!layout.mapRect.isEmpty)
        for coordinate in layout.coordinates {
            #expect(CLLocationCoordinate2DIsValid(coordinate))
            #expect(layout.mapRect.contains(MKMapPoint(coordinate)))
        }
        let first = try #require(layout.coordinates.first)
        let fourth = try #require(layout.coordinates.last)
        #expect(fourth.longitude > first.longitude)
        #expect(layout.coordinates[1].latitude < first.latitude)
    }

    @Test func exampleStaysNearSelectedLocation() {
        let center = CLLocationCoordinate2D(latitude: 0.5, longitude: 101.5)
        let layout = BoundaryDrawingGuideLayout(
            center: center, longitudeDelta: 0.006,
            viewport: CGSize(width: 393, height: 852)
        )
        let mapCenter = MKMapPoint(x: layout.mapRect.midX, y: layout.mapRect.midY).coordinate
        #expect(abs(mapCenter.latitude - center.latitude) < 0.000001)
        #expect(abs(mapCenter.longitude - center.longitude) < 0.000001)
    }

    @Test(arguments: [CGSize(width: 393, height: 852), CGSize(width: 852, height: 393)])
    func allCornersRemainAboveTheFixedGuideSheet(viewport: CGSize) {
        let obscuredHeight: CGFloat = 268
        let layout = BoundaryDrawingGuideLayout(
            center: CLLocationCoordinate2D(latitude: 0.5, longitude: 101.5),
            longitudeDelta: 0.006, viewport: viewport, obscuredBottomHeight: obscuredHeight
        )
        for coordinate in layout.coordinates {
            let point = MKMapPoint(coordinate)
            let y = (point.y - layout.mapRect.minY) / layout.mapRect.height * viewport.height
            #expect(y > 0)
            #expect(y < viewport.height - obscuredHeight)
        }
    }
}
