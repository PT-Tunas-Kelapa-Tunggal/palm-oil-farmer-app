import SwiftUI

struct GardenProfileSummaryView: View {
    let garden: Garden
    let onClose: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            GardenProfileHeader(onEdit: onEdit, onBack: onClose)
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        GardenProfileSectionHeader(title: "Riwayat Panen")
                        if let harvest = garden.harvestRecord { HarvestSummaryCard(record: harvest) }
                    }
                    VStack(spacing: 16) {
                        GardenProfileSectionHeader(title: "Frekuensi Pemupukan")
                        GardenProfileFieldRow(title: "Frekuensi Pemupukan dalam setahun") {
                            if let frequency = garden.fertilizationFrequencyPerYear {
                                Text(frequency.formatted()).font(.largeTitle.bold()).frame(minWidth: 100)
                            } else {
                                Text("Belum diisi").foregroundStyle(.secondary)
                            }
                        }
                        VStack(spacing: 16) {
                            GardenProfileSectionHeader(title: "Jenis Pupuk", message: "Data pupuk yang diaplikasikan di kebun ini dalam periode pemupukan terakhir")
                            ForEach(garden.fertilizerRecords ?? []) { record in FertilizerSummaryCard(record: record) }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 32)
            }
        }
        .background(GardenProfileStyle.formBackground)
        .presentationDetents([.large]).presentationDragIndicator(.hidden)
        .toolbar(.hidden, for: .navigationBar)
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
