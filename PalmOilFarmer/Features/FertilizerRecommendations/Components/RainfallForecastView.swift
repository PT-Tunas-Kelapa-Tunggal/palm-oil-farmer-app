import SwiftUI
import Charts

struct RainfallForecastView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let forecast: RainfallForecast

    private var upperBound: Double {
        let maximum = forecast.days.map(\.precipitationMillimeters).max() ?? 0
        return max(40, (maximum / 10).rounded(.up) * 10)
    }

    private var yAxisValues: [Double] {
        stride(from: 0.0, through: upperBound, by: 10).map { $0 }
    }

    private var summaryText: Text {
        if let formatted = try? AttributedString(markdown: forecast.summary) {
            return Text(formatted)
        }
        return Text(forecast.summary.replacingOccurrences(of: "**", with: ""))
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Prakiraan hujan · \(forecast.dateRange)")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text(forecast.headline)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.10, green: 0.27, blue: 0.46))
                        .frame(width: 26, height: 4)
                    Text("Hujan lebat · lebih dari \(Int(forecast.heavyThresholdMillimeters)) mm")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Text("Curah hujan (mm)")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                Chart {
                    RuleMark(y: .value("Ambang hujan lebat", forecast.heavyThresholdMillimeters))
                        .foregroundStyle(Color.gray.opacity(0.8))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 6]))

                    ForEach(forecast.days) { day in
                        BarMark(
                            x: .value("Tanggal", day.id),
                            y: .value("Curah hujan (mm)", day.precipitationMillimeters)
                        )
                        .foregroundStyle(day.isHeavy
                            ? Color(red: 0.10, green: 0.27, blue: 0.46)
                            : Color(red: 0.34, green: 0.58, blue: 0.75))
                        .cornerRadius(5)
                        .annotation(position: .top, spacing: 6) {
                            if day.isHeavy {
                                Text("\(day.precipitationMillimeters.formatted(.number.precision(.fractionLength(0...1)))) mm")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...upperBound)
                .chartYAxis {
                    AxisMarks(position: .leading, values: yAxisValues) { value in
                        AxisGridLine().foregroundStyle(Color.gray.opacity(0.18))
                        AxisTick()
                        AxisValueLabel {
                            if let millimeters = value.as(Double.self) {
                                Text("\(Int(millimeters))")
                                    .font(.body)
                            }
                        }
                    }
                }
                .chartXAxis(.hidden)
                .chartPlotStyle { plot in
                    plot.padding(.top, 20)
                }
                .frame(height: dynamicTypeSize.isAccessibilitySize ? 360 : 300)
                .accessibilityLabel("Grafik prakiraan hujan selama \(forecast.dateRange)")

                HStack(spacing: 0) {
                    ForEach(forecast.days) { day in
                        VStack(spacing: 6) {
                            Image(systemName: day.symbol)
                                .symbolRenderingMode(.multicolor)
                                .font(.title3)
                            Text(day.weekday)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 70)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(day.weekday), \(day.precipitationMillimeters.formatted()) milimeter, \(day.spreadStatus)")
                    }
                }
                // Align the separate icon row with the chart's plot area after its y-axis.
                .padding(.leading, 44)
                .padding(.trailing, 10)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 28))

            summaryText
                .font(.title3)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(.background, in: RoundedRectangle(cornerRadius: 28))
        }
    }
}
