import SwiftUI
import MapKit

/// Uses live coordinates in the app, with an optional Sketch map asset for visual previews.
struct GardenMapView: View {
    let boundary: GardenBoundary
    var referenceImage: String? = nil
    var showsAnnotations = false
    /// Room kept clear around the boundary, e.g. under a title or a card that overlaps the map.
    var contentInsets = EdgeInsets()
    /// Extra room around the boundary on top of `contentInsets`; 1 fits it edge to edge.
    var zoomOut = 1.0

    var body: some View {
        Group {
            if let referenceImage {
                Image(referenceImage)
                    .resizable()
                    .scaledToFill()
            } else {
                GeometryReader { geometry in
                    map(in: geometry.size)
                }
            }
        }
        .clipped()
        .accessibilityLabel("Peta batas kebun")
    }

    private func map(in size: CGSize) -> some View {
        Map(position: .constant(cameraPosition(in: size))) {
            MapPolygon(coordinates: boundary.coordinates)
                .foregroundStyle(.white.opacity(0.25))
                .stroke(.white.opacity(0.9), lineWidth: 2)
            if showsAnnotations {
                ForEach(boundary.points.indices, id: \.self) { index in
                    Annotation("", coordinate: boundary.points[index].mapCoordinate) {
                        BoundaryPointMarker(number: index + 1)
                    }
                }
            }
        }
        .mapStyle(.imagery)
        .mapControls {}
        .allowsHitTesting(false)
    }

    /// Frames the boundary inside the map minus `contentInsets`, so it never sits under the title
    /// or a card. Without insets or zoom, MapKit frames it automatically as before.
    private func cameraPosition(in size: CGSize) -> MapCameraPosition {
        let points = boundary.coordinates.map { MKMapPoint($0) }
        guard points.count > 1, contentInsets != EdgeInsets() || zoomOut != 1,
              let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(), let maxY = points.map(\.y).max() else { return .automatic }
        let availableWidth = size.width - contentInsets.leading - contentInsets.trailing
        let availableHeight = size.height - contentInsets.top - contentInsets.bottom
        guard availableWidth > 0, availableHeight > 0 else { return .automatic }
        // Map points per screen point.
        let scale = max((maxX - minX) / availableWidth, (maxY - minY) / availableHeight) * zoomOut
        guard scale > 0, scale.isFinite else { return .automatic }
        let originX = (minX + maxX) / 2 - (contentInsets.leading + availableWidth / 2) * scale
        let originY = (minY + maxY) / 2 - (contentInsets.top + availableHeight / 2) * scale
        return .rect(MKMapRect(x: originX, y: originY, width: size.width * scale, height: size.height * scale))
    }
}

struct BoundaryPointMarker: View {
    let number: Int
    @ScaledMetric(relativeTo: .caption2) private var markerSize = 5

    var body: some View {
        Circle()
            .fill(KropsTheme.labelInversePrimary)
            .overlay { Circle().stroke(KropsTheme.labelInversePrimary, lineWidth: 1.5) }
            .frame(width: markerSize, height: markerSize)
            .accessibilityLabel("Titik \(number)")
    }
}

#if DEBUG
#Preview("Garden Map", traits: .sizeThatFitsLayout) {
    GardenMapView(boundary: GardenPreviewData.boundary, referenceImage: "GardenProfileMap")
        .frame(width: 402, height: 201)
}

#Preview("Boundary Point", traits: .sizeThatFitsLayout) {
    BoundaryPointMarker(number: 3).padding()
}
#endif
