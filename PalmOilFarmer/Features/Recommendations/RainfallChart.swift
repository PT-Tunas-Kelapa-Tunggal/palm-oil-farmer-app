import SwiftUI
import Charts

/// Daily rain for the week as bars, with the heavy-rain threshold as a reference line.
struct RainfallChart: View {
    let days: [RainfallDay]
    @State private var selectedWeekday: String?

    private var yMaximum: Double {
        max(RainfallDay.heavyThreshold * 1.5, (days.map(\.millimeters).max() ?? 0) * 1.15)
    }

    var body: some View {
        Chart {
            RuleMark(y: .value("Batas hujan lebat", RainfallDay.heavyThreshold))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 4]))
                .foregroundStyle(KropsTheme.secondaryText)
                .annotation(position: .top, alignment: .leading, spacing: 2) {
                    Text("Hujan lebat")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            ForEach(days) { day in
                BarMark(x: .value("Hari", day.weekday), y: .value("Curah hujan", day.millimeters),
                        width: .ratio(0.55))
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4))
                    .foregroundStyle(day.isHeavy ? KropsTheme.Chart.heavyRain : KropsTheme.Chart.lightRain)
                    .opacity(selectedWeekday == nil || selectedWeekday == day.weekday ? 1 : 0.35)
                    .annotation(position: .top, spacing: 4) {
                        if day.isHeavy || selectedWeekday == day.weekday {
                            Text("\(day.millimeters.formatted()) mm")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .accessibilityLabel(day.weekday)
                    .accessibilityValue("\(day.millimeters.formatted()) milimeter, \(day.intensity)")
            }
        }
        .chartYScale(domain: 0...yMaximum)
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 10)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(uiColor: .separator))
                AxisValueLabel {
                    if let millimeters = value.as(Double.self) {
                        Text(millimeters == 0 ? "0" : "\(millimeters.formatted())").font(.caption2)
                    }
                }
            }
        }
        .chartYAxisLabel("mm", position: .topLeading)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel(centered: true) {
                    if let weekday = value.as(String.self), let day = days.first(where: { $0.weekday == weekday }) {
                        VStack(spacing: 4) {
                            Image(systemName: day.symbol)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color.secondary,
                                                 day.millimeters >= 5 ? KropsTheme.Chart.lightRain : Color.orange)
                                .font(.body)
                            Text(weekday).font(.caption2)
                        }
                        .foregroundStyle(day.isHeavy ? .primary : .secondary)
                    }
                }
            }
        }
        .chartXSelection(value: $selectedWeekday)
        .frame(height: 210)
    }
}

extension RainfallDay {
    static let heavyThreshold = 20.0

    var symbol: String {
        isHeavy ? "cloud.heavyrain.fill" : millimeters >= 5 ? "cloud.drizzle.fill" : "cloud.sun.fill"
    }

    var intensity: String {
        isHeavy ? "hujan lebat" : millimeters >= 5 ? "hujan ringan" : "cerah berawan"
    }
}

#if DEBUG
#Preview("Rainfall Chart", traits: .sizeThatFitsLayout) {
    RainfallChart(days: DemoReviewReport.rainfall(startingFrom: .now).days)
        .padding(16)
        .frame(width: 370)
}
#endif
