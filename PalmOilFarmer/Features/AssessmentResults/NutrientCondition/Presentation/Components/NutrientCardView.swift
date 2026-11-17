import SwiftUI

/// Feed card representing a single nutrient assessment with badge, status, comparison, and warnings.
public struct NutrientCardView: View {
    public let item: NutrientItem
    public var showsDivider: Bool

    public init(item: NutrientItem, showsDivider: Bool = true) {
        self.item = item
        self.showsDivider = showsDivider
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Badge + Title/Source + Status Pill
            HStack(alignment: .center, spacing: 12) {
                NutrientBadgeView(symbol: item.symbol)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(KropsTheme.labelPrimary)

                    Text(item.sourceDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                NutrientStatusPill(status: item.status)
            }

            // Description of agronomic function
            Text(item.description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Comparison Metrics (if available)
            if let comparison = item.comparison {
                NutrientComparisonView(comparison: comparison)
            }

            // Actionable Verdict
            Text(item.verdict)
                .font(.callout.weight(.medium))
                .foregroundStyle(KropsTheme.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Warning Impact (only shown for deficiency or excess)
            if item.status != .sufficient, let warningImpact = item.warningImpact {
                NutrientWarningRow(message: warningImpact)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle()
                    .fill(Color.black.opacity(0.12))
                    .frame(height: 1)
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        NutrientCardView(item: NutrientConditionOverview.dummyData.nutrients[0])
        NutrientCardView(item: NutrientConditionOverview.dummyData.nutrients[3])
    }
}

