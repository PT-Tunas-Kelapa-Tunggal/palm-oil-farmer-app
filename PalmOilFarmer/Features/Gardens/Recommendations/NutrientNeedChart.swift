import SwiftUI
import Charts

/// Each nutrient as a share of what the garden needs: now (hollow) and after fertilizing (filled).
/// The dashed line marks 100% of the need, so shortfall and excess read against one scale.
struct NutrientNeedChart: View {
    let values: [NutrientProjection]
    /// The report level that equals 100% of the need.
    var need = 0.64
    var onSelect: (String) -> Void = { _ in }

    private static let rowHeight: CGFloat = 48

    private func percent(_ level: Double) -> Double {
        need > 0 ? level / need * 100 : 0
    }

    private var xMaximum: Double {
        let highest = values.flatMap { [percent($0.current), percent($0.target)] }.max() ?? 100
        return max(150, (highest / 50).rounded(.up) * 50)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NutrientLegend()
            HStack(alignment: .top, spacing: 8) {
                // Row labels sit outside the plot so they are never clipped; rows match the plot's bands.
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(values) { value in
                        Button { onSelect(value.name) } label: {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(value.name).font(.subheadline.weight(.semibold))
                                Text(value.status)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(width: 68, height: Self.rowHeight, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Lihat pupuk yang mengandung hara ini")
                    }
                }
                chart
            }
            Text("Ketuk hara untuk melihat pupuk yang mengandungnya.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var chart: some View {
        Chart {
            RuleMark(x: .value("Kebutuhan", 100))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                .foregroundStyle(KropsTheme.secondaryText)
            ForEach(values) { value in
                RuleMark(xStart: .value("Saat ini", percent(value.current)),
                         xEnd: .value("Setelah pemupukan", percent(value.target)),
                         y: .value("Hara", value.name))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    .foregroundStyle(Color(white: 0.75))
                PointMark(x: .value("Saat ini", percent(value.current)), y: .value("Hara", value.name))
                    .symbol {
                        Circle()
                            .strokeBorder(Color(white: 0.45), lineWidth: 2)
                            .background(Circle().fill(Color(uiColor: .systemBackground)))
                            .frame(width: 14, height: 14)
                    }
                PointMark(x: .value("Setelah pemupukan", percent(value.target)), y: .value("Hara", value.name))
                    .symbol {
                        Circle()
                            .fill(KropsTheme.buttonBackground)
                            .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                            .frame(width: 16, height: 16)
                    }
                    .accessibilityLabel(NutrientReference.reference(for: value.name)?.name ?? value.name)
                    .accessibilityValue("\(value.status). Saat ini \(Int(percent(value.current))) persen kebutuhan, setelah pemupukan \(Int(percent(value.target))) persen.")
            }
        }
        .chartXScale(domain: 0...xMaximum)
        .chartXAxis {
            AxisMarks(values: .stride(by: 50)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(uiColor: .separator))
                AxisValueLabel {
                    if let percent = value.as(Double.self) {
                        Text("\(Int(percent))%").font(.caption2)
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartPlotStyle { $0.frame(height: CGFloat(values.count) * Self.rowHeight) }
        .chartGesture { proxy in
            SpatialTapGesture().onEnded { tap in
                if let symbol: String = proxy.value(atY: tap.location.y) { onSelect(symbol) }
            }
        }
    }
}

struct NutrientLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            legendItem("Saat ini") {
                Circle().strokeBorder(Color(white: 0.45), lineWidth: 2).frame(width: 10, height: 10)
            }
            legendItem("Setelah pemupukan") {
                Circle().fill(KropsTheme.buttonBackground).frame(width: 10, height: 10)
            }
            legendItem("Kebutuhan") {
                Rectangle()
                    .stroke(KropsTheme.secondaryText, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    .frame(width: 1, height: 12)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    private func legendItem<Icon: View>(_ title: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 4) {
            icon()
            Text(title)
        }
    }
}

#if DEBUG
#Preview("Nutrient Need Chart", traits: .sizeThatFitsLayout) {
    NutrientNeedChart(values: RecommendationPreviewData.report.nutrients)
        .padding(16)
        .frame(width: 370)
}
#endif
