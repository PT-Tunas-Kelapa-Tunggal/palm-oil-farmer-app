import SwiftUI

/// Total cost summary card displaying overall fertilizer budget, progress bar, and remaining allowance.
/// Matches Sketch: "Card / Total"
public struct FertilizerTotalCostCard: View {
    public let totalCost: String
    public let fertilizerCount: Int
    public let budgetProgress: Double
    public let budgetStatusText: String
    public let budgetBalanceText: String
    public let isOverBudget: Bool

    public init(
        totalCost: String,
        fertilizerCount: Int,
        budgetProgress: Double,
        budgetStatusText: String,
        budgetBalanceText: String,
        isOverBudget: Bool
    ) {
        self.totalCost = totalCost
        self.fertilizerCount = fertilizerCount
        self.budgetProgress = budgetProgress
        self.budgetStatusText = budgetStatusText
        self.budgetBalanceText = budgetBalanceText
        self.isOverBudget = isOverBudget
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            Text("Total belanja pupuk")
                .font(.footnote)
                .foregroundStyle(.secondary)

            // Total Amount
            Text(totalCost)
                .font(.largeTitle.bold())
                .foregroundStyle(KropsTheme.labelPrimary)
                .padding(.top, 2)

            // Unit / Scope
            Text("per tahun untuk \(fertilizerCount) jenis pupuk")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            // Budget Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(KropsTheme.surfaceCardRaised) // #F2F4F7
                            .frame(height: 8)

                        Capsule()
                            .fill(KropsTheme.accentHero) // #FF4F18
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(budgetProgress))), height: 8)
                    }
                }
                .frame(height: 8)

                // Budget Labels
                HStack {
                    Text(budgetStatusText)
                        .font(.footnote)
                        .foregroundStyle(isOverBudget ? KropsTheme.accentHero : KropsTheme.labelPrimary)

                    Spacer()

                    Text(budgetBalanceText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    FertilizerTotalCostCard(
        totalCost: "Rp7.850.000",
        fertilizerCount: 3,
        budgetProgress: 0.84,
        budgetStatusText: "Di bawah anggaran Rp9.350.000",
        budgetBalanceText: "Sisa Rp1.500.000",
        isOverBudget: false
    )
    .padding()
    .background(KropsTheme.surfaceBackground)
}

