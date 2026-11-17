import SwiftUI

struct HarvestSummaryCard: View {
    let record: HarvestRecord

    var body: some View {
        VStack(spacing: 8) {
            ProfileSummaryRow(title: "Frekuensi panen", value: "\(record.frequencyPerMonth) kali per bulan")
            ProfileSummaryRow(title: "Rata-rata berat panen per bulan", value: record.monthlyWeightKg.formatted() + "kg")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(KropsTheme.surfaceCard, in: RoundedRectangle(cornerRadius: 18))
    }
}

#if DEBUG
#Preview("Ringkasan panen · Bulanan", traits: .sizeThatFitsLayout) {
    HarvestSummaryCard(record: GardenProfileCanvasFixtures.harvestRecord)
        .padding().frame(width: 402)
}
#endif
