import SwiftUI
import MapKit

struct BlockAreaThumbnail: View {
    let block: GardenBlock

    var body: some View {
        Canvas { context, size in
            let points = block.fragments.flatMap { $0.map { MKMapPoint($0) } }
            guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
                  let minY = points.map(\.y).min(), let maxY = points.map(\.y).max() else { return }
            let scale = min((size.width - 14) / max(maxX - minX, 1),
                            (size.height - 14) / max(maxY - minY, 1))
            func projected(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
                let point = MKMapPoint(coordinate)
                return CGPoint(x: (point.x - (minX + maxX) / 2) * scale + size.width / 2,
                               y: (point.y - (minY + maxY) / 2) * scale + size.height / 2)
            }
            for edge in block.outlineEdges {
                var path = Path()
                path.addLines(edge.map(projected))
                context.stroke(path, with: .color(.black.opacity(0.55)), lineWidth: 1.5)
            }
        }
        .background(Color(white: 0.62))
        .accessibilityHidden(true)
    }
}
