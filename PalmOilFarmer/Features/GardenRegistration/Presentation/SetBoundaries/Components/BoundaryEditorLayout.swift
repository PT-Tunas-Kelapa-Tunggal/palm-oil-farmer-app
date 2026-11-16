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
    /// Diisi → tombol X menjadi glass menu "Keluar dari pemetaan?".
    /// Kosong (nil) → tombol X biasa yang langsung memanggil `onClose`.
    var showsExitMenu: Binding<Bool>? = nil
    var onDiscard: () -> Void = {}
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
            .overlay {
                // Selama menu terbuka, ketukan di peta menutup menu, bukan menambah titik.
                if let showsExitMenu, showsExitMenu.wrappedValue {
                    Color.clear
                        .ignoresSafeArea()
                        .collapsesGlassMenu(showsExitMenu)
                }
            }
            .overlay(alignment: .top) {
                if showsControls {
                    VStack(spacing: 12) {
                        RegistrationHeader(title: title, isMapHeader: true,
                                           showsCloseButton: showsExitMenu == nil,
                                           onClose: onClose)
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
                    .overlay(alignment: .topLeading) {
                        if let showsExitMenu {
                            exitMenu(isExpanded: showsExitMenu)
                                .padding(.leading, 16)
                        }
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

    /// Tombol X yang membesar menjadi kartu konfirmasi keluar, bergaya dialog bawaan iOS.
    private func exitMenu(isExpanded: Binding<Bool>) -> some View {
        // Ketukan X tidak langsung membuka kartu: ViewModel yang memutuskan
        // (batas kosong → langsung tutup, sudah ada titik → buka kartu).
        RegistrationDiscardMenu(
            isExpanded: isExpanded,
            title: "Buang batas kebun",
            message: "Batas yang belum disimpan akan hilang.",
            onClose: onClose,
            onDiscard: onDiscard
        )
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

#Preview("Layout editor batas · Menu keluar") {
    BoundaryEditorLayout(
        boundary: GardenPreviewData.boundary, metrics: GardenPreviewData.metrics,
        // Panel bawah dimatikan: sheet menutupi canvas sehingga X dan kartu tidak terlihat.
        showsBottomPanel: false,
        showsExitMenu: .constant(true),
        onClose: {}, onSearch: {}, onUndo: {}, onClear: {}, onConfirm: {}
    ) {
        Color.clear
            .overlay { Image("MappingSatelliteSource").resizable().scaledToFill() }
            .clipped()
    }
}
#endif
