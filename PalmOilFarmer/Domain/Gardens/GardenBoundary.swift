import Foundation

struct GardenCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct GardenBoundary: Codable {
    var points: [GardenCoordinate] = []

    /// A local tangent-plane approximation, suitable for small agricultural plots.
    var areaHectares: Double {
        guard points.count >= 3, let origin = points.first else { return 0 }
        let radius = 6_371_000.0
        let radians = Double.pi / 180
        let projected = points.map {
            (
                x: ($0.longitude - origin.longitude) * radians * radius * cos(origin.latitude * radians),
                y: ($0.latitude - origin.latitude) * radians * radius
            )
        }
        let doubledArea = projected.indices.reduce(0.0) { total, index in
            let next = projected[(index + 1) % projected.count]
            let current = projected[index]
            return total + current.x * next.y - next.x * current.y
        }
        return abs(doubledArea) / 2 / 10_000
    }

    var isValid: Bool {
        guard points.count >= 3,
              points.allSatisfy({
                  $0.latitude.isFinite && $0.longitude.isFinite
                      && (-90...90).contains($0.latitude)
                      && (-180...180).contains($0.longitude)
              }), Set(points).count == points.count else { return false }
        return areaHectares > 0.000001 && !hasIntersectingEdges
    }

    private var hasIntersectingEdges: Bool {
        guard points.count >= 4 else { return false }
        for first in points.indices {
            let firstEnd = (first + 1) % points.count
            for second in points.indices where second > first {
                let secondEnd = (second + 1) % points.count
                guard firstEnd != second, secondEnd != first else { continue }
                if edgesIntersect(points[first], points[firstEnd], points[second], points[secondEnd]) {
                    return true
                }
            }
        }
        return false
    }

    private func edgesIntersect(
        _ a: GardenCoordinate, _ b: GardenCoordinate,
        _ c: GardenCoordinate, _ d: GardenCoordinate
    ) -> Bool {
        func cross(_ p: GardenCoordinate, _ q: GardenCoordinate, _ r: GardenCoordinate) -> Double {
            (q.longitude - p.longitude) * (r.latitude - p.latitude)
                - (q.latitude - p.latitude) * (r.longitude - p.longitude)
        }
        let first = cross(a, b, c)
        let second = cross(a, b, d)
        let third = cross(c, d, a)
        let fourth = cross(c, d, b)
        if first * second < 0 && third * fourth < 0 { return true }
        func liesOnSegment(_ p: GardenCoordinate, _ q: GardenCoordinate, _ r: GardenCoordinate) -> Bool {
            r.longitude >= min(p.longitude, q.longitude) && r.longitude <= max(p.longitude, q.longitude)
                && r.latitude >= min(p.latitude, q.latitude) && r.latitude <= max(p.latitude, q.latitude)
        }
        return (first == 0 && liesOnSegment(a, b, c))
            || (second == 0 && liesOnSegment(a, b, d))
            || (third == 0 && liesOnSegment(c, d, a))
            || (fourth == 0 && liesOnSegment(c, d, b))
    }
}

