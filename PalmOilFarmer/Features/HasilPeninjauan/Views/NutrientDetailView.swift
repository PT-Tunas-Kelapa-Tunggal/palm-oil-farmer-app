import SwiftUI

/// One layout for every nutrient; only the content and kilograms change.
struct NutrientDetailView: View {
    let detail: NutrientDetail
    let currentKg: Double
    let needKg: Double
    let history: ReviewHistory

    @Environment(\.dismiss) private var dismiss
    @State private var showsHistory = false

    private var status: NutrientDetail.Status {
        NutrientDetail.Status(currentKg: currentKg, needKg: needKg)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KropsTheme.Spacing.screen) {
                ReviewIconButton(systemImage: "chevron.left", accessibilityLabel: "Kembali",
                                 font: .title3.weight(.medium), size: 48) { dismiss() }
                card
            }
            .padding(KropsTheme.Spacing.screen)
        }
        .scrollIndicators(.hidden)
        .background(KropsTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showsHistory) {
            ReviewHistorySheet(history: history)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: KropsTheme.Spacing.section) {
            VStack(alignment: .leading, spacing: KropsTheme.Spacing.compact) {
                Text("\(detail.name) (\(detail.symbol))").font(.title2.bold())
                Text(detail.role).font(.subheadline)
            }

            VStack(alignment: .leading, spacing: KropsTheme.Spacing.field) {
                HStack(alignment: .top, spacing: KropsTheme.Spacing.screen) {
                    amountColumn("Praktik Saat Ini", kilograms: currentKg, color: .secondary)
                    amountColumn("Kebutuhan", kilograms: needKg, color: .primary)
                }
                Text("Praktik pemupukan Anda sekarang \(Text(status.emphasis).bold()). \(status.advice)")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            fertilizerList
            ReviewActionButton(title: "Lihat Rekomendasi Pemupukan", systemImage: "arrow.right", style: .muted,
                               font: .subheadline.weight(.semibold), minHeight: 44) { showsHistory = true }
        }
        .reviewCard()
    }

    private func amountColumn(_ title: String, kilograms: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            ReviewAmountText(value: kilograms.formatted(), unit: "kg")
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var fertilizerList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Pupuk yang mengandung \(detail.name.lowercased())")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.bottom, KropsTheme.Spacing.compact)
            ForEach(detail.fertilizers) { fertilizer in
                VStack(alignment: .leading, spacing: 4) {
                    Text(fertilizer.name).font(.headline)
                    Text(fertilizer.content).font(.footnote).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, KropsTheme.Spacing.field)
                if fertilizer.id != detail.fertilizers.last?.id { Divider() }
            }
        }
    }

}

#if DEBUG
#Preview("Nitrogen · Kurang") {
    NavigationStack {
        NutrientDetailView(detail: .nitrogen, currentKg: 30, needKg: 50, history: .sample)
    }
}
#Preview("Fosfor · Sesuai") {
    NavigationStack {
        NutrientDetailView(detail: .phosphorus, currentKg: 6, needKg: 6, history: .sample)
    }
}
#Preview("Kalium · Contoh") {
    NavigationStack {
        NutrientDetailView(detail: .potassium, currentKg: 20, needKg: 35, history: .sample)
    }
}
#Preview("Magnesium · Contoh") {
    NavigationStack {
        NutrientDetailView(detail: .magnesium, currentKg: 8, needKg: 25, history: .sample)
    }
}
#Preview("Fosfor · Berlebih") {
    NavigationStack {
        NutrientDetailView(detail: .phosphorus, currentKg: 10, needKg: 6, history: .sample)
    }
}
#endif
