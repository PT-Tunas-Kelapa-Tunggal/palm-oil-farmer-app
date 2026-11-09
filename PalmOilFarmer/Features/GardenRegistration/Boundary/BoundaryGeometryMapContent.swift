import SwiftUI
import MapKit

/// Shared geographic geometry for the guided exercise and the boundary editor.
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
