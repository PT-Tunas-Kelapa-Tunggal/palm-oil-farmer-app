import SwiftUI

/// "Identitas Kebun" page: read-only location, size and planting data.
/// Pushed from Profil Kebun and from Ringkasan Hasil. Sliced from Sketch "Hasil Peninjauan / Identitas Kebun / Locked".
struct GardenIdentityView: View {
    let garden: Garden
    /// The data became the basis of a review result and can no longer change.
    var isLocked = false
    var referenceMapImage: String? = nil
    /// Kept for callers; the native back button pops the page.
    let onBack: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static let locale = Locale(identifier: "id_ID")

    var body: some View {
        let metrics = GardenDisplayMetrics(boundary: garden.boundary)
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // The navigation bar shows "Identitas Kebun" as the large title.
                Text(garden.name).font(.subheadline).foregroundStyle(KropsTheme.labelSecondary)
                GardenMapView(boundary: garden.boundary, referenceImage: referenceMapImage,
                              contentInsets: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                section("Lokasi", message: "Titik tengah kebun yang Anda tandai.") {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wilayah").font(.subheadline).foregroundStyle(KropsTheme.labelSecondary)
                        Text(garden.locationName).font(.headline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
                    .accessibilityElement(children: .combine)
                    Divider()
                    row("Koordinat", value: centerText)
                }
                section("Ukuran Kebun", message: "Dihitung dari batas kebun yang Anda petakan.") {
                    row("Luas", value: metrics.area)
                    Divider()
                    row("Keliling", value: metrics.perimeter)
                    Divider()
                    row("Titik batas", value: "\(garden.boundary.points.count) titik")
                }
                section("Tanaman dan Tanah", message: "Data yang Anda isi saat mendaftarkan kebun.") {
                    row("Tahun tanam", value: plantingText)
                    Divider()
                    row("Jenis tanah", value: garden.soilType.rawValue)
                }
                if isLocked {
                    Text(lockedNote).font(.footnote).foregroundStyle(KropsTheme.labelSecondary)
                }
            }
            .foregroundStyle(KropsTheme.labelPrimary)
            .padding(.horizontal, 16).padding(.top, 4).padding(.bottom, 34)
        }
        .background(KropsTheme.surfaceBackground.ignoresSafeArea())
        .navigationTitle("Identitas Kebun")
        .navigationBarTitleDisplayMode(.large)
        // The profile page behind hides its bar; this page uses the native one (back button, swipe back).
        .toolbar(.visible, for: .navigationBar)
        // The app tints controls orange; bar buttons (‹, Ubah) are black as in Sketch.
        .tint(KropsTheme.labelPrimary)
    }

    private func section<Rows: View>(_ title: String, message: String,
                                     @ViewBuilder rows: () -> Rows) -> some View {
        VStack(spacing: 8) {
            GardenProfileSectionHeader(title: title, message: message)
            VStack(spacing: 0, content: rows)
                .padding(.horizontal, 16)
                .background(KropsTheme.surfaceCard, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private func row(_ title: String, value: String) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            Text(title).font(.body).frame(maxWidth: .infinity, alignment: .leading)
            Text(value).font(.headline).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// Average of the boundary points, shown as "1.104730, 104.121380".
    private var centerText: String {
        let points = garden.boundary.points
        guard !points.isEmpty else { return "—" }
        let latitude = points.map(\.latitude).reduce(0, +) / Double(points.count)
        let longitude = points.map(\.longitude).reduce(0, +) / Double(points.count)
        return String(format: "%.6f, %.6f", latitude, longitude)
    }

    /// "Oktober 2016", or the year alone for gardens saved before the month was asked.
    private var plantingText: String {
        guard let month = garden.plantingMonth, (1...12).contains(month),
              let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: garden.plantingYear, month: month, day: 1))
        else { return String(garden.plantingYear) }
        return date.formatted(.dateTime.month(.wide).year().locale(Self.locale))
    }

    private var lockedNote: String {
        guard let date = garden.review?.date(for: .completed) else {
            return "Data ini dikunci karena menjadi dasar hasil peninjauan."
        }
        let day = date.formatted(.dateTime.day().month(.wide).year().locale(Self.locale))
        return "Data ini dikunci karena menjadi dasar hasil peninjauan yang terbit \(day)."
    }
}

#if DEBUG
#Preview("Identitas kebun · Terkunci") {
    NavigationStack {
        GardenIdentityView(garden: GardenProfileCanvasFixtures.completeGarden, isLocked: true,
                           referenceMapImage: "GardenProfileMap", onBack: {})
    }
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#Preview("Identitas kebun · Teks besar") {
    NavigationStack {
        GardenIdentityView(garden: GardenProfileCanvasFixtures.completeGarden, onBack: {})
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
