import CoreLocation
import SwiftUI

// Shared pieces for the Mode Pemupukan experiment (Sketch: Pemupukan / Mode Pemupukan / *).

enum SpreaderPalette {
    static let ink = rgb(0x141517)
    static let inkSecondary = rgb(0x141517, opacity: 0.72)
    static let inkTertiary = rgb(0x141517, opacity: 0.55)
    static let panel = rgb(0xF2F4F7)
    static let searchCard = rgb(0xEAEAEE)
    static let brand = rgb(0xFF4F18)
    static let brandDeep = rgb(0xC9390C)
    static let brandSoft = rgb(0xFFEAE3)
    static let darkTop = rgb(0x2E3034)
}

extension SpreaderPalette {
    /// Kept inside the experiment: other features declare their own `Color(hex:)`.
    static func rgb(_ hex: UInt32, opacity: Double = 1) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255, opacity: opacity)
    }
}

enum SpreaderFormat {
    static let locale = Locale(identifier: "id_ID")

    static func kilograms(_ value: Double, maxFraction: Int = 1) -> String {
        value.formatted(.number.precision(.fractionLength(0...maxFraction)).locale(locale)) + " kg"
    }

    /// "KROPS-SPR-A1B2" → "Spreader A1B2"
    static func deviceName(_ advertised: String) -> String {
        let prefix = "KROPS-SPR-"
        guard advertised.hasPrefix(prefix) else { return advertised }
        return "Spreader " + advertised.dropFirst(prefix.count)
    }

    /// Panel title once connected: "KROPS Spreader A1B2", or the advertised name.
    static func headerName(_ advertised: String) -> String {
        advertised.hasPrefix("KROPS-SPR-") ? "KROPS " + deviceName(advertised) : advertised
    }
}

/// Dose per zone. Sample values until the assessment result supplies real totals and tree counts.
/// One dose is one "T:" command: 0.75 L at 2.9 L/min = T:15517.
struct SpreaderZonePlan: Equatable {
    let zoneID: Int
    let treeCount: Int
    let totalKg: Double
    let dosePerTreeKg: Double
    /// Solution volume sent to the spreader for one tree.
    let litersPerTree: Double

    // Sample assumptions, same tree density as DemoReviewReport.
    private static let treesPerHectare = 136.0
    private static let sampleDosePerTreeKg = 1.5
    /// Placeholder conversion from fertilizer kg to solution liters (0.5 L per kg → 0.75 L per tree).
    private static let sampleLitersPerKg = 0.5

    static func sample(for zones: [WaypointZone]) -> [Int: SpreaderZonePlan] {
        Dictionary(uniqueKeysWithValues: zones.map { zone in
            let trees = max(Int((zone.areaSquareMeters / 10_000 * treesPerHectare).rounded()), 1)
            let zoneTotalLiters = Double(trees) * sampleDosePerTreeKg * sampleLitersPerKg
            let liters = SpreaderDose.litersPerTree(zoneTotalLiters: zoneTotalLiters, treeCount: trees) ?? 0
            return (zone.id, SpreaderZonePlan(zoneID: zone.id, treeCount: trees,
                                                 totalKg: Double(trees) * sampleDosePerTreeKg,
                                                 dosePerTreeKg: sampleDosePerTreeKg, litersPerTree: liters))
        })
    }
}

enum SpreaderGeometry {
    /// Zone containing the coordinate, if any.
    static func zoneID(containing coordinate: CLLocationCoordinate2D, in zones: [WaypointZone]) -> Int? {
        zones.first { zone in zone.fragments.contains { isInside(coordinate, polygon: $0) } }?.id
    }

    /// White separator lines: fragment edges not shared with another fragment of the same zone.
    /// Covers the garden outline and the lines between zones, without the triangulation seams.
    static func separators(for zones: [WaypointZone]) -> [[CLLocationCoordinate2D]] {
        struct Key: Hashable { let ax: Int64, ay: Int64, bx: Int64, by: Int64 }
        func point(_ c: CLLocationCoordinate2D) -> (Int64, Int64) {
            (Int64((c.longitude * 1e8).rounded()), Int64((c.latitude * 1e8).rounded()))
        }
        func key(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Key {
            let p = point(a), q = point(b)
            return p < q ? Key(ax: p.0, ay: p.1, bx: q.0, by: q.1) : Key(ax: q.0, ay: q.1, bx: p.0, by: p.1)
        }
        var lines: [[CLLocationCoordinate2D]] = []
        for zone in zones {
            var count: [Key: Int] = [:]
            var edges: [(Key, CLLocationCoordinate2D, CLLocationCoordinate2D)] = []
            for fragment in zone.fragments where fragment.count >= 3 {
                for index in fragment.indices {
                    let a = fragment[index], b = fragment[(index + 1) % fragment.count]
                    let edgeKey = key(a, b)
                    guard edgeKey.ax != edgeKey.bx || edgeKey.ay != edgeKey.by else { continue }
                    count[edgeKey, default: 0] += 1
                    edges.append((edgeKey, a, b))
                }
            }
            lines += edges.filter { count[$0.0] == 1 }.map { [$0.1, $0.2] }
        }
        return lines
    }

    private static func isInside(_ c: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
        guard polygon.count >= 3 else { return false }
        var inside = false
        var j = polygon.count - 1
        for i in polygon.indices {
            let a = polygon[i], b = polygon[j]
            if (a.latitude > c.latitude) != (b.latitude > c.latitude),
               c.longitude < (b.longitude - a.longitude) * (c.latitude - a.latitude) / (b.latitude - a.latitude) + a.longitude {
                inside.toggle()
            }
            j = i
        }
        return inside
    }
}

/// The Bluetooth rune drawn as strokes (SF Symbols has no public Bluetooth symbol).
struct BluetoothGlyph: View {
    var slashed = false
    var color: Color = SpreaderPalette.ink

    var body: some View {
        GeometryReader { proxy in
            let line = max(proxy.size.height * 0.085, 1.5)
            ZStack {
                BluetoothRune()
                    .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round))
                if slashed {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: proxy.size.height * 0.08))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height * 0.92))
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .round))
                }
            }
        }
        .aspectRatio(0.6, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

private struct BluetoothRune: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }
        var path = Path()
        path.move(to: p(0.1, 0.28))
        path.addLine(to: p(0.9, 0.72))
        path.addLine(to: p(0.5, 0.96))
        path.addLine(to: p(0.5, 0.04))
        path.addLine(to: p(0.9, 0.28))
        path.addLine(to: p(0.1, 0.72))
        return path
    }
}

/// 36 pt status badge (Sketch: Atom / Icon Badge / Neutral, Brand).
struct SpreaderIconBadge: View {
    var isBrand = false
    var slashed = false

    var body: some View {
        Circle()
            .fill(isBrand ? SpreaderPalette.brandSoft : SpreaderPalette.ink.opacity(0.08))
            .frame(width: 36, height: 36)
            .overlay {
                BluetoothGlyph(slashed: slashed,
                               color: isBrand ? SpreaderPalette.brand : SpreaderPalette.inkSecondary)
                    .frame(height: 17)
            }
    }
}

/// Slight press feedback for the large round buttons.
struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
