import SwiftUI

struct FertilizerRecommendationView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let report: FertilizerRecommendationReport
    @State private var selectedTab: RecommendationTab
    @State private var selectedAreaID: String
    @State private var reference: NutrientReference?
    @State private var showsAreaPicker = false
    @State private var showsNavigation = false
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
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Proyeksi hara · Seluruh kebun").font(.caption).foregroundStyle(.secondary)
                                Text("Kadar hara setelah pemupukan").font(.headline)
                            }
                            NutrientLegend()
                            NutrientProjectionChart(values: report.nutrients, need: report.nutrientNeed) { symbol in
                                reference = NutrientReference.reference(for: symbol)
                            }
                        }
                        .padding(16)
                        .background(.background, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
                        if !report.nutrientSummary.isEmpty {
                            Text(report.nutrientSummary)
                                .font(.title3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(.background, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
                        }
                        FertilizerCostTable(lines: report.costs, total: report.totalCost)
                    case .allocation:
                        if let area = selectedArea {
                            Group {
                                if area.zone != nil {
                                    AllocationAreaMap(boundary: report.boundary, areas: report.areas, selectedID: area.id)
                                        .allowsHitTesting(false)
                                } else if let mapImage = area.mapImage {
                                    Image(mapImage).resizable().scaledToFill()
                                } else {
                                    GardenMapView(boundary: report.boundary)
                                }
                            }
                            .frame(height: 206)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            HStack {
                                Button { showsAreaPicker = true } label: {
                                    HStack(spacing: 8) {
                                        Text("Area " + area.id).font(.title3.weight(.semibold))
                                        Image(systemName: "chevron.down").font(.footnote.weight(.semibold))
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(minHeight: 44)
                                }
                                .buttonStyle(.glass)
                                .accessibilityHint("Pilih area kebun lain")
                                Spacer()
                                if area.zone != nil {
                                    Button { showsNavigation = true } label: {
                                        Label("Buka Map", systemImage: "figure.walk")
                                            .font(.headline)
                                            .padding(.horizontal, 12)
                                            .frame(minHeight: 44)
                                    }
                                    .buttonStyle(.glass)
                                }
                            }
                            ForEach(area.periods) { period in
                                FertilizerAllocationSection(period: period)
                            }
                        } else {
                            ContentUnavailableView("Area kebun belum tersedia", systemImage: "square.grid.2x2",
                                                   description: Text("Batas kebun belum dapat dibagi menjadi area."))
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
        .sheet(item: $reference) { reference in
            NutrientReferenceView(reference: reference)
        }
        .sheet(isPresented: $showsAreaPicker) {
            AreaPickerView(areas: report.areas, selectedID: selectedAreaID) { selectedAreaID = $0 }
        }
        .fullScreenCover(isPresented: $showsNavigation) {
            AreaNavigationView(boundary: report.boundary, areas: report.areas, selectedID: selectedAreaID)
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

struct NutrientLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            Label { Text("Saat ini") } icon: {
                RoundedRectangle(cornerRadius: 2).strokeBorder(.secondary, lineWidth: 1).frame(width: 10, height: 10)
            }
            Label { Text("Setelah pemupukan") } icon: {
                RoundedRectangle(cornerRadius: 2).fill(Color(white: 0.34)).frame(width: 10, height: 10)
            }
            Label { Text("Kebutuhan") } icon: {
                Rectangle().fill(.secondary).frame(width: 12, height: 1)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .labelStyle(LegendLabelStyle())
    }

    private struct LegendLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack(spacing: 4) { configuration.icon; configuration.title }
        }
    }
}

struct NutrientProjectionChart: View {
    let values: [NutrientProjection]
    var need = 0.64
    var onSelect: (String) -> Void = { _ in }
    private let barHeight: CGFloat = 125

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ForEach(values) { value in
                Button { onSelect(value.name) } label: {
                    VStack(spacing: 4) {
                        HStack(alignment: .bottom, spacing: 3) {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.secondary.opacity(0.4), lineWidth: 1)
                                .frame(width: 26, height: barHeight * max(0, min(value.current, 1)))
                            UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12)
                                .fill(Color(white: 0.34))
                                .frame(width: 28, height: barHeight * max(0, min(value.target, 1)))
                        }
                        .frame(height: barHeight, alignment: .bottom)
                        Divider()
                        Text(value.name).font(.subheadline.weight(.semibold))
                        Text(value.status)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2, reservesSpace: true)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(value.name), \(value.status)")
                .accessibilityHint("Lihat pupuk yang mengandung hara ini")
            }
        }
        .overlay(alignment: .top) {
            GeometryReader { geometry in
                Path { path in
                    let y = barHeight * (1 - need)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
                .stroke(.secondary, style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
            }
            .allowsHitTesting(false)
        }
    }
}

struct RainfallForecastView: View {
    let forecast: RainfallForecast

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Prakiraan hujan · " + forecast.dateRange).font(.caption).foregroundStyle(.secondary)
                    Text(forecast.headline).font(.headline)
                }
                HStack(spacing: 4) {
                    ForEach(forecast.days) { day in
                        VStack(spacing: 6) {
                            Image(systemName: day.isHeavy ? "cloud.heavyrain.fill" : day.millimeters >= 5 ? "cloud.drizzle.fill" : "cloud.sun.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.title3)
                                .frame(height: 28)
                            Text(day.weekday).font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(day.isHeavy ? KropsTheme.secondaryFill : KropsTheme.tertiaryFill,
                                    in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(day.weekday), \(day.isHeavy ? "hujan lebat" : "hujan ringan") \(Int(day.millimeters)) milimeter")
                    }
                }
                RainfallLine(values: forecast.days.map(\.millimeters))
                    .stroke(.secondary, lineWidth: 1.5)
                    .frame(height: 36)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
            Text(forecast.advice)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
        }
    }
}

/// Rain amounts across the week, drawn through the centre of each day column.
struct RainfallLine: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        Path { path in
            guard let maximum = values.max(), maximum > 0, !values.isEmpty else { return }
            let step = rect.width / CGFloat(values.count)
            for (index, value) in values.enumerated() {
                let point = CGPoint(x: rect.minX + step * (CGFloat(index) + 0.5),
                                    y: rect.maxY - rect.height * value / maximum)
                index == 0 ? path.move(to: point) : path.addLine(to: point)
            }
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
#Preview("Curah Hujan") {
    FertilizerRecommendationView(report: RecommendationPreviewData.report, initialTab: .rainfall)
}
#Preview("Nutrient Chart", traits: .sizeThatFitsLayout) {
    NutrientProjectionChart(values: RecommendationPreviewData.report.nutrients).frame(width: 370, height: 190).padding()
}
#Preview("Cost Table", traits: .sizeThatFitsLayout) {
    FertilizerCostTable(lines: RecommendationPreviewData.report.costs, total: "Rp1,435,000").padding(16).frame(width: 402)
}
#Preview("Allocation Section", traits: .sizeThatFitsLayout) {
    FertilizerAllocationSection(period: RecommendationPreviewData.report.areas[0].periods[0]).padding(16).frame(width: 402)
}
#endif
