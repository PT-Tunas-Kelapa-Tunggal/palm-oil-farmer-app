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
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(KropsTheme.secondaryFill, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tutup")
                Spacer()
            }
        }
        .padding(.horizontal, KropsTheme.Spacing.field)
        .padding(.top, KropsTheme.Spacing.field)
    }

    private var fertilizerSection: some View {
        VStack(spacing: KropsTheme.Spacing.compact) {
            sectionHeader("Riwayat pupuk", accessibilityLabel: "Ubah riwayat pupuk", action: onEditFertilizers)
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
            sectionHeader("Riwayat Panen", accessibilityLabel: "Ubah riwayat panen", action: onEditHarvest)
            card {
                valueRow("Frekuensi panen", value: history.harvestFrequency)
                valueRow("Rata-rata berat panen per bulan", value: history.averageHarvest)
            }
        }
    }

    private func sectionHeader(_ title: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
            : AnyLayout(HStackLayout())
        return layout {
            Text(title)
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: KropsTheme.Spacing.compact)
            }
            Button(action: action) {
                Label("Ubah", systemImage: "pencil.line")
                    .labelStyle(.titleAndIcon)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, KropsTheme.Spacing.compact)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: KropsTheme.Spacing.compact) {
            content()
        }
        .padding(KropsTheme.Spacing.screen)
        .frame(maxWidth: .infinity)
        .background(KropsTheme.secondaryFill, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.metric))
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
