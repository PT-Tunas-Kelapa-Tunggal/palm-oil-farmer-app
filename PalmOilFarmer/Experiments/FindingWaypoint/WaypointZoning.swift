import Foundation
import MapKit

/// Six experimental, equal-area zones. Coordinates are never written back to Garden.
struct WaypointZone: Identifiable {
    let id: Int
    let fragments: [[CLLocationCoordinate2D]]
    let destination: CLLocationCoordinate2D
    let areaSquareMeters: Double
}

enum WaypointZoning {
    private struct Point {
        var x: Double
        var y: Double
    }

    static func zones(for boundary: GardenBoundary) -> [WaypointZone] {
        guard boundary.points.count <= 500, boundary.isValid,
              let origin = boundary.coordinates.first else { return [] }
        // A local tangent plane keeps the area calculation appropriate for garden-scale plots.
        let meters = 111_194.9266
        let longitudeScale = meters * cos(origin.latitude * .pi / 180)
        guard abs(longitudeScale) > 1,
              boundary.coordinates.allSatisfy({
                  abs($0.longitude - origin.longitude) < 1 && abs($0.latitude - origin.latitude) < 1
              }) else { return [] }
        func coordinate(_ p: Point) -> CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: origin.latitude + p.y / meters,
                                   longitude: origin.longitude + p.x / longitudeScale)
        }
        var polygon = boundary.coordinates.map {
            Point(x: ($0.longitude - origin.longitude) * longitudeScale,
                  y: ($0.latitude - origin.latitude) * meters)
        }
        if signedArea(polygon) < 0 { polygon.reverse() }
        // Remove redundant collinear vertices before ear clipping.
        var changed = true
        while changed && polygon.count > 3 {
            changed = false
            for i in polygon.indices {
                if abs(cross(polygon[(i + polygon.count - 1) % polygon.count],
                             polygon[i], polygon[(i + 1) % polygon.count])) < 0.000001 {
                    polygon.remove(at: i)
                    changed = true
                    break
                }
            }
        }
        guard let triangles = triangulate(polygon) else { return [] }
        let halves = split(triangles, axisX: true, fraction: 0.5)
        var result: [WaypointZone] = []
        for (column, half) in [halves.0, halves.1].enumerated() {
            let lower = split(half, axisX: false, fraction: 1.0 / 3)
            let upper = split(lower.1, axisX: false, fraction: 0.5)
            for (row, fragments) in [upper.1, upper.0, lower.0].enumerated() {
                guard let largest = fragments.max(by: { area($0) < area($1) }) else { return [] }
                let totalArea = fragments.reduce(0) { $0 + area($1) }
                guard totalArea > 0 else { return [] }
                let weightedCenter = fragments.reduce(Point(x: 0, y: 0)) { sum, fragment in
                    let center = centroid(fragment)
                    return Point(x: sum.x + center.x * area(fragment) / totalArea,
                                 y: sum.y + center.y * area(fragment) / totalArea)
                }
                // A concave or disconnected zone's centroid can fall outside the garden.
                let target = fragments.contains(where: { contains(weightedCenter, in: $0) })
                    ? weightedCenter : centroid(largest)
                result.append(WaypointZone(
                    id: row * 2 + column + 1,
                    fragments: fragments.map { $0.map(coordinate) },
                    destination: coordinate(target),
                    areaSquareMeters: totalArea
                ))
            }
        }
        return result.sorted { $0.id < $1.id }
    }

    private static func cross(_ a: Point, _ b: Point, _ c: Point) -> Double {
        (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    }

    private static func signedArea(_ points: [Point]) -> Double {
        guard points.count >= 3 else { return 0 }
        return points.indices.reduce(0) { sum, i in
            let next = points[(i + 1) % points.count]
            return sum + points[i].x * next.y - next.x * points[i].y
        } / 2
    }

    private static func area(_ points: [Point]) -> Double { abs(signedArea(points)) }

    private static func centroid(_ points: [Point]) -> Point {
        var x = 0.0
        var y = 0.0
        for i in points.indices {
            let a = points[i], b = points[(i + 1) % points.count]
            let weight = a.x * b.y - b.x * a.y
            x += (a.x + b.x) * weight
            y += (a.y + b.y) * weight
        }
        let divisor = 6 * signedArea(points)
        return Point(x: x / divisor, y: y / divisor)
    }

    private static func contains(_ point: Point, in convex: [Point]) -> Bool {
        convex.indices.allSatisfy {
            cross(convex[$0], convex[($0 + 1) % convex.count], point) >= -0.000001
        }
    }

    private static func triangulate(_ polygon: [Point]) -> [[Point]]? {
        var remaining = polygon
        var triangles: [[Point]] = []
        while remaining.count > 3 {
            var found = false
            for i in remaining.indices {
                let previous = (i + remaining.count - 1) % remaining.count
                let next = (i + 1) % remaining.count
                let triangle = [remaining[previous], remaining[i], remaining[next]]
                guard cross(triangle[0], triangle[1], triangle[2]) > 0.000001 else { continue }
                let blocked = remaining.indices.contains {
                    $0 != previous && $0 != i && $0 != next && contains(remaining[$0], in: triangle)
                }
                if !blocked {
                    triangles.append(triangle)
                    remaining.remove(at: i)
                    found = true
                    break
                }
            }
            guard found else { return nil }
        }
        if remaining.count == 3 { triangles.append(remaining) }
        return triangles
    }

    private static func clip(_ polygon: [Point], axisX: Bool, value: Double, lower: Bool) -> [Point] {
        guard let last = polygon.last else { return [] }
        func component(_ p: Point) -> Double { axisX ? p.x : p.y }
        func inside(_ p: Point) -> Bool { lower ? component(p) <= value : component(p) >= value }
        var output: [Point] = []
        var previous = last
        for current in polygon {
            if inside(previous) != inside(current) {
                let t = (value - component(previous)) / (component(current) - component(previous))
                output.append(Point(x: previous.x + t * (current.x - previous.x),
                                    y: previous.y + t * (current.y - previous.y)))
            }
            if inside(current) { output.append(current) }
            previous = current
        }
        return output
    }

    private static func split(_ fragments: [[Point]], axisX: Bool, fraction: Double) -> ([[Point]], [[Point]]) {
        let values = fragments.flatMap { $0.map { axisX ? $0.x : $0.y } }
        guard var low = values.min(), var high = values.max() else { return ([], []) }
        let target = fragments.reduce(0) { $0 + area($1) } * fraction
        for _ in 0..<48 {
            let middle = (low + high) / 2
            let clippedArea = fragments.reduce(0) {
                $0 + area(clip($1, axisX: axisX, value: middle, lower: true))
            }
            if clippedArea < target { low = middle } else { high = middle }
        }
        let cut = (low + high) / 2
        func pieces(lower: Bool) -> [[Point]] {
            fragments.map { clip($0, axisX: axisX, value: cut, lower: lower) }
                .filter { area($0) > 0.00000001 }
        }
        return (pieces(lower: true), pieces(lower: false))
    }
}
