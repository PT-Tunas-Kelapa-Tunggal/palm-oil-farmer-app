import MapKit
import SwiftUI

extension GardenBlock {
    var code: String {
        let columns = ["A", "B"]
        let rows = ["A", "B", "C"]
        return columns[(id - 1) % 2] + rows[min(2, max(0, (id - 1) / 2))]
    }

    // Triangulation fragments share internal edges. Draw only the outside of each block.
    var outlineEdges: [[CLLocationCoordinate2D]] {
        func key(_ point: CLLocationCoordinate2D) -> String {
            "\(Int64((point.latitude * 1e8).rounded())):\(Int64((point.longitude * 1e8).rounded()))"
        }
        var edges: [String: [CLLocationCoordinate2D]] = [:]
        var counts: [String: Int] = [:]
        for fragment in fragments {
            for index in fragment.indices {
                let a = fragment[index], b = fragment[(index + 1) % fragment.count]
                let first = key(a), second = key(b)
                guard first != second else { continue }
                let edgeKey = [first, second].sorted().joined(separator: "|")
                counts[edgeKey, default: 0] += 1
                edges[edgeKey] = [a, b]
            }
        }
        return edges.keys.sorted().filter { counts[$0] == 1 }.compactMap { edges[$0] }
    }
}

struct BlockMapOverlay: MapContent {
    let blocks: [GardenBlock]
    let selectedID: Int

    var body: some MapContent {
        ForEach(blocks) { block in
            ForEach(block.fragments.indices, id: \.self) { index in
                MapPolygon(coordinates: block.fragments[index])
                    .foregroundStyle(.white.opacity(block.id == selectedID ? 0.38 : 0.18))
            }
            let edges = block.outlineEdges
            ForEach(edges.indices, id: \.self) { index in
                MapPolyline(coordinates: edges[index])
                    .stroke(.white.opacity(block.id == selectedID ? 1 : 0.7),
                            lineWidth: block.id == selectedID ? 5 : 1.5)
            }
            Annotation(block.code, coordinate: block.destination) {
                Text(block.code)
                    .font(.subheadline.weight(block.id == selectedID ? .semibold : .regular))
                    .foregroundStyle(.black)
            }
            .annotationTitles(.hidden)
        }
    }
}

enum BlockMapCamera {
    static func position(for coordinates: [CLLocationCoordinate2D]) -> MapCameraPosition {
        let points = coordinates.map { MKMapPoint($0) }
        guard let first = points.first else { return .automatic }
        let rect = points.dropFirst().reduce(MKMapRect(origin: first, size: MKMapSize(width: 1, height: 1))) {
            $0.union(MKMapRect(origin: $1, size: MKMapSize(width: 1, height: 1)))
        }
        return .rect(rect.insetBy(dx: -max(rect.width * 0.15, 20),
                                  dy: -max(rect.height * 0.15, 20)))
    }
}
