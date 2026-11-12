import SwiftUI

/// Card displaying the 3-period fertilizer recommendation timeline.
/// Sliced from Sketch: "Hasil Peninjauan / Ringkasan Hasil / Default" -> "Panel Copy"
public struct FertilizerRecommendationCardView: View {
    public let title: String
    public let subtitle: String
    public let periods: [FertilizerPeriodItem]
    public var onTap: (() -> Void)?

    private let orangeAccent = Color(red: 1.0, green: 0.31, blue: 0.09)

    public init(
        title: String = "Rekomendasi Pemupukan",
        subtitle: String = "3 kali pemupukan di tahun 2027",
        periods: [FertilizerPeriodItem],
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.periods = periods
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header Row
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(orangeAccent)
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.white)

                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundStyle(Color.white.opacity(0.8))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .padding(.top, 4)
                }

                // Timeline Capsules Row (Jan, Apr, Jul connected by lines)
                HStack(spacing: 0) {
                    ForEach(Array(periods.enumerated()), id: \.element.id) { index, period in
                        periodTile(period)

                        if index < periods.count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.20))
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(red: 0.08, green: 0.08, blue: 0.09))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func periodTile(_ period: FertilizerPeriodItem) -> some View {
        VStack(spacing: 2) {
            Text(period.orderText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.8))

            Text(period.month)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.white)

            Text(period.year)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 73)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    FertilizerRecommendationCardView(
        periods: ResultOverviewItem.sample.periods
    )
    .padding()
    .background(Color(red: 0.95, green: 0.96, blue: 0.97))
}

