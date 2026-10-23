import SwiftUI

struct BoundaryEditorLayout<MapContent: View>: View {
    let boundary: GardenBoundary
    var metrics: GardenDisplayMetrics? = nil
    var isRegionOverview = false
    let onClose: () -> Void
    let onSkip: () -> Void
    let onRecenter: () -> Void
    let onUndo: () -> Void
    let onClear: () -> Void
    let onConfirm: () -> Void
    @ViewBuilder let map: () -> MapContent

    var body: some View {
        let isValid = boundary.isValid
        map()
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 185)
                    .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                VStack(spacing: 0) {
                    ScreenHeader(title: "Buat batas area kebun", onClose: onClose)
                        .foregroundStyle(.white)
                    if boundary.points.isEmpty {
                        Button(action: onSkip) {
                            HStack {
                                Text("Lakukan nanti saat di kebun")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 24)
                            .frame(minHeight: 52)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: Capsule())
                        .padding(.horizontal, 12)
                    }
                }
                .environment(\.colorScheme, .dark)
            }
            .overlay(alignment: .bottom) {
                VStack(alignment: .trailing, spacing: 28) {
                    HStack(spacing: 14) {
                        if isRegionOverview {
                            Text("Menuju ke lokasi saat ini")
                                .font(.footnote)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(.black.opacity(0.65), in: Capsule())
                        }
                        Button(action: onRecenter) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                                .frame(width: 52, height: 52)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: Circle())
                        .accessibilityLabel("Kembali ke lokasi terpilih")
                    }
                    .padding(.trailing, 4)

                    VStack(spacing: 8) {
                        BoundaryMetricsView(boundary: boundary, metrics: metrics)
                        HStack(spacing: 8) {
                            BoundaryActionButton(title: "Urungkan", systemImage: "arrow.uturn.backward",
                                                 isAvailable: !boundary.points.isEmpty, action: onUndo)
                            BoundaryActionButton(title: "Hapus", systemImage: "trash",
                                                 isAvailable: !boundary.points.isEmpty, action: onClear)
                        }
                        BoundaryActionButton(title: "Konfirmasi", systemImage: "checkmark",
                                             isAvailable: isValid, isPrimary: true, action: onConfirm)
                        if boundary.points.count >= 3 && !isValid {
                            Text("Batas harus membentuk area tanpa garis berpotongan.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
                }
                .padding(.horizontal, 8)
                .padding(.bottom, -10)
            }
    }
}

struct BoundaryActionButton: View {
    let title: String
    let systemImage: String
    var isAvailable = true
    var isPrimary = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.body.weight(isPrimary ? .bold : .regular))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 62)
                .glassEffect(
                    .regular.tint(Color(white: isAvailable ? 0.45 : 0.5)).interactive(),
                    in: RoundedRectangle(cornerRadius: 30)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
    }
}

struct BoundaryMetricsView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let boundary: GardenBoundary
    var metrics: GardenDisplayMetrics? = nil

    private var displayMetrics: GardenDisplayMetrics { metrics ?? GardenDisplayMetrics(boundary: boundary) }

    var body: some View {
        let displayMetrics = displayMetrics
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 4))
            : AnyLayout(HStackLayout())
        layout {
            metric("Luas tanah: ", value: displayMetrics.area)
            metric("Perimeter: ", value: displayMetrics.perimeter)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .frame(minHeight: 34)
        .background(.white.opacity(0.15), in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private func metric(_ title: String, value: String) -> some View {
        Text("\(title)\(Text(value).bold())")
            .font(.footnote)
            .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview("Boundary Layout") {
    BoundaryEditorLayout(
        boundary: GardenPreviewData.boundary, metrics: GardenPreviewData.metrics,
        onClose: {}, onSkip: {}, onRecenter: {}, onUndo: {}, onClear: {}, onConfirm: {}
    ) { Image("MappingSatelliteSource").resizable().scaledToFill() }
}
#Preview("Boundary Actions", traits: .sizeThatFitsLayout) {
    HStack {
        BoundaryActionButton(title: "Urungkan", systemImage: "arrow.uturn.backward", action: {})
        BoundaryActionButton(title: "Konfirmasi", systemImage: "checkmark", isPrimary: true, action: {})
    }.padding().frame(width: 402)
}
#Preview("Boundary Metrics", traits: .sizeThatFitsLayout) {
    BoundaryMetricsView(boundary: GardenPreviewData.boundary, metrics: GardenPreviewData.metrics)
        .padding().frame(width: 402).background(.gray)
}
#endif
