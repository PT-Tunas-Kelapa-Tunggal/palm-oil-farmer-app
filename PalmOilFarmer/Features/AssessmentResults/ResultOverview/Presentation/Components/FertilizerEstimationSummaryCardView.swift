import SwiftUI

/// Summary card displaying the estimated total fertilizer cost and budget comparison.
/// Sliced from Sketch: "Hasil Peninjauan / Ringkasan Hasil / Default" -> "Card / Perkiraan Biaya"
public struct FertilizerEstimationSummaryCardView: View {
    public let title: String
    public let estimation: FertilizerEstimationSummary
    public var onTap: (() -> Void)?

    private let darkPrimary = Color(red: 0.08, green: 0.08, blue: 0.09) // #141517
    private let graySecondary = Color(red: 0.24, green: 0.24, blue: 0.26).opacity(0.60) // #3C3C4399
    private let orangeAccent = Color(red: 1.0, green: 0.31, blue: 0.09) // #FF4F18
    private let lightChipBg = Color(red: 0.95, green: 0.96, blue: 0.97) // #F2F4F7

    public init(
        title: String = "Perkiraan Biaya Pupuk",
        estimation: FertilizerEstimationSummary,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.estimation = estimation
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 14) {
                // Header Category Row
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(graySecondary)

                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(graySecondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(darkPrimary.opacity(0.55))
                }

                // Price Headline & Detail
                VStack(alignment: .leading, spacing: 4) {
                    Text(estimation.formattedTotalCost)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(darkPrimary)

                    Text("Per tahun untuk \(estimation.fertilizerTypeCount) jenis pupuk")
                        .font(.system(size: 14))
                        .foregroundStyle(darkPrimary.opacity(0.72))
                }

                // Budget comparison pill
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(orangeAccent)

                    Text("Di bawah anggaran \(estimation.formattedBudgetLimit)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(darkPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(lightChipBg)
                .clipShape(Capsule())
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FertilizerEstimationSummaryCardView(
        estimation: ResultOverviewItem.sample.fertilizerEstimation
    )
    .padding()
    .background(Color(red: 0.95, green: 0.96, blue: 0.97))
}
