import SwiftUI

struct FertilizerHistoryCard: View {
    let record: FertilizerRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.name).font(.headline)
            HistoryValueRow(title: "Berat per karung", value: record.bagWeightKg.formatted() + "kg")
            HistoryValueRow(title: "Jumlah karung", value: "\(record.bagCount) karung")
            HistoryValueRow(title: "Dosis", value: record.doseKgPerTree.formatted() + " kg / pohon")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct HarvestHistoryCard: View {
    let record: HarvestRecord

    var body: some View {
        VStack(spacing: 8) {
            HistoryValueRow(title: "Frekuensi panen", value: "\(record.frequencyPerMonth) kali per bulan")
            HistoryValueRow(title: "Rata rata berat (terakhir panen)", value: record.latestWeightKg.formatted() + "kg")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct HistoryValueRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let value: String

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 8))
        layout {
            Text(title)
            if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 4) }
            Text(value).fontWeight(.semibold)
        }
        .font(.subheadline)
        .frame(minHeight: 20)
        .accessibilityElement(children: .combine)
    }
}

struct GardenSectionHeader: View {
    let title: String
    let onEdit: () -> Void

    var body: some View {
        HStack {
            Text(title).font(.title3.weight(.semibold))
            Spacer()
            Button(action: onEdit) {
                Label("Ubah", systemImage: "pencil.line")
                    .font(.subheadline)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 25)
    }
}

#if DEBUG
#Preview("Fertilizer Card", traits: .sizeThatFitsLayout) {
    FertilizerHistoryCard(record: GardenPreviewData.fertilizers[0]).padding().frame(width: 402)
}
#Preview("Harvest Card", traits: .sizeThatFitsLayout) {
    HarvestHistoryCard(record: GardenPreviewData.harvest).padding().frame(width: 402)
}
#Preview("History Row", traits: .sizeThatFitsLayout) {
    HistoryValueRow(title: "Jumlah karung", value: "6 karung").padding().frame(width: 370)
}
#Preview("History Header", traits: .sizeThatFitsLayout) {
    GardenSectionHeader(title: "Riwayat pupuk", onEdit: {}).padding().frame(width: 402)
}
#endif
