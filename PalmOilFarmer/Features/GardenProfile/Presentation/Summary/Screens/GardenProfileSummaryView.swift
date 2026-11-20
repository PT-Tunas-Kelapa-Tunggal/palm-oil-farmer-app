import SwiftUI

/// "Riwayat Panen dan Pemupukan" page. "Ubah" opens the profile editor.
/// Sliced from Sketch "Profil Kebun / Profil Kebun / Default".
struct GardenProfileSummaryView: View {
    let garden: Garden
    var metrics: GardenDisplayMetrics? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onClose: () -> Void
    let onEdit: () -> Void
    /// Shown under the subtitle after saving from this page ("Profil kebun baru saja diperbarui").
    var savedNotice: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            GardenProfileHeader(title: "", onEdit: onEdit, onBack: onClose)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Riwayat Panen dan Pemupukan").font(.largeTitle.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text(subtitle)
                            .font(.subheadline).foregroundStyle(KropsTheme.labelSecondary)
                        if let savedNotice {
                            GardenSavedNotice(text: savedNotice).padding(.top, 8)
                        }
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2), spacing: 16) {
                        metric("Panen", detail: "kali per bulan", value: garden.harvestRecord.map { String($0.frequencyPerMonth) } ?? "—", symbol: "calendar")
                        metric("Hasil panen", detail: "kg per bulan", value: garden.harvestRecord.map { $0.monthlyWeightKg.formatted() } ?? "—", symbol: "chart.line.uptrend.xyaxis")
                        metric("Pemupukan", detail: "kali per tahun", value: garden.fertilizationFrequencyPerYear.map(String.init) ?? "—", symbol: "rectangle.stack")
                        metric("Jenis pupuk", detail: (garden.fertilizerRecords ?? []).map(\.name).joined(separator: " dan "), value: String(garden.fertilizerRecords?.count ?? 0), symbol: "sprout")
                    }
                    VStack(spacing: 8) {
                        GardenProfileSectionHeader(title: "Pupuk yang Diberikan", message: "Pupuk dan dosis pada pemupukan terakhir.")
                        ForEach(garden.fertilizerRecords ?? []) { record in FertilizerSummaryCard(record: record) }
                    }
                    Text("Data ini berasal dari isian Anda. Rekomendasi pupuk akan tersedia setelah kebun ditinjau.")
                        .font(.footnote).foregroundStyle(KropsTheme.labelSecondary)
                }
                .padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 34)
            }
        }
        .background(KropsTheme.surfaceBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
    /// "Kebun Belakang Rumah, diperbarui 7 November 2026"
    private var subtitle: String {
        let name = garden.name.lowercased().hasPrefix("kebun") ? garden.name : "Kebun " + garden.name
        guard let updatedAt = garden.profileUpdatedAt else { return name }
        let date = updatedAt.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "id_ID")))
        return name + ", diperbarui " + date
    }

    private func metric(_ title: String, detail: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                if symbol == "sprout" {
                    Image("ProfileSeedling").resizable().scaledToFit().frame(width: 24, height: 24)
                } else {
                    Image(systemName: symbol).font(.title2)
                }
                Spacer(minLength: 0)
                Text(value).font(.title.bold()).minimumScaleFactor(0.7).lineLimit(1)
            }
            .padding(.bottom, 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline)
            }
        }
        .foregroundStyle(KropsTheme.labelInversePrimary).padding(14)
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
        .background(
            LinearGradient(colors: [KropsTheme.surfaceInverse, KropsTheme.surfaceInverseRaised],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .accessibilityElement(children: .combine)
    }

}

#if DEBUG
#Preview("Ringkasan profil · Lengkap") {
    GardenProfileSummaryView(garden: GardenProfileCanvasFixtures.completeGarden, onClose: {}, onEdit: {})
        .environment(\.locale, Locale(identifier: "id_ID"))
}
#Preview("Ringkasan profil · Teks besar") {
    GardenProfileSummaryView(garden: GardenProfileCanvasFixtures.completeGarden, onClose: {}, onEdit: {})
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
