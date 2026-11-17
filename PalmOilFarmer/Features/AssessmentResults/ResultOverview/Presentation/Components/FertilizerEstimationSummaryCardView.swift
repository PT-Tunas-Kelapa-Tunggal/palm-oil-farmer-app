import SwiftUI

/// Summary card displaying the estimated total fertilizer cost and budget comparison.
/// Sliced from Sketch: "Hasil Peninjauan / Ringkasan Hasil / Default" -> "Card / Perkiraan Biaya"
public struct FertilizerEstimationSummaryCardView: View {
    public let title: String
    public let estimation: FertilizerEstimationSummary
    public var onTap: (() -> Void)?


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
                        .foregroundStyle(KropsTheme.labelSecondary)

                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(KropsTheme.labelSecondary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(KropsTheme.labelTertiary)
                }

                // Price Headline & Detail
                VStack(alignment: .leading, spacing: 4) {
                    Text(estimation.formattedTotalCost)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(KropsTheme.labelPrimary)

                    Text("Per tahun untuk \(estimation.fertilizerTypeCount) jenis pupuk")
                        .font(.system(size: 14))
                        .foregroundStyle(KropsTheme.labelSecondary)
                }

                // Budget comparison pill
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(KropsTheme.accentHero)

                    Text("Di bawah anggaran \(estimation.formattedBudgetLimit)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(KropsTheme.labelPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(KropsTheme.surfaceCardRaised)
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
    .background(KropsTheme.surfaceBackground)
}
