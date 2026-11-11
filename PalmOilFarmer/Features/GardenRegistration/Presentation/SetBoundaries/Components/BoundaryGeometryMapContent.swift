import SwiftUI
import MapKit

/// Map overlay (polygon / polyline) for the drawn boundary. Used by `GardenBoundaryView`.
struct BoundaryGeometryMapContent: MapContent {
    let coordinates: [CLLocationCoordinate2D]
    let isClosed: Bool
    var fillOpacity = 0.25

    var body: some MapContent {
        if isClosed, coordinates.count >= 3 {
            MapPolygon(coordinates: coordinates)
                .foregroundStyle(.white.opacity(fillOpacity))
                .stroke(.white, lineWidth: 2)
        } else {
            if coordinates.count >= 2 {
                MapPolyline(coordinates: coordinates)
                    .stroke(.white, lineWidth: 2)
            }
            if coordinates.count >= 3,
               let first = coordinates.first, let last = coordinates.last {
                MapPolyline(coordinates: [last, first])
                    .stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
            }
        }
    }
}

#if DEBUG
#Preview("Geometri batas di peta") {
    Map(initialPosition: .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 1.666, longitude: 101.448),
        latitudinalMeters: 400, longitudinalMeters: 400
    ))) {
        BoundaryGeometryMapContent(coordinates: GardenPreviewData.boundary.coordinates, isClosed: true)
    }
    .mapStyle(.imagery)
}

#Preview("Geometri batas · Belum tertutup") {
    Map(initialPosition: .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 1.666, longitude: 101.448),
        latitudinalMeters: 400, longitudinalMeters: 400
    ))) {
        BoundaryGeometryMapContent(coordinates: Array(GardenPreviewData.boundary.coordinates.prefix(3)), isClosed: false)
    }
    .mapStyle(.imagery)
}
#endif
