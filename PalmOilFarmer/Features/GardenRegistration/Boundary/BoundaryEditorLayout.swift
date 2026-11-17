import SwiftUI
import CoreLocation

struct BoundaryEditorLayout<MapContent: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let boundary: GardenBoundary
    var metrics: GardenDisplayMetrics? = nil
    var title = "Buat Batas Kebun"
    var isClosed = true
    var showsControls = true
    var showsBottomPanel = true
    var bottomSheetHeight: CGFloat = 0
    let onClose: () -> Void
    let onSearch: () -> Void
    let onUndo: () -> Void
    let onClear: () -> Void
    let onConfirm: () -> Void
    @ViewBuilder let map: () -> MapContent

    private var showsMetricsInPanel: Bool {
        verticalSizeClass == .compact && dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        map()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: bottomSheetHeight).allowsHitTesting(false)
            }
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                if showsControls {
                    VStack(spacing: 12) {
                        RegistrationHeader(title: title, isMapHeader: true, onClose: onClose)
                        if !showsMetricsInPanel {
                            BoundaryMetricsView(boundary: boundary, metrics: metrics, isClosed: isClosed)
                                .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 237)
                        }
                    }
                    .padding(.bottom, 8)
                    .background {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.7)
                            .mask {
                                LinearGradient(
                                    stops: [
                                        .init(color: .black, location: 0),
                                        .init(color: .black, location: 0.65),
                                        .init(color: .clear, location: 1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                            .ignoresSafeArea(edges: .top)
                            .allowsHitTesting(false)
                    }
                    .environment(\.colorScheme, .dark)
                }
            }
            .sheet(isPresented: .constant(showsControls && showsBottomPanel)) {
                DynamicSheet(animation: .bouncy, size: .xsmall) {
                    BoundaryEditingPanel(
                        boundary: boundary, metrics: metrics, showsMetrics: showsMetricsInPanel, isClosed: isClosed,
                        onUndo: onUndo, onClear: onClear, onConfirm: onConfirm
                    )
                }
                .presentationBackgroundInteraction(.enabled)
                .presentationDragIndicator(.hidden)
                .presentationCompactAdaptation(.sheet)
            }
            .ignoresSafeArea(.container, edges: .bottom)
    }

}

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
#Preview("COdedUI5 · Boundary Layout") {
    BoundaryEditorLayout(
        boundary: GardenPreviewData.boundary, metrics: GardenPreviewData.metrics,
        onClose: {}, onSearch: {}, onUndo: {}, onClear: {}, onConfirm: {}
    ) {
        Color.clear
            .overlay { Image("MappingSatelliteSource").resizable().scaledToFill() }
            .clipped()
    }
}
#endif
