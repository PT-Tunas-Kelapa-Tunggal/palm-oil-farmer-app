import MapKit
import SwiftUI

/// A lightweight boundary diagram avoids running six live maps in a scrolling list.
struct WaypointZoneThumbnail: View {
    let zones: [WaypointZone]

    var body: some View {
        Canvas { context, size in
            let points = zones.flatMap { $0.fragments.flatMap { $0.map { MKMapPoint($0) } } }
            guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
                  let minY = points.map(\.y).min(), let maxY = points.map(\.y).max() else { return }
            let scale = min((size.width - 32) / max(maxX - minX, 1),
                            (size.height - 24) / max(maxY - minY, 1))
            func projected(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
                let point = MKMapPoint(coordinate)
                return CGPoint(x: (point.x - (minX + maxX) / 2) * scale + size.width / 2,
                               y: (point.y - (minY + maxY) / 2) * scale + size.height / 2)
            }
            for zone in zones {
                var path = Path()
                for fragment in zone.fragments {
                    guard let first = fragment.first else { continue }
                    path.move(to: projected(first))
                    for coordinate in fragment.dropFirst() { path.addLine(to: projected(coordinate)) }
                    path.closeSubpath()
                }
                context.fill(path, with: .color(WaypointPalette.color(for: zone.id).opacity(0.8)))
                context.draw(Text("\(zone.id)").font(.callout.bold()).foregroundStyle(.black),
                             at: projected(zone.destination))
            }
        }
        .background(Color.green.opacity(0.08))
        .overlay(alignment: .topLeading) {
            Text("SKEMA ZONA").font(.caption2.weight(.semibold))
                .padding(8).foregroundStyle(.secondary)
        }
        .accessibilityLabel("Skema kebun dengan enam zona bernomor satu sampai enam")
    }
}

enum WaypointPalette {
    static func color(for id: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.71, green: 0.81, blue: 0.98),
            Color(red: 0.85, green: 0.88, blue: 1),
            Color(red: 0.80, green: 0.87, blue: 0.98),
            Color(red: 0.67, green: 0.78, blue: 0.95),
            Color(red: 0.72, green: 0.85, blue: 0.96),
            Color(red: 0.84, green: 0.89, blue: 1)
        ]
        return colors[max(0, min(id - 1, colors.count - 1))]
    }
}

#if DEBUG
enum WaypointPreviewData {
    static var garden: Garden {
        let coordinates = [
            CLLocationCoordinate2D(latitude: -6.599, longitude: 106.799),
            CLLocationCoordinate2D(latitude: -6.599, longitude: 106.801),
            CLLocationCoordinate2D(latitude: -6.602, longitude: 106.801),
            CLLocationCoordinate2D(latitude: -6.602, longitude: 106.799)
        ]
        return Garden(id: UUID(), name: "Kebun Contoh", locationName: "Data demo • Bogor",
                      boundary: GardenBoundary(points: coordinates.map(GardenCoordinate.init)),
                      plantingYear: 2020, soilType: .mineral)
    }
}
#endif
