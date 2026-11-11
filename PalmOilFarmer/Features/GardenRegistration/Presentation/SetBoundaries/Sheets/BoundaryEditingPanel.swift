import SwiftUI

/// Drawing controls: hint text, Urungkan / Hapus Semua, "Simpan Batas Kebun".
struct BoundaryEditingPanel: View {
    let boundary: GardenBoundary
    var metrics: GardenDisplayMetrics? = nil
    var showsMetrics = false
    var isClosed = true
    let onUndo: () -> Void
    let onClear: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 8) {
                        Text(instructions)
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        if showsMetrics {
                            BoundaryMetricsView(boundary: boundary, metrics: metrics, isClosed: isClosed)
                        }
                        if boundary.points.count >= GardenBoundary.minimumMappingPointCount && !boundary.isValid {
                            Text("Batas harus membentuk area tanpa garis berpotongan.")
                                .font(.caption).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height, alignment: .center)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            VStack(spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { editingActions }
                    VStack(spacing: 12) { editingActions }
                }

                RegistrationPrimaryButton(title: "Simpan Batas Kebun", action: onConfirm)
                    .disabled(!boundary.isReadyForMapping)
            }
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
private struct BoundaryEditingPanelPreview: View {
    let boundary: GardenBoundary
    var isClosed = true

    var body: some View {
        SheetPreview(backdrop: "RegistrationDrawingSatellite") {
            DynamicSheet(animation: .bouncy, size: .xsmall) {
                BoundaryEditingPanel(boundary: boundary, isClosed: isClosed,
                                     onUndo: {}, onClear: {}, onConfirm: {})
            }
            .presentationBackgroundInteraction(.enabled)
            .presentationDragIndicator(.hidden)
        }
    }
}

#Preview("Kontrol batas · Kosong") {
    BoundaryEditingPanelPreview(boundary: GardenBoundary(), isClosed: false)
}

#Preview("Kontrol batas · 2 titik") {
    BoundaryEditingPanelPreview(boundary: GardenBoundary(points: Array(GardenPreviewData.boundary.points.prefix(2))),
                                isClosed: false)
}

#Preview("Kontrol batas · Lengkap") {
    BoundaryEditingPanelPreview(boundary: GardenPreviewData.boundary)
}

#Preview("Kontrol batas · Teks besar") {
    BoundaryEditingPanelPreview(boundary: GardenPreviewData.boundary)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
