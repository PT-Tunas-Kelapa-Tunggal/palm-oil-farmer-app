import SwiftUI

enum FertilizerScheduleStyle {
    /// Bright fruit-bunch orange from the design; only used for icons and the status dot.
    static let accent = Color(red: 0.95, green: 0.33, blue: 0.13)
    static let accentSoft = accent.opacity(0.14)
    static let neutralFill = Color(white: 0.94)
    static let gapBar = Color(white: 0.86)
    static let highlight = LinearGradient(
        colors: [Color(white: 0.06), Color(white: 0.24)], startPoint: .leading, endPoint: .trailing
    )
    static let screenBackground = LinearGradient(
        colors: [Color(white: 0.2), Color(white: 0.05)], startPoint: .topTrailing, endPoint: .bottomLeading
    )
    static let heroRadius: CGFloat = 28
    static let rowRadius: CGFloat = 16
}

struct FertilizerStepRow: View {
    typealias Row = FertilizerSchedulePresentation.StepRow

    let row: Row
    var isCard = false
    let action: () -> Void

    private var isHighlighted: Bool { row.style == .highlighted }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                badge
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(nameStyle)
                    if let subtitle = row.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(isHighlighted ? AnyShapeStyle(.white.opacity(0.75)) : AnyShapeStyle(.secondary))
                    }
                }
                Spacer(minLength: 8)
                Text(row.quantity)
                    .font(.body.weight(.bold))
                    .foregroundStyle(nameStyle)
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isHighlighted ? AnyShapeStyle(.white) : AnyShapeStyle(.tertiary))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, isHighlighted || isCard ? 12 : 8)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background { background }
            .contentShape(RoundedRectangle(cornerRadius: FertilizerScheduleStyle.rowRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var nameStyle: AnyShapeStyle {
        switch row.style {
        case .highlighted: AnyShapeStyle(.white)
        case .given: AnyShapeStyle(.secondary)
        case .waiting, .locked: AnyShapeStyle(.primary)
        }
    }

    @ViewBuilder
    private var badge: some View {
        if row.style == .given {
            Image(systemName: "checkmark")
                .font(.footnote.weight(.bold))
                .foregroundStyle(FertilizerScheduleStyle.accent)
                .frame(width: 26, height: 26)
                .background(FertilizerScheduleStyle.accentSoft, in: Circle())
        } else {
            Text("\(row.order)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isHighlighted ? .black : .primary)
                .frame(width: 24, height: 24)
                .background(isHighlighted ? AnyShapeStyle(.white) : AnyShapeStyle(FertilizerScheduleStyle.neutralFill),
                            in: Circle())
                .padding(.horizontal, 1)
        }
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: FertilizerScheduleStyle.rowRadius)
        if isHighlighted {
            shape.fill(FertilizerScheduleStyle.highlight)
        } else if isCard {
            shape.fill(.background.opacity(0.85))
        }
    }
}

struct FertilizerGapRow: View {
    let row: FertilizerSchedulePresentation.GapRow

    var body: some View {
        HStack(spacing: 12) {
            Capsule()
                .fill(barColor)
                .frame(width: 3, height: row.style == .counting ? 16 : 22)
            Text(row.text)
                .font(.subheadline.weight(row.style == .counting ? .semibold : .regular))
                .foregroundStyle(textStyle)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, row.style == .counting ? 14 : 4)
        .background {
            if row.style == .counting {
                RoundedRectangle(cornerRadius: FertilizerScheduleStyle.rowRadius).fill(FertilizerScheduleStyle.neutralFill)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var barColor: Color {
        switch row.style {
        case .counting: .primary
        case .pending: FertilizerScheduleStyle.gapBar
        case .elapsed: FertilizerScheduleStyle.gapBar.opacity(0.6)
        }
    }

    private var textStyle: AnyShapeStyle {
        switch row.style {
        case .counting: AnyShapeStyle(.primary)
        case .pending: AnyShapeStyle(.secondary)
        case .elapsed: AnyShapeStyle(.tertiary)
        }
    }
}

struct FertilizerTimelineList: View {
    let rows: [FertilizerSchedulePresentation.TimelineRow]
    var isCard = false
    let onSelectStep: (UUID) -> Void

    var body: some View {
        VStack(spacing: isCard ? 8 : 6) {
            ForEach(rows) { row in
                switch row {
                case .step(let step):
                    FertilizerStepRow(row: step, isCard: isCard) { onSelectStep(step.id) }
                case .gap(let gap):
                    FertilizerGapRow(row: gap)
                }
            }
        }
    }
}
