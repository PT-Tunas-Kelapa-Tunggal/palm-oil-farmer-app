import SwiftUI

struct FertilizerRecommendationScreen: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let report: FertilizerRecommendationReport
    var isDemo = false
    var garden: Garden? = nil
    @State private var selectedTab: RecommendationTab
    @State private var selectedAreaID: String
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
                        BoundarySilhouette(points: report.outline)
                            .fill(Color(white: 0.77))
                            .overlay { BoundarySilhouette(points: report.outline).stroke(Color(white: 0.35), lineWidth: 2) }
                            .frame(width: 134, height: 158)
                            .frame(maxWidth: .infinity)
                            .frame(height: 206)
                        if report.nutrients.isEmpty {
                            ContentUnavailableView("Analisis hara belum tersedia", systemImage: "chart.bar",
                                description: Text("Hasil pengukuran dan rekomendasi pupuk belum diterima. Pembagian blok dapat digunakan melalui Alokasi pupuk."))
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Proyeksi hara · Seluruh kebun")
                                    .font(.footnote).foregroundStyle(.secondary)
                                Text("Kadar hara setelah pemupukan").font(.headline)
                                NutrientProjectionChart(values: report.nutrients,
                                                        references: report.nutrientReferences) {
                                    selectedReference = $0
                                }
                            }
                            .padding(16)
                            .background(.background, in: RoundedRectangle(cornerRadius: 24))
                            if let summary = report.nutrientSummary {
                                Text(summary).font(.title3)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                                    .background(.background, in: RoundedRectangle(cornerRadius: 24))
                            }
                        }
                        if !report.costs.isEmpty {
                            FertilizerCostTable(lines: report.costs, total: report.totalCost)
                        }
                    case .allocation:
                        if let garden {
                            FindingBlockView(garden: garden, report: report)
                        } else if let area = selectedArea {
                            Group {
                                if let mapImage = area.mapImage {
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
                                    .font(.title3.weight(.medium))
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                    .glassEffect(.regular.interactive(), in: Capsule())
                                }
                                Spacer()
                                Button { showsAreaMap = true } label: {
                                    Label("Buka Map", systemImage: "figure.walk")
                                        .font(.title3)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(KropsTheme.tertiaryFill, in: Capsule())
                                }
                            }
                            .buttonStyle(.plain)
                            ForEach(area.periods) { period in
                                FertilizerAllocationSection(period: period)
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

struct BoundarySilhouette: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addLines(points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
            path.closeSubpath()
        }
    }
}

struct NutrientProjectionChart: View {
    let values: [NutrientProjection]
    @ScaledMetric(relativeTo: .caption) private var statusHeight = 32
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    var references: [NutrientReference] = []
    var onReference: (NutrientReference) -> Void = { _ in }

    private var maximum: Double {
        max(1, values.map { max($0.current, $0.target, $0.requirement) }.max() ?? 1)
    }

    var body: some View {
        VStack(spacing: 16) {
            legend
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(values) { value in
                    VStack(spacing: 6) {
                        HStack(alignment: .bottom, spacing: 3) {
                            UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
                                .fill(.background)
                                .overlay {
                                    UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
                                        .stroke(.secondary, lineWidth: 1)
                                }
                                .frame(height: height(value.current))
                            UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
                                .fill(Color(white: 0.34))
                                .frame(height: height(value.target))
                        }
                        .frame(height: 125, alignment: .bottom)
                        .overlay {
                            GeometryReader { geometry in
                                Path { path in
                                    let y = 125 - height(value.requirement)
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                                }
                                .stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                            }
                        }
                        .overlay(alignment: .bottom) { Divider() }
                        if let reference = references.first(where: { $0.id == value.name }) {
                            Button(value.name) { onReference(reference) }
                                .font(.subheadline.bold())
                                .buttonStyle(.plain)
                                .accessibilityHint("Lihat referensi pupuk")
                        } else {
                            Text(value.name).font(.subheadline.bold())
                        }
                        Text(value.status ?? "")
                            .font(.caption).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(height: statusHeight, alignment: .top)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("\(value.name), saat ini \(value.current), setelah pemupukan \(value.target), kebutuhan \(value.requirement)")
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private var legend: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            Label {
                Text("Saat ini")
            } icon: { Rectangle().stroke(.secondary).frame(width: 9, height: 9) }
            Label {
                Text("Setelah pemupukan")
            } icon: { Rectangle().fill(Color(white: 0.34)).frame(width: 9, height: 9) }
            Text("┄ Kebutuhan")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func height(_ value: Double) -> CGFloat {
        guard value.isFinite else { return 0 }
        return 125 * max(0, min(value / maximum, 1))
    }
}

struct FertilizerCostTable: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let lines: [FertilizerCostLine]
    let total: String

    var body: some View {
        VStack(spacing: 0) {
            if !dynamicTypeSize.isAccessibilitySize {
                HStack {
                    tableCell("Jenis pupuk", alignment: .leading)
                    tableCell("Jumlah (kg)", alignment: .center)
                    tableCell("Biaya", alignment: .trailing)
                }
                .fontWeight(.semibold)
                .background(Color(uiColor: .systemGray4).opacity(0.6))
            }
            ForEach(lines) { line in
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(line.name).font(.headline)
                        HistoryValueRow(title: "Jumlah (kg)", value: line.quantity)
                        HistoryValueRow(title: "Biaya", value: line.cost)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    Divider()
                } else {
                    HStack {
                        tableCell(line.name, alignment: .leading)
                        tableCell(line.quantity, alignment: .center)
                        tableCell(line.cost, alignment: .trailing)
                    }
                }
            }
            HStack {
                Text("Total")
                Spacer()
                Text(total)
            }
            .fontWeight(.semibold)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 32)
        }
        .font(.subheadline)
        .background(KropsTheme.tertiaryFill.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func tableCell(_ text: String, alignment: Alignment) -> some View {
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: alignment)
            .padding(8)
            .frame(minHeight: 32)
    }
}

struct FertilizerAllocationSection: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let period: FertilizerAllocationPeriod

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout())
        VStack(spacing: 8) {
            layout {
                Text(period.title).font(.headline)
                Spacer()
                Text(period.dateRange).font(.subheadline).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            VStack(spacing: 0) {
                ForEach(period.lines.indices, id: \.self) { index in
                    let line = period.lines[index]
                    layout {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(line.name).font(.headline)
                            Text(line.total).font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(line.dosage).font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 12)
                    .frame(minHeight: 69)
                    if index < period.lines.count - 1 { Divider() }
                }
            }
            .padding(.horizontal, 16)
            .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 24))
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
    FertilizerAllocationSection(period: RecommendationPreviewData.report.areas[0].periods[0]).padding(16).frame(width: 402)
}
#endif
