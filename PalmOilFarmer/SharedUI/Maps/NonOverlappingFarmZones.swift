import Foundation

/// Partitions intersections between orthomosaic zone polygons at the midpoint between their centers.
/// The resulting polygons are used for both drawing and hit testing, so a point belongs to at most one zone.
enum NonOverlappingFarmZones {
    static func polygons(for zones: [FertilizingZoneItem]) -> [Int64: [PixelPoint]] {
        let valid = zones.compactMap { zone -> (id: Int64, points: [PixelPoint], center: PixelPoint, bounds: Bounds)? in
            guard zone.boundingBox.count >= 3,
                  let bounds = Bounds(zone.boundingBox),
                  let center = center(of: zone.boundingBox) else { return nil }
            return (zone.id, zone.boundingBox, center, bounds)
        }

        var result: [Int64: [PixelPoint]] = [:]
        for zone in valid {
            var points = zone.points
            for other in valid where other.id != zone.id && zone.bounds.overlaps(other.bounds) {
                var normalX = other.center.x - zone.center.x
                let normalY = other.center.y - zone.center.y
                // Identical centers still need a deterministic partition.
                if normalX * normalX + normalY * normalY <= 0.000001 {
                    normalX = zone.id < other.id ? 1 : -1
                }
                let midpoint = PixelPoint(
                    x: (zone.center.x + other.center.x) / 2,
                    y: (zone.center.y + other.center.y) / 2
                )
                points = clip(points, midpoint: midpoint, normalX: normalX, normalY: normalY)
                if points.count < 3 { break }
            }
            if points.count >= 3, abs(signedDoubleArea(of: points)) > 0.000001 {
                result[zone.id] = points
            }
        }
        return result
    }

    static func center(of points: [PixelPoint]) -> PixelPoint? {
        guard let bounds = Bounds(points) else { return nil }
        let doubleArea = signedDoubleArea(of: points)
        guard abs(doubleArea) > 0.000001 else {
            return PixelPoint(x: (bounds.minX + bounds.maxX) / 2,
                              y: (bounds.minY + bounds.maxY) / 2)
        }
        var sumX = 0.0
        var sumY = 0.0
        for index in points.indices {
            let first = points[index]
            let second = points[(index + 1) % points.count]
            let cross = first.x * second.y - second.x * first.y
            sumX += (first.x + second.x) * cross
            sumY += (first.y + second.y) * cross
        }
        return PixelPoint(x: sumX / (3 * doubleArea), y: sumY / (3 * doubleArea))
    }

    static func contains(_ point: PixelPoint, in polygon: [PixelPoint]) -> Bool {
        guard polygon.count >= 3 else { return false }
        var inside = false
        var previous = polygon.count - 1
        for index in polygon.indices {
            let current = polygon[index]
            let last = polygon[previous]
            if (current.y > point.y) != (last.y > point.y),
               point.x < (last.x - current.x) * (point.y - current.y) / (last.y - current.y) + current.x {
                inside.toggle()
            }
            previous = index
        }
        return inside
    }

    private static func clip(
        _ polygon: [PixelPoint], midpoint: PixelPoint, normalX: Double, normalY: Double
    ) -> [PixelPoint] {
        guard !polygon.isEmpty else { return [] }
        func distance(_ point: PixelPoint) -> Double {
            (point.x - midpoint.x) * normalX + (point.y - midpoint.y) * normalY
        }
        var output: [PixelPoint] = []
        var previous = polygon[polygon.count - 1]
        var previousDistance = distance(previous)
        for current in polygon {
            let currentDistance = distance(current)
            let previousInside = previousDistance <= 0
            let currentInside = currentDistance <= 0
            if previousInside != currentInside {
                let fraction = previousDistance / (previousDistance - currentDistance)
                output.append(PixelPoint(
                    x: previous.x + fraction * (current.x - previous.x),
                    y: previous.y + fraction * (current.y - previous.y)
                ))
            }
            if currentInside { output.append(current) }
            previous = current
            previousDistance = currentDistance
        }
        return output
    }

    private static func signedDoubleArea(of points: [PixelPoint]) -> Double {
        guard points.count >= 3 else { return 0 }
        return points.indices.reduce(0) { sum, index in
            let first = points[index]
            let second = points[(index + 1) % points.count]
            return sum + first.x * second.y - second.x * first.y
        }
    }

    private struct Bounds {
        let minX: Double
        let maxX: Double
        let minY: Double
        let maxY: Double

        init?(_ points: [PixelPoint]) {
            guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
                  let minY = points.map(\.y).min(), let maxY = points.map(\.y).max() else { return nil }
            self.minX = minX
            self.maxX = maxX
            self.minY = minY
            self.maxY = maxY
        }

        func overlaps(_ other: Bounds) -> Bool {
            minX < other.maxX && other.minX < maxX && minY < other.maxY && other.minY < maxY
        }
    }
}
