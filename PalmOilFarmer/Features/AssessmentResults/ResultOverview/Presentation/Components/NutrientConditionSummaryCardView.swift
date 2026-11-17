import SwiftUI

/// Summary card displaying nutrient balance headline, narrative, and circular nutrient badges (N, P, K, Mg).
/// Sliced from Sketch: "Hasil Peninjauan / Ringkasan Hasil / Default" -> "Card / Kondisi Hara Copy"
public struct NutrientConditionSummaryCardView: View {
    public let title: String
    public let statusBadgeText: String
    public let summaryText: String
    public let nutrients: [NutrientStatusSummaryItem]
    public var onTap: (() -> Void)?


    public init(
        title: String = "Kondisi Hara",
        statusBadgeText: String = "Belum Seimbang",
        summaryText: String = "Hasil dari praktik pemupukan Anda sebelumnya: dua hara kurang dan satu berlebih.",
        nutrients: [NutrientStatusSummaryItem],
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.statusBadgeText = statusBadgeText
        self.summaryText = summaryText
        self.nutrients = nutrients
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 14) {
                // Header Category Row
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "sparkles")
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

                // Title Headline & Description
                VStack(alignment: .leading, spacing: 6) {
                    Text(statusBadgeText)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(KropsTheme.labelPrimary)

                    Text(summaryText)
                        .font(.system(size: 14))
                        .foregroundStyle(KropsTheme.labelSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // 4 Nutrient Badges in Horizontal Row
                HStack(spacing: 0) {
                    ForEach(nutrients) { item in
                        nutrientColumn(item)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 8)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Nutrient Item

    private func nutrientColumn(_ item: NutrientStatusSummaryItem) -> some View {
        VStack(spacing: 8) {
            // 64x64 Circular Badge with bottom-right status mark
            ZStack(alignment: .bottomTrailing) {
                // Main circle
                Group {
                    if item.symbol == "P" {
                        Circle()
                            .fill(Color.white)
                            .overlay(
                                Circle()
                                    .stroke(KropsTheme.surfaceControl, lineWidth: 1.5)
                            )
                    } else if item.symbol == "Mg" {
                        Circle()
                            .fill(KropsTheme.surfaceCardRaised)
                    } else {
                        Circle()
                            .fill(KropsTheme.accentHero)
                    }
                }
                .frame(width: 64, height: 64)

                // Symbol text inside main circle
                Text(item.symbol)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(badgeTextColor(for: item))
                    .frame(width: 64, height: 64)

                // 22x22 Status Mark Circle at bottom-right
                ZStack {
                    Circle()
                        .fill(statusMarkBackground(for: item.status))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )

                    statusMarkIcon(for: item.status)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .offset(x: 2, y: 2)
            }

            // Labels below badge
            VStack(spacing: 2) {
                Text(item.status.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(statusTextColor(for: item.status))

                Text(item.name)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(KropsTheme.labelSecondary)
            }
        }
    }

    private func badgeTextColor(for item: NutrientStatusSummaryItem) -> Color {
        switch item.symbol {
        case "P":
            return KropsTheme.accentPrimary
        case "Mg":
            return KropsTheme.labelPrimary
        default:
            return Color.white
        }
    }

    private func statusMarkBackground(for status: NutrientConditionStatus) -> Color {
        switch status {
        case .cukup:
            return KropsTheme.surfaceInverse
        case .kurang, .berlebih:
            return KropsTheme.accentHero
        }
    }

    @ViewBuilder
    private func statusMarkIcon(for status: NutrientConditionStatus) -> some View {
        switch status {
        case .kurang:
            Image(systemName: "arrow.down")
        case .berlebih:
            Image(systemName: "arrow.up")
        case .cukup:
            Image(systemName: "checkmark")
        }
    }

    private func statusTextColor(for status: NutrientConditionStatus) -> Color {
        switch status {
        case .cukup:
            return KropsTheme.labelPrimary
        case .kurang, .berlebih:
            return KropsTheme.accentPrimary
        }
    }
}

#Preview {
    NutrientConditionSummaryCardView(
        nutrients: ResultOverviewItem.sample.nutrients
    )
    .padding()
    .background(KropsTheme.surfaceBackground)
}
