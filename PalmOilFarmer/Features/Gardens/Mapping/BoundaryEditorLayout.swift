import SwiftUI

struct BoundaryEditorLayout<MapContent: View>: View {
    let boundary: GardenBoundary
    var metrics: GardenDisplayMetrics? = nil
    var isRegionOverview = false
    var title = "Buat batas kebun"
    /// Shown above the map while no point has been placed.
    var hint: String? = nil
    var showsControls = true
    let onClose: () -> Void
    /// Offers "Lakukan Nanti" while no point has been placed.
    var onSkip: (() -> Void)? = nil
    var onSearch: (() -> Void)? = nil
    let onRecenter: () -> Void
    let onUndo: () -> Void
    let onClear: () -> Void
    let onConfirm: () -> Void
    @ViewBuilder let map: () -> MapContent

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                map()
                    .frame(width: geometry.size.width,
                           height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom)
                    .clipped()
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .frame(height: 185)
                            .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
                            .allowsHitTesting(false)
                    }
                    .ignoresSafeArea()
                VStack(spacing: 0) {
                    header
                    Spacer(minLength: 16)
                    if showsControls { controls(isValid: boundary.isValid) }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: showsControls ? title : "", onClose: onClose)
                .overlay(alignment: .trailing) {
                    if showsControls, let onSearch {
                        Button(action: onSearch) {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: Circle())
                        .accessibilityLabel("Cari lokasi lain")
                        .padding(.trailing, 12)
                    }
                }
            if showsControls {
                BoundaryMetricsView(boundary: boundary, metrics: metrics)
                    .padding(.horizontal, 54)
                if boundary.points.isEmpty, let hint {
                    Text(hint)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal, 32)
                        .padding(.top, 12)
                }
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private func controls(isValid: Bool) -> some View {
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
                .accessibilityLabel("Ke posisi saya")
            }
            .padding(.trailing, 4)

            VStack(spacing: 16) {
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
            if boundary.points.isEmpty, let onSkip {
                Button("Lakukan nanti", action: onSkip)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .glassEffect(.regular.interactive(), in: Capsule())
            }
        }
        .padding(.horizontal, 34)
        .padding(.bottom, 8)
        .environment(\.colorScheme, .dark)
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
                .frame(minHeight: 48)
                .glassEffect(
                    .regular.tint(isPrimary ? Color(white: 0.3) : Color.white.opacity(0.12)).interactive(),
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
            metric("Luas lahan", value: displayMetrics.area)
            metric("Keliling kebun", value: displayMetrics.perimeter)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title).font(.caption)
            Text(value).font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
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
