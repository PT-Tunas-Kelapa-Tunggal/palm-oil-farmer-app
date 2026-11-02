import SwiftUI

struct ReviewHistorySheet: View {
    let history: ReviewHistory
    var onEditFertilizers: () -> Void = {}
    var onEditHarvest: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: KropsTheme.Spacing.section) {
                    fertilizerSection
                    frequencyCard
                    harvestSection
                }
                .padding(KropsTheme.Spacing.screen)
            }
            .scrollIndicators(.hidden)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.background)
    }

    private var header: some View {
        ZStack {
            Text("Riwayat Kebun")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 52)
            HStack {
                ReviewIconButton(systemImage: "xmark", accessibilityLabel: "Tutup") { dismiss() }
                Spacer()
            }
        }
        .padding(.horizontal, KropsTheme.Spacing.field)
        .padding(.top, KropsTheme.Spacing.field)
    }

    private var fertilizerSection: some View {
        VStack(spacing: KropsTheme.Spacing.compact) {
            ReviewSectionHeader(title: "Riwayat pupuk", titleFont: .title3.weight(.semibold),
                                editAccessibilityLabel: "Ubah riwayat pupuk", onEdit: onEditFertilizers)
            ForEach(history.fertilizers) { fertilizer in
                card {
                    Text(fertilizer.name)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    valueRow("Berat per karung", value: fertilizer.bagWeight)
                    valueRow("Jumlah karung", value: fertilizer.bagCount)
                    valueRow("Dosis", value: fertilizer.dose)
                }
            }
        }
    }

    private var frequencyCard: some View {
        card {
            HStack(spacing: KropsTheme.Spacing.screen) {
                Text("Frekuensi Pemupukan dalam setahun")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(history.fertilizingFrequency)")
                    .font(.title2.bold())
                    .frame(minWidth: 64)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var harvestSection: some View {
        VStack(spacing: KropsTheme.Spacing.compact) {
            ReviewSectionHeader(title: "Riwayat Panen", titleFont: .title3.weight(.semibold),
                                editAccessibilityLabel: "Ubah riwayat panen", onEdit: onEditHarvest)
            card {
                valueRow("Frekuensi panen", value: history.harvestFrequency)
                valueRow("Rata-rata berat panen per bulan", value: history.averageHarvest)
            }
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: KropsTheme.Spacing.compact) {
            content()
        }
        .reviewCard(padding: KropsTheme.Spacing.screen, fill: KropsTheme.secondaryFill,
                    cornerRadius: KropsTheme.Radius.metric)
    }

    @ViewBuilder
    private func valueRow(_ title: String, value: String) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline)
                Text(value).font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: KropsTheme.Spacing.compact) {
                Text(title).font(.subheadline)
                Spacer(minLength: 0)
                Text(value).font(.subheadline.weight(.semibold))
            }
            .accessibilityElement(children: .combine)
        }
    }
}

#if DEBUG
#Preview("Riwayat Kebun") {
    Color.clear.sheet(isPresented: .constant(true)) {
        ReviewHistorySheet(history: .sample)
    }
}
#endif
