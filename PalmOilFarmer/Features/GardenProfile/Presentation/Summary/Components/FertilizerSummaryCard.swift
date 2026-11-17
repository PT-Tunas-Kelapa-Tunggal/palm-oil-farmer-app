import SwiftUI

struct FertilizerSummaryCard: View {
    let record: FertilizerRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { title; category }
                    VStack(alignment: .leading, spacing: 8) { title; category }
                }
                HStack(spacing: 6) {
                    if let composition = record.composition {
                        nutrient("N", value: composition.nitrogen)
                        nutrient("P", value: composition.phosphorus)
                        nutrient("K", value: composition.potassium)
                        if let magnesium = composition.magnesium, magnesium > 0 { nutrient("Mg", value: magnesium) }
                    } else if FertilizerCatalogue.kind(for: record.name) == .urea {
                        nutrient("N", value: 46)
                    }
                }
            }.padding(.top, 16).padding(.bottom, 17)
            Divider()
            HStack {
                Text("Dosis per pohon")
                Spacer()
                Text(record.doseKgPerTree.formatted(.number.precision(.fractionLength(1))) + " kg").fontWeight(.semibold)
            }.font(.body).padding(.vertical, 14)
            if let weight = record.bagWeightKg {
                ProfileSummaryRow(title: "Berat per karung", value: weight.formatted() + " kg").padding(.bottom, 8)
            }
            if let count = record.bagCount {
                ProfileSummaryRow(title: "Jumlah karung", value: "\(count) karung").padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
        .background(KropsTheme.surfaceCard, in: RoundedRectangle(cornerRadius: 20))
    }

    private var title: some View {
        Text(record.composition.map { record.name.hasPrefix("NPK ") ? record.name : record.name + " " + $0.label } ?? record.name)
            .font(.title2.bold())
    }

    private var category: some View {
        Text(record.name.hasPrefix("NPK") ? "Majemuk" : "Tunggal")
            .font(.footnote.weight(.medium)).foregroundStyle(.secondary)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(KropsTheme.fillBlack4, in: Capsule())
    }

    @ViewBuilder
    private func nutrient(_ label: String, value: Double?) -> some View {
        if let value {
            Text("\(label) \(value.formatted())%")
                .font(.footnote.weight(.medium)).foregroundStyle(KropsTheme.labelPrimary)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(KropsTheme.fillBlack4, in: Capsule())
        }
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
