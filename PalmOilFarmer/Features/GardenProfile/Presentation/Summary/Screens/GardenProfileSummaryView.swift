import SwiftUI

/// "Riwayat Panen dan Pemupukan" page. "Ubah" opens the profile editor.
struct GardenProfileSummaryView: View {
    let garden: Garden
    var metrics: GardenDisplayMetrics? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onClose: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            GardenProfileHeader(title: "", onEdit: onEdit, onBack: onClose)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profil Kebun").font(.largeTitle.bold())
                        Text(subtitle)
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2), spacing: 16) {
                        metric("Panen", detail: "kali per bulan", value: garden.harvestRecord.map { String($0.frequencyPerMonth) } ?? "—", symbol: "calendar", colors: [.init(red: 0.28, green: 0.75, blue: 0.40), .init(red: 0.15, green: 0.62, blue: 0.29)])
                        metric("Hasil panen", detail: "kg per bulan", value: garden.harvestRecord.map { $0.monthlyWeightKg.formatted() } ?? "—", symbol: "chart.xyaxis.line", colors: [.init(red: 0.72, green: 0.62, blue: 0), .init(red: 0.64, green: 0.56, blue: 0)])
                        metric("Pemupukan", detail: "kali per tahun", value: garden.fertilizationFrequencyPerYear.map(String.init) ?? "—", symbol: "rectangle.stack", colors: [.init(red: 0.94, green: 0.52, blue: 0.29), .init(red: 0.88, green: 0.41, blue: 0.14)])
                        metric("Jenis pupuk", detail: (garden.fertilizerRecords ?? []).map(\.name).joined(separator: " dan "), value: String(garden.fertilizerRecords?.count ?? 0), symbol: "sprout", colors: [.init(red: 0.68, green: 0.68, blue: 0.70), .init(red: 0.56, green: 0.56, blue: 0.58)])
                    }
                    VStack(spacing: 8) {
                        GardenProfileSectionHeader(title: "Pupuk yang Diberikan", message: "Pupuk dan dosis pada pemupukan terakhir.")
                        ForEach(garden.fertilizerRecords ?? []) { record in FertilizerSummaryCard(record: record) }
                    }
                    Text("Data ini berasal dari isian Anda. Rekomendasi pupuk akan tersedia setelah kebun ditinjau.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 34)
            }
        }
        .background(KropsTheme.surfaceBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
    private var subtitle: String {
        let identity = "\(garden.name) · \((metrics ?? GardenDisplayMetrics(boundary: garden.boundary)).area)"
        guard let updatedAt = garden.profileUpdatedAt else { return identity }
        let date = updatedAt.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "id_ID")))
        return identity + " · Diperbarui " + date
    }

    private func metric(_ title: String, detail: String, value: String, symbol: String, colors: [Color]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                if symbol == "sprout" {
                    Image("ProfileSeedling").resizable().scaledToFit().frame(width: 24, height: 24)
                } else {
                    Image(systemName: symbol).font(.title2)
                }
                Spacer(minLength: 4)
                Text(value).font(.title.bold()).minimumScaleFactor(0.7).lineLimit(1)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).opacity(0.85)
            }
        }
        .foregroundStyle(.white).padding(16)
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
        .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20))
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
