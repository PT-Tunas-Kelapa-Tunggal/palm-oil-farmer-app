import SwiftUI
import CoreLocation

/// Map chrome while drawing: header and area/perimeter pill on top of any map.
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

#if DEBUG
#Preview("Layout editor batas") {
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
