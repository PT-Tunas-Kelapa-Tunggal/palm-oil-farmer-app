import SwiftUI

struct BoundaryEditingPanel: View {
    let boundary: GardenBoundary
    var metrics: GardenDisplayMetrics? = nil
    var showsMetrics = false
    var isClosed = true
    let onUndo: () -> Void
    let onClear: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        MapBottomPanel(insets: EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16)) {
            VStack(spacing: 12) {
                Text(instructions)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if showsMetrics {
                    BoundaryMetricsView(boundary: boundary, metrics: metrics, isClosed: isClosed)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { editingActions }
                    VStack(spacing: 8) { editingActions }
                }
                RegistrationPrimaryButton(title: "Simpan Batas Kebun", action: onConfirm)
                    .disabled(!boundary.isReadyForMapping)
                if boundary.points.count >= GardenBoundary.minimumMappingPointCount && !boundary.isValid {
                    Text("Batas harus membentuk area tanpa garis berpotongan.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var instructions: String {
        let remaining = GardenBoundary.minimumMappingPointCount - boundary.points.count
        if boundary.points.isEmpty {
            return "Ketuk peta untuk menandai minimal \(GardenBoundary.minimumMappingPointCount) sudut kebun."
        }
        if remaining > 0 {
            return "Tambahkan \(remaining) sudut lagi. Geser titik untuk menyesuaikan posisinya."
        }
        return "Periksa batas kebun. Geser titik atau tambahkan sudut sebelum disimpan."
    }

    @ViewBuilder
    private var editingActions: some View {
        BoundaryActionButton(title: "Urungkan", systemImage: "arrow.uturn.backward",
                             isAvailable: !boundary.points.isEmpty, action: onUndo)
        BoundaryActionButton(title: "Hapus Semua", systemImage: "trash",
                             isAvailable: !boundary.points.isEmpty, isDestructive: true, action: onClear)
    }
}

private struct BoundaryActionButton: View {
    let title: String
    let systemImage: String
    var isAvailable = true
    var isDestructive = false
    let action: () -> Void

    var body: some View {
        Button(role: isDestructive ? .destructive : nil, action: action) {
            Label(title, systemImage: systemImage)
                .font(.body)
                .fixedSize(horizontal: true, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 48)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isDestructive ? Color(uiColor: .systemRed) : .primary)
        .glassEffect(.regular.interactive(), in: Capsule())
        .disabled(!isAvailable)
    }
}

#if DEBUG
#Preview("Kontrol batas kebun") {
    Color.gray
        .overlay(alignment: .bottom) {
            BoundaryEditingPanel(boundary: GardenPreviewData.boundary, metrics: GardenPreviewData.metrics,
                                 onUndo: {}, onClear: {}, onConfirm: {})
        }
        .ignoresSafeArea(.container, edges: .bottom)
}
#Preview("Kontrol batas kebun · Teks besar") {
    Color.gray
        .overlay(alignment: .bottom) {
            BoundaryEditingPanel(boundary: GardenPreviewData.boundary, metrics: GardenPreviewData.metrics,
                                 onUndo: {}, onClear: {}, onConfirm: {})
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
