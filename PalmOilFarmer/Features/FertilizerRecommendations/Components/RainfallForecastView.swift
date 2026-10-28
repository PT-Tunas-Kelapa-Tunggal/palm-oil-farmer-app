import SwiftUI
import Charts

struct RainfallForecastView: View {
    let forecast: RainfallForecast

    var body: some View {
        VStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Prakiraan hujan · " + forecast.dateRange)
                    .font(.footnote).foregroundStyle(.secondary)
                Text(forecast.headline).font(.headline)
                HStack(spacing: 4) {
                    ForEach(forecast.days) { day in
                        VStack(spacing: 8) {
                            Image(systemName: day.symbol)
                                .symbolRenderingMode(.multicolor)
                                .font(.title3)
                            Spacer(minLength: 0)
                            Text(day.id).font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityLabel("\(day.id), \(day.precipitationMillimeters.formatted()) milimeter hujan")
                    }
                }
                .frame(height: 92)
                .overlay {
                    Chart(forecast.days) { day in
                        LineMark(x: .value("Hari", day.id), y: .value("Hujan", day.precipitationMillimeters))
                            .foregroundStyle(Color.gray)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .chartYScale(domain: 0...max(1, (forecast.days.map(\.precipitationMillimeters).max() ?? 0) * 2))
                    .padding(.horizontal, 10)
                    .padding(.top, 25)
                    .padding(.bottom, 24)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 24))
            Text(forecast.summary)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 24))
        }
    }
}
