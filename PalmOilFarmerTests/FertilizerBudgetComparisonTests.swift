import Testing
@testable import PalmOilFarmer

struct FertilizerBudgetComparisonTests {
    private func estimate(cost: Int, budget: Int) -> FertilizerEstimationOverview {
        FertilizerEstimationOverview(
            id: "garden",
            gardenName: "Kebun",
            budgetLimit: budget,
            fertilizers: [FertilizerItem(
                id: "npk", name: "NPK", pricePerBag: cost,
                weightKg: 50, bagCount: 1, totalPrice: cost
            )],
            npkOptions: [],
            selectedNPKId: "npk"
        )
    }

    @Test func costBelowBudget() {
        let detail = estimate(cost: 2_250_000, budget: 2_429_911)
        let summary = FertilizerEstimationSummary(totalCost: detail.totalCost, fertilizerTypeCount: 1, budgetLimit: detail.budgetLimit)
        #expect(!detail.isOverBudget)
        #expect(detail.budgetStatusText.hasPrefix("Di bawah anggaran"))
        #expect(detail.budgetBalanceText.hasPrefix("Sisa "))
        #expect(summary.budgetStatusText == detail.budgetStatusText)
    }

    @Test func costAboveBudget() {
        let detail = estimate(cost: 2_500_000, budget: 2_429_911)
        let summary = FertilizerEstimationSummary(totalCost: detail.totalCost, fertilizerTypeCount: 1, budgetLimit: detail.budgetLimit)
        #expect(detail.isOverBudget)
        #expect(detail.budgetStatusText.hasPrefix("Di atas anggaran"))
        #expect(detail.budgetBalanceText.hasPrefix("Kelebihan "))
        #expect(detail.budgetBalanceText.contains("70.089"))
        #expect(summary.isOverBudget)
        #expect(summary.budgetStatusText == detail.budgetStatusText)
    }

    @Test func costEqualsBudget() {
        let detail = estimate(cost: 2_250_000, budget: 2_250_000)
        let summary = FertilizerEstimationSummary(totalCost: detail.totalCost, fertilizerTypeCount: 1, budgetLimit: detail.budgetLimit)
        #expect(!detail.isOverBudget)
        #expect(detail.budgetStatusText.hasPrefix("Sesuai anggaran"))
        #expect(summary.budgetStatusText == detail.budgetStatusText)
    }
}
