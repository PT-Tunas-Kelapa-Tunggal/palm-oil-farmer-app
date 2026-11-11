import SwiftUI
import CoreLocation

/// "Luas | Keliling" glass pill shown above the map while drawing (and inside the panel at large text sizes).
struct BoundaryMetricsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let boundary: GardenBoundary
    var metrics: GardenDisplayMetrics? = nil
    var isClosed = true

    private var displayMetrics: GardenDisplayMetrics {
        if let metrics { return metrics }
        let closed = GardenDisplayMetrics(boundary: boundary)
        guard !isClosed else { return closed }
        let length = zip(boundary.coordinates, boundary.coordinates.dropFirst()).reduce(0.0) { total, pair in
            total + CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
                .distance(from: CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude))
        }
        return GardenDisplayMetrics(area: boundary.points.isEmpty ? "0 ha" : "–",
                                    perimeter: length.formatted(.number.precision(.fractionLength(0))) + " m")
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            metric("Luas", value: isClosed || boundary.points.isEmpty ? displayMetrics.area : "–")
            if !dynamicTypeSize.isAccessibilitySize {
                Rectangle().fill(Color(uiColor: .separator)).frame(width: 1, height: 12)
                    .accessibilityHidden(true)
            }
            metric("Keliling", value: displayMetrics.perimeter)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 41)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(spacing: 0) {
            Text(value).font(.headline)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview("Metrik batas", traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        BoundaryMetricsView(boundary: GardenPreviewData.boundary, metrics: GardenPreviewData.metrics)
        BoundaryMetricsView(boundary: GardenBoundary(points: Array(GardenPreviewData.boundary.points.prefix(2))),
                            isClosed: false)
        BoundaryMetricsView(boundary: GardenBoundary())
    }
    .frame(width: 260)
    .padding(24)
    .background(.black.opacity(0.7))
    .environment(\.colorScheme, .dark)
}
#endif
