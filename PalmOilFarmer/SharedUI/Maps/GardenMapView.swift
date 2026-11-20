import SwiftUI
import MapKit

/// Uses live coordinates in the app, with an optional Sketch map asset for visual previews.
struct GardenMapView: View {
    let boundary: GardenBoundary
    var referenceImage: String? = nil
    var showsAnnotations = false

    var body: some View {
        Group {
            if let referenceImage {
                Image(referenceImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Map {
                    MapPolygon(coordinates: boundary.coordinates)
                        .foregroundStyle(.white.opacity(0.25))
                        .stroke(.white.opacity(0.9), lineWidth: 2)
                    if showsAnnotations {
                        ForEach(boundary.points.indices, id: \.self) { index in
                            Annotation("", coordinate: boundary.points[index].mapCoordinate, anchor: .center) {
                                BoundaryPointMarker(number: index + 1)
                            }
                        }
                    }
                }
                .mapStyle(.imagery)
                .mapControls {}
                .allowsHitTesting(false)
            }
        }
        .clipped()
        .accessibilityLabel("Peta batas kebun")
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
