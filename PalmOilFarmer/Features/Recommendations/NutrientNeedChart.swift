import SwiftUI
import Charts

/// Each nutrient as a share of what the garden needs, now and after fertilizing, as paired bars.
/// The dashed line marks 100% of the need, so shortfall and excess read against one scale.
struct NutrientNeedChart: View {
    let values: [NutrientProjection]
    /// The report level that equals 100% of the need.
    var need = 0.64
    var onSelect: (String) -> Void = { _ in }

    private static let currentFill = KropsTheme.Chart.current
    private static let targetFill = KropsTheme.Chart.target

    /// Shortfall reads as a warning and excess as the accent; the status word itself carries the meaning.
    static func statusColor(_ status: String) -> Color {
        switch status {
        case "Kurang", "Sangat kurang": KropsTheme.warningText
        case "Berlebih": KropsTheme.accent
        default: KropsTheme.primaryText
        }
    }

    private func percent(_ level: Double) -> Double {
        need > 0 ? level / need * 100 : 0
    }

    private var yMaximum: Double {
        let highest = values.flatMap { [percent($0.current), percent($0.target)] }.max() ?? 100
        return max(150, (highest / 50).rounded(.up) * 50)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NutrientLegend()
            Chart {
                ForEach(values) { value in
                    BarMark(x: .value("Hara", value.name), y: .value("Kadar", percent(value.current)),
                            width: .fixed(22))
                        .position(by: .value("Waktu", "Saat ini"), axis: .horizontal, span: .ratio(0.7))
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4))
                        .foregroundStyle(Self.currentFill)
                        .accessibilityLabel("\(value.name) saat ini")
                        .accessibilityValue("\(Int(percent(value.current))) persen kebutuhan, \(value.status)")
                    BarMark(x: .value("Hara", value.name), y: .value("Kadar", percent(value.target)),
                            width: .fixed(22))
                        .position(by: .value("Waktu", "Setelah pemupukan"), axis: .horizontal, span: .ratio(0.7))
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4))
                        .foregroundStyle(Self.targetFill)
                        .accessibilityLabel("\(value.name) setelah pemupukan")
                        .accessibilityValue("\(Int(percent(value.target))) persen kebutuhan")
                }
                RuleMark(y: .value("Kebutuhan", 100))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    .foregroundStyle(KropsTheme.secondaryText)
            }
            .chartYScale(domain: 0...yMaximum)
            .chartYAxis {
                AxisMarks(position: .leading, values: .stride(by: 50)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(KropsTheme.separatorDefault)
                    AxisValueLabel {
                        if let percent = value.as(Double.self) {
                            Text("\(Int(percent))%").font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel(centered: true) {
                        if let symbol = value.as(String.self) {
                            VStack(spacing: 0) {
                                Text(symbol)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.primary)
                                let status = values.first { $0.name == symbol }?.status ?? ""
                                Text(status)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(Self.statusColor(status))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2, reservesSpace: true)
                            }
                        }
                    }
                }
            }
            .chartGesture { proxy in
                SpatialTapGesture().onEnded { tap in
                    if let symbol: String = proxy.value(atX: tap.location.x) { onSelect(symbol) }
                }
            }
            .frame(height: 220)
            Text("Ketuk hara untuk melihat pupuk yang mengandungnya.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct NutrientLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            legendItem("Saat ini") {
                RoundedRectangle(cornerRadius: 2).fill(KropsTheme.Chart.current).frame(width: 10, height: 10)
            }
            legendItem("Setelah pemupukan") {
                RoundedRectangle(cornerRadius: 2).fill(KropsTheme.Chart.target).frame(width: 10, height: 10)
            }
            legendItem("Kebutuhan") {
                Rectangle()
                    .stroke(KropsTheme.secondaryText, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    .frame(width: 14, height: 1)
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
