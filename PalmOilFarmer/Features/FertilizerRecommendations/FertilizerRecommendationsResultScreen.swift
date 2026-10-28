import SwiftUI

struct FertilizerRecommendationsResultScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FertilizerRecommendationsResultViewModel

    init(recommendation: FertilizerRecommendationsResult) {
        _viewModel = StateObject(wrappedValue: FertilizerRecommendationsResultViewModel(recommendation: recommendation))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: viewModel.farmTitle, systemImage: "chevron.left",
                         subtitle: viewModel.locationLabel, onClose: { dismiss() })
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summary
                    annualProducts
                    Text("Alokasi tahunan per area")
                        .font(.title3.weight(.semibold))
                    if viewModel.zones.isEmpty {
                        ContentUnavailableView("Alokasi area belum tersedia", systemImage: "square.grid.2x2")
                    } else {
                        ForEach(viewModel.zones) { zone in
                            zoneCard(zone)
                        }
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ringkasan tahunan").font(.headline)
            HStack(spacing: 12) {
                summaryMetric(title: "Area", value: viewModel.summaryZoneCount)
                summaryMetric(title: "Pohon", value: viewModel.summaryTreeCount)
            }
            if !viewModel.annualNutrientBoosts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tambahan unsur hara").font(.subheadline.weight(.semibold))
                    ForEach(viewModel.annualNutrientBoosts, id: \.self) { value in
                        Text(value).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private var annualProducts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kebutuhan produk per tahun").font(.headline)
            ForEach(viewModel.annualProductBoosts) { product in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.title).font(.subheadline.weight(.medium))
                        Text("Unsur hara \(product.nutrient)")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    Text(product.zoneMass).font(.subheadline.weight(.semibold))
                }
                .padding(.vertical, 5)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private func zoneCard(_ zone: FertilizerRecommendationsResultViewModel.ZoneRow) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Area \(zone.id)").font(.headline)
                Spacer()
                Text("\(zone.treeCount) pohon · \(zone.area)")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if !zone.nutrientBoosts.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Tambahan unsur hara").font(.subheadline.weight(.medium))
                    ForEach(zone.nutrientBoosts, id: \.self) { value in
                        Text(value).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            if !zone.products.isEmpty {
                Divider()
                ForEach(zone.products) { product in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(product.title).font(.subheadline.weight(.medium))
                            Spacer(minLength: 8)
                            Text(product.zoneMass).font(.subheadline.weight(.semibold))
                        }
                        Text("\(product.nutrient) · \(product.perPalmMass) per pohon / tahun")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.footnote).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 14))
    }
}
