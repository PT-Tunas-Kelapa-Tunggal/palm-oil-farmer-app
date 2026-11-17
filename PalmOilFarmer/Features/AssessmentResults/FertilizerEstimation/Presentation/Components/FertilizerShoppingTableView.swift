import SwiftUI

/// Shopping list table card showing individual fertilizer items, quantities, costs, and grand total.
/// Matches Sketch: "Card / Tabel Belanja"
public struct FertilizerShoppingTableView: View {
    public let fertilizers: [FertilizerItem]
    public let totalCost: String
    public var onSelectNPK: (() -> Void)?

    public init(
        fertilizers: [FertilizerItem],
        totalCost: String,
        onSelectNPK: (() -> Void)? = nil
    ) {
        self.fertilizers = fertilizers
        self.totalCost = totalCost
        self.onSelectNPK = onSelectNPK
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Table Column Headers
            HStack(alignment: .center, spacing: 12) {
                Text("Pupuk")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Berat")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .trailing)

                Text("Harga")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(width: 110, alignment: .trailing)
            }
            .padding(.bottom, 8)

            tableDivider

            // Fertilizer Rows
            ForEach(fertilizers) { item in
                FertilizerItemRowView(item: item) {
                    if item.isCustomizableNPK {
                        onSelectNPK?()
                    }
                }

                tableDivider
            }

            // Total Row
            HStack(alignment: .center) {
                Text("Total")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(KropsTheme.labelPrimary)

                Spacer()

                Text(totalCost)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(KropsTheme.labelPrimary)
            }
            .padding(.vertical, 14)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var tableDivider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.08))
            .frame(height: 1)
    }
}

#Preview {
    FertilizerShoppingTableView(
        fertilizers: FertilizerEstimationOverview.sample.fertilizers,
        totalCost: FertilizerEstimationOverview.sample.formattedTotalCost
    )
    .padding()
    .background(KropsTheme.surfaceBackground)
}

