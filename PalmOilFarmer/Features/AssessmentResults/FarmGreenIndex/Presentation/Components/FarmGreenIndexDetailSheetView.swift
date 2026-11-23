import SwiftUI

/// Bottom sheet displaying in-depth condition metrics for a selected category using Liquid Glass.
/// Sliced from Sketch: "Hasil Peninjauan / Detail Kondisi / [Normal|Terindikasi|Defisiensi|Tidak Wajar]"
public struct FarmGreenIndexDetailSheetView: View {
    public let summary: TreeConditionSummaryItem
    public var onBack: (() -> Void)?
    public var onCollapse: (() -> Void)?


    public init(
        summary: TreeConditionSummaryItem,
        onBack: (() -> Void)? = nil,
        onCollapse: (() -> Void)? = nil
    ) {
        self.summary = summary
        self.onBack = onBack
        self.onCollapse = onCollapse
    }

    public var body: some View {
        let dotColor = summary.category.color

        VStack(alignment: .leading, spacing: 16) {
            // Header: Circular Back Button (<) + Category Dot + Title (Left-aligned matching Sketch)
            HStack(alignment: .center, spacing: 10) {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(KropsTheme.labelPrimary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: Circle())
                .accessibilityLabel("Kembali ke Legenda")

                Circle()
                    .fill(dotColor)
                    .frame(width: 12, height: 12)

                Text(summary.category.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(KropsTheme.labelPrimary)

                Spacer()
            }

            // Detailed Narrative Explanation (Left-aligned)
            Text(summary.category.detailNarrative)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(KropsTheme.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // 2 Metric Cards Row (Jumlah pohon & Bagian kebun)
            HStack(spacing: 12) {
                metricCard(
                    title: "Jumlah pohon",
                    value: "\(summary.treeCount) pohon"
                )

                metricCard(
                    title: "Bagian kebun",
                    value: summary.percentageText
                )
            }
            .padding(.top, 4)
        }
        // Shown inside `DetentSheet`: the system draws the sheet, its glass and its grabber.
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(KropsTheme.labelSecondary)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(KropsTheme.labelPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.50))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}


#Preview("Detail Kondisi · Normal") {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            FarmGreenIndexDetailSheetView(
                summary: FarmGreenIndexItem.sample.categories[0]
            )
        }
    }
}

#Preview("Detail Kondisi · Defisiensi") {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            FarmGreenIndexDetailSheetView(
                summary: FarmGreenIndexItem.sample.categories[2]
            )
        }
    }
}
