import SwiftUI
import UIKit

struct FertilizerRecommendationScreen: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let report: FertilizerRecommendationReport
    var isDemo = false
    var garden: Garden? = nil
    @State private var selectedTab: RecommendationTab
    @State private var selectedAreaID: String
    @State private var selectedProductOptionIDs: [String: String] = [:]
    @State private var showsAreaPicker = false
    @State private var showsAreaMap = false
    @State private var selectedReference: NutrientReference?
    @Environment(\.dismiss) private var dismiss

    init(report: FertilizerRecommendationReport, initialTab: RecommendationTab = .nutrients, isDemo: Bool = false, garden: Garden? = nil) {
        self.report = report
        self.isDemo = isDemo
        self.garden = garden
        _selectedTab = State(initialValue: initialTab)
        _selectedAreaID = State(initialValue: report.areas.first?.id ?? "")
    }

    private var reportPicker: some View {
        Picker("Informasi kebun", selection: $selectedTab) {
            ForEach(RecommendationTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
    }

    private var selectedArea: FertilizerAllocationArea? {
        report.areas.first { $0.id == selectedAreaID }
    }

    private var nutrientMapPreview: some View {
        Group {
            if let imageName = report.nutrientMapImageName,
               let image = bundledImage(named: imageName) {
                ZoneAnnotatedMap(image: image, areas: report.areas)
                    .accessibilityLabel("Peta kebun dengan batas zona")
            } else {
                boundaryPreview
            }
        }
    }

    private func bundledImage(named imageName: String) -> UIImage? {
        let file = URL(fileURLWithPath: imageName)
        guard let imageURL = Bundle.main.url(
            forResource: file.deletingPathExtension().lastPathComponent,
            withExtension: file.pathExtension
        ) else { return nil }
        return UIImage(contentsOfFile: imageURL.path)
    }

    private func insightText(_ value: String) -> Text {
        if let formatted = try? AttributedString(markdown: value) {
            return Text(formatted)
        }
        return Text(value.replacingOccurrences(of: "**", with: ""))
    }

    private var boundaryPreview: some View {
        BoundarySilhouette(points: report.outline)
            .fill(Color(white: 0.77))
            .overlay { BoundarySilhouette(points: report.outline).stroke(Color(white: 0.35), lineWidth: 2) }
            .frame(width: 134, height: 158)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: report.gardenName, systemImage: "chevron.left",
                         subtitle: report.locationName, onClose: { dismiss() })
            ScrollView {
                VStack(spacing: 24) {
                    if dynamicTypeSize.isAccessibilitySize {
                        reportPicker.pickerStyle(.menu)
                    } else {
                        reportPicker.pickerStyle(.segmented)
                    }

                    switch selectedTab {
                    case .nutrients:
                        nutrientMapPreview
                            .frame(maxWidth: .infinity)
                            .frame(height: 206)
                        if report.nutrients.isEmpty && report.supplementalNutrientProjections.isEmpty {
                            ContentUnavailableView("Analisis hara belum tersedia", systemImage: "chart.bar",
                                description: Text("Hasil pengukuran dan rekomendasi pupuk belum diterima. Pembagian blok dapat digunakan melalui Alokasi pupuk."))
                        } else {
                            if !report.nutrients.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(report.nutrientChartEyebrow ?? "Komposisi pupuk · per 50 kg")
                                        .font(.footnote).foregroundStyle(.secondary)
                                    Text(report.nutrientChartTitle ?? "Komposisi NPK dibanding rekomendasi")
                                        .font(.title2.weight(.semibold))
                                    NutrientProjectionChart(values: report.nutrients,
                                                            references: report.nutrientReferences,
                                                            currentLabel: report.currentNutrientLabel ?? "NPK riwayat",
                                                            targetLabel: report.targetNutrientLabel ?? "Rekomendasi NPKMg",
                                                            requirementLabel: report.nutrientRequirementLabel ?? "Patokan") {
                                        selectedReference = $0
                                    }
                                    if let caption = report.nutrientChartCaption {
                                        Text(caption).font(.footnote).foregroundStyle(.secondary)
                                    }
                                }
                                .padding(16)
                                .background(.background, in: RoundedRectangle(cornerRadius: 24))
                                if let summary = report.nutrientSummary {
                                    insightText(summary).font(.body)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(16)
                                        .background(.background, in: RoundedRectangle(cornerRadius: 24))
                                }
                            }
                            if !report.supplementalNutrientProjections.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Rekomendasi dosis pupuk tunggal")
                                        .font(.footnote).foregroundStyle(.secondary)
                                    Text("Pasokan N dan Mg dari pupuk tunggal")
                                        .font(.title2.weight(.semibold))
                                    NutrientProjectionChart(values: report.supplementalNutrientProjections,
                                                            currentLabel: "Dari riwayat",
                                                            targetLabel: "Kebutuhan tahunan",
                                                            requirementLabel: "Target")
                                    Text("Grafik menggabungkan Urea/ZA untuk N, serta Dolomit/Kieserit untuk Mg.")
                                        .font(.footnote).foregroundStyle(.secondary)
                                }
                                .padding(16)
                                .background(.background, in: RoundedRectangle(cornerRadius: 24))
                                if let summary = report.singleFertilizerSummary {
                                    insightText(summary).font(.body)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(16)
                                        .background(.background, in: RoundedRectangle(cornerRadius: 24))
                                }
                            }
                        }
                        if !report.costs.isEmpty {
                            FertilizerCostTable(lines: report.costs, total: report.totalCost)
                        }
                    case .allocation:
                        if let garden, isDemo, report.nutrientMapImageName == nil {
                            FindingBlockView(garden: garden, report: report)
                        } else if let area = selectedArea {
                            Group {
                                if let imageName = report.nutrientMapImageName,
                                   let image = bundledImage(named: imageName) {
                                    ZoneAnnotatedMap(image: image, areas: report.areas)
                                } else if let path = area.mapImage, let image = UIImage(contentsOfFile: path) {
                                    Image(uiImage: image).resizable().scaledToFill()
                                } else if let mapImage = area.mapImage, !mapImage.hasPrefix("/") {
                                    Image(mapImage).resizable().scaledToFill()
                                } else {
                                    AllocationOverviewMap(boundary: report.boundary, areas: report.areas,
                                                          selectedAreaID: area.id)
                                }
                            }
                            .frame(height: 206)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            HStack {
                                Button { showsAreaPicker = true } label: {
                                    HStack {
                                        Text("Area " + area.id)
                                        Image(systemName: "chevron.down").font(.footnote)
                                    }
                                    .font(.title3.weight(.semibold))
                                    .padding(.horizontal, 18).padding(.vertical, 14)
                                    .frame(minHeight: 56)
                                    .glassEffect(.regular.interactive(), in: Capsule())
                                }
                                Spacer()
                                if report.nutrientMapImageName == nil {
                                    Button { showsAreaMap = true } label: {
                                        Label("Buka Map", systemImage: "figure.walk")
                                            .font(.title3)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(KropsTheme.tertiaryFill, in: Capsule())
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            ForEach(area.periods) { period in
                                FertilizerAllocationSection(
                                    period: period,
                                    areaID: area.id,
                                    selectedOptionIDs: $selectedProductOptionIDs
                                )
                            }
                        }
                    case .rainfall:
                        if let rainfall = report.rainfall {
                            RainfallForecastView(forecast: rainfall)
                        } else {
                            ContentUnavailableView("Data curah hujan belum tersedia", systemImage: "cloud.rain")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedReference) { reference in
            NutrientReferenceScreen(reference: reference)
        }
        .sheet(isPresented: $showsAreaPicker) {
            RecommendationAreaPickerScreen(areas: report.areas, selectedAreaID: $selectedAreaID)
        }
        .fullScreenCover(isPresented: $showsAreaMap) {
            if let selectedArea {
                RecommendationAreaMapScreen(boundary: report.boundary, areas: report.areas,
                                          selectedArea: selectedArea)
            }
        }
    }
}

#if DEBUG
#Preview("Hasil lokal · Kebun aktif") {
    let garden = GardenPreviewData.completedGarden
    FertilizerRecommendationScreen(report: .local(for: garden), initialTab: .allocation, garden: garden)
}
#Preview("Proyeksi Hara") {
    FertilizerRecommendationScreen(report: RecommendationPreviewData.report)
}
#Preview("Curah Hujan") {
    FertilizerRecommendationScreen(report: RecommendationPreviewData.report, initialTab: .rainfall)
}
#Preview("Alokasi Pupuk") {
    FertilizerRecommendationScreen(report: RecommendationPreviewData.report, initialTab: .allocation)
}
#Preview("Nutrient Chart", traits: .sizeThatFitsLayout) {
    NutrientProjectionChart(values: RecommendationPreviewData.report.nutrients).frame(width: 370, height: 170).padding()
}
#Preview("Cost Table", traits: .sizeThatFitsLayout) {
    FertilizerCostTable(lines: RecommendationPreviewData.report.costs, total: "Rp1,435,000").padding(16).frame(width: 402)
}
#Preview("Allocation Section", traits: .sizeThatFitsLayout) {
    @Previewable @State var selectedOptionIDs: [String: String] = [:]
    let area = RecommendationPreviewData.report.areas[0]
    FertilizerAllocationSection(
        period: area.periods[0],
        areaID: area.id,
        selectedOptionIDs: $selectedOptionIDs
    )
    .padding(16)
    .frame(width: 402)
}
#endif
