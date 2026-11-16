import SwiftUI

/// Total cost summary card displaying overall fertilizer budget, progress bar, and remaining allowance.
/// Matches Sketch: "Card / Total"
public struct FertilizerTotalCostCard: View {
    public let totalCost: String
    public let fertilizerCount: Int
    public let budgetLimit: String
    public let remainingBudget: String
    public let budgetProgress: Double

    public init(
        totalCost: String,
        fertilizerCount: Int,
        budgetLimit: String,
        remainingBudget: String,
        budgetProgress: Double
    ) {
        self.totalCost = totalCost
        self.fertilizerCount = fertilizerCount
        self.budgetLimit = budgetLimit
        self.remainingBudget = remainingBudget
        self.budgetProgress = budgetProgress
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
                .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))
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
                            .fill(Color(red: 0.95, green: 0.96, blue: 0.97)) // #F2F4F7
                            .frame(height: 8)

                        Capsule()
                            .fill(Color(red: 1.0, green: 0.31, blue: 0.09)) // #FF4F18
                            .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(budgetProgress))), height: 8)
                    }
                }
                .frame(height: 8)

                // Budget Labels
                HStack {
                    Text("Di bawah anggaran \(budgetLimit)")
                        .font(.footnote)
                        .foregroundStyle(Color(red: 0.08, green: 0.08, blue: 0.09))

                    Spacer()

                    Text("Sisa \(remainingBudget)")
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
        budgetLimit: "Rp9.350.000",
        remainingBudget: "Rp1.500.000",
        budgetProgress: 0.84
    )
    .padding()
    .background(Color(red: 0.95, green: 0.96, blue: 0.97))
}

