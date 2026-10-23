import SwiftUI

struct FertilizerRecommendationView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let report: FertilizerRecommendationReport
    @State private var selectedTab: RecommendationTab
    @State private var selectedAreaID: String
    @Environment(\.dismiss) private var dismiss

    init(report: FertilizerRecommendationReport, initialTab: RecommendationTab = .nutrients) {
        self.report = report
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
                        NutrientProjectionChart(values: report.nutrients)
                        FertilizerCostTable(lines: report.costs, total: report.totalCost)
                    case .allocation:
                        if let area = selectedArea {
                            Group {
                                if let mapImage = area.mapImage {
                                    Image(mapImage).resizable().scaledToFill()
                                } else {
                                    GardenMapView(boundary: report.boundary)
                                }
                            }
                            .frame(height: 206)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            Menu {
                                ForEach(report.areas) { area in
                                    Button("Area " + area.id) { selectedAreaID = area.id }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text("Area " + area.id).font(.title.weight(.bold))
                                    Image(systemName: "chevron.down").font(.footnote)
                                        .frame(width: 26, height: 26)
                                        .background(.white.opacity(0.3), in: Circle())
                                }
                            }
                            .buttonStyle(.plain)
                            ForEach(area.periods) { period in
                                FertilizerAllocationSection(period: period)
                            }
                        }
                    case .rainfall:
                        ContentUnavailableView("Data curah hujan belum tersedia", systemImage: "cloud.rain")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(values) { value in
                    VStack(spacing: 8) {
                        HStack(alignment: .bottom, spacing: 3) {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.secondary.opacity(0.4), lineWidth: 1)
                                .frame(width: 26, height: 125 * max(0, min(value.current, 1)))
                            UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12)
                                .fill(Color(white: 0.34))
                                .frame(width: 28, height: 125 * max(0, min(value.target, 1)))
                        }
                        .frame(height: 125, alignment: .bottom)
                        Text(value.name).font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(value.name), saat ini \(value.current), target \(value.target)")
                }
            }
            .padding(.top, 8)
            .overlay(alignment: .top) {
                GeometryReader { geometry in
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 53))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: 53))
                    }
                    .stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                }
                .allowsHitTesting(false)
            }
            .overlay(alignment: .top) { Divider().offset(y: 133) }
        }
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
#Preview("Proyeksi Hara") {
    FertilizerRecommendationView(report: RecommendationPreviewData.report)
}
#Preview("Alokasi Pupuk") {
    FertilizerRecommendationView(report: RecommendationPreviewData.report, initialTab: .allocation)
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
