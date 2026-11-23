import SwiftUI

/// Bottom sheet displaying the condition legend categories and tree counts using Liquid Glass.
/// Sliced from Sketch: "Hasil Peninjauan / Peta Kondisi Kebun / Legend" -> "Template / Sheet / Small Detent", "Arsip / Panel (manual)"
public struct FarmGreenIndexLegendSheetView: View {
    public let categories: [TreeConditionSummaryItem]
    public var onSelectCategory: ((TreeConditionCategory) -> Void)?
    public var onCollapse: (() -> Void)?


    public init(
        categories: [TreeConditionSummaryItem],
        onSelectCategory: ((TreeConditionCategory) -> Void)? = nil,
        onCollapse: (() -> Void)? = nil
    ) {
        self.categories = categories
        self.onSelectCategory = onSelectCategory
        self.onCollapse = onCollapse
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Title & Subtitle (Left-aligned matching Sketch)
            VStack(alignment: .leading, spacing: 3) {
                Text("Kondisi Pohon")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(KropsTheme.labelPrimary)

                Text("Warna pada peta menunjukkan kesehatan setiap pohon.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(KropsTheme.labelSecondary)
            }
            .padding(.horizontal, 4)

            // 4 Category Rows (Normal, Terindikasi, Defisiensi, Tidak Wajar)
            VStack(spacing: 8) {
                ForEach(categories) { item in
                    Button(action: { onSelectCategory?(item.category) }) {
                        categoryRow(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        // Shown inside `DetentSheet`: the system draws the sheet, its glass and its grabber.
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    private func categoryRow(_ item: TreeConditionSummaryItem) -> some View {
        let dotColor = item.category.color

        return HStack(spacing: 12) {
            // Condition color dot
            Circle()
                .fill(dotColor)
                .frame(width: 12, height: 12)

            // Titles (Left-aligned)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.category.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(KropsTheme.labelPrimary)

                Text(item.category.shortLegend)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(KropsTheme.labelSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Tree count (Right-aligned bold text)
            Text("\(item.treeCount)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(KropsTheme.labelPrimary)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(KropsTheme.labelQuaternary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.50))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}


#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            FarmGreenIndexLegendSheetView(
                categories: FarmGreenIndexItem.sample.categories
            )
        }
    }
}
