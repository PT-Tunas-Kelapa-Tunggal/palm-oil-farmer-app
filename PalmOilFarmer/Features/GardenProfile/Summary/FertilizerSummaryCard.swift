import SwiftUI

struct FertilizerSummaryCard: View {
    let record: FertilizerRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.composition.map { record.name + " " + $0.label } ?? record.name).font(.headline)
            if let weight = record.bagWeightKg {
                ProfileSummaryRow(title: "Berat per karung", value: weight.formatted() + "kg")
            }
            if let count = record.bagCount {
                ProfileSummaryRow(title: "Jumlah karung", value: "\(count) karung")
            }
            if let magnesium = record.composition?.magnesium, magnesium > 0 {
                ProfileSummaryRow(title: "Magnesium", value: magnesium.formatted() + "%")
            }
            ProfileSummaryRow(title: "Dosis", value: record.doseKgPerTree.formatted() + " kg / pohon")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: record.bagWeightKg == nil && record.bagCount == nil ? nil : 130, alignment: .leading)
        .background(GardenProfileStyle.field, in: RoundedRectangle(cornerRadius: 18))
    }
}

#if DEBUG
#Preview("Ringkasan pupuk · NPK custom", traits: .sizeThatFitsLayout) {
    FertilizerSummaryCard(record: GardenProfileCanvasFixtures.npkRecord)
        .padding().frame(width: 402)
}
#Preview("Ringkasan pupuk · Data karung lama", traits: .sizeThatFitsLayout) {
    FertilizerSummaryCard(record: FertilizerRecord(name: "Urea", bagWeightKg: 50, bagCount: 2, doseKgPerTree: 1.5))
        .padding().frame(width: 402)
}
#endif
