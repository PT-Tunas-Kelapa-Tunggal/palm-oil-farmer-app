import SwiftUI

struct BoundaryEditorLayout<MapContent: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let boundary: GardenBoundary
    var metrics: GardenDisplayMetrics? = nil
    var title = "Buat batas kebun"
    var showsControls = true
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
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                if showsControls {
                    VStack(spacing: 0) {
                        RegistrationHeader(title: title, trailingSymbol: "magnifyingglass",
                                           trailingLabel: "Cari lokasi kebun", onTrailing: onSearch,
                                           onClose: onClose)
                        if !showsMetricsInPanel {
                            BoundaryMetricsView(boundary: boundary, metrics: metrics)
                                .padding(.horizontal, 14)
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if showsControls {
                    BoundaryEditingPanel(
                        boundary: boundary, metrics: metrics, showsMetrics: showsMetricsInPanel,
                        onUndo: onUndo, onClear: onClear, onConfirm: onConfirm
                    )
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
    }

}

struct BoundaryMetricsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let boundary: GardenBoundary
    var metrics: GardenDisplayMetrics? = nil

    private var displayMetrics: GardenDisplayMetrics { metrics ?? GardenDisplayMetrics(boundary: boundary) }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            metric("Luas", value: displayMetrics.area)
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
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(title).font(.footnote)
            Text(value).font(.title3.weight(.medium))
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
