import SwiftUI

/// Roles used by the "Jadwal Pemupukan" screens, mapped to KROPS Light tokens.
enum FertilizerScheduleStyle {
    static let accent = KropsTheme.accentHero
    static let accentSoft = KropsTheme.accentSoft
    static let ink = KropsTheme.labelPrimary
    static let inkSecondary = KropsTheme.labelSecondary
    static let inkTertiary = KropsTheme.labelTertiary
    static let inkGap = KropsTheme.labelEmphasis
    static let numberFill = KropsTheme.fillGray2
    static let raisedFill = KropsTheme.surfaceCardRaised
    static let chipFill = KropsTheme.fillBlack4
    static let gapBar = KropsTheme.fillBlack12
    static let headerSecondary = KropsTheme.labelInverseSecondary
    static let highlight = LinearGradient(
        colors: [KropsTheme.surfaceInverse, KropsTheme.surfaceInverseRaised], startPoint: .top, endPoint: .bottom
    )
    static let screenBackground = LinearGradient(
        colors: [KropsTheme.surfaceInverseRaised, KropsTheme.surfaceInverse], startPoint: .topTrailing, endPoint: .bottomLeading
    )
    static let heroRadius: CGFloat = 28
    static let cardRadius: CGFloat = 20
    static let rowRadius: CGFloat = 20
}

struct FertilizerStepRow: View {
    typealias Row = FertilizerSchedulePresentation.StepRow

    let row: Row
    var isCard = false
    let action: () -> Void

    private typealias Style = FertilizerScheduleStyle
    private var isHighlighted: Bool { row.style == .highlighted }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                badge
                VStack(alignment: .leading, spacing: 0) {
                    Text(row.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(ink)
                    if let subtitle = row.subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(isHighlighted ? Color.white.opacity(0.8) : Style.inkSecondary)
                    }
                }
                Spacer(minLength: 0)
                Text(row.quantity)
                    .font(.headline)
                    .foregroundStyle(ink)
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(isHighlighted ? Color.white.opacity(0.8) : Style.inkTertiary)
            }
            .padding(.vertical, 14)
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background { background }
            .contentShape(RoundedRectangle(cornerRadius: Style.rowRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var ink: Color {
        switch row.style {
        case .highlighted: .white
        case .given: Style.inkSecondary
        case .waiting, .locked: Style.ink
        }
    }

    @ViewBuilder
    private var badge: some View {
        if row.style == .given {
            Image(systemName: "checkmark")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Style.accent)
                .frame(width: 24, height: 24)
                .background(Style.accentSoft, in: Circle())
        } else {
            Text("\(row.order)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Style.ink)
                .frame(width: 24, height: 24)
                .background(badgeFill, in: Circle())
        }
    }

    private var badgeFill: Color {
        if isHighlighted { return .white }
        return isCard ? Style.ink.opacity(0.08) : Style.numberFill
    }

    @ViewBuilder
    private var background: some View {
        let shape = RoundedRectangle(cornerRadius: Style.rowRadius)
        if isHighlighted {
            shape.fill(Style.highlight)
        } else if isCard {
            shape.fill(Style.raisedFill)
        }
    }
}

struct FertilizerGapRow: View {
    let row: FertilizerSchedulePresentation.GapRow

    private typealias Style = FertilizerScheduleStyle
    private var isCounting: Bool { row.style == .counting }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(isCounting ? Style.ink : Style.gapBar)
                .frame(width: 4, height: isCounting ? 12 : 28)
            Text(row.text)
                .font(.subheadline.weight(isCounting ? .semibold : .regular))
                .foregroundStyle(textColor)
            Spacer(minLength: 0)
        }
        .padding(.leading, 22)
        .padding(.trailing, 12)
        .padding(.vertical, isCounting ? 14 : 2)
        .background {
            if isCounting {
                RoundedRectangle(cornerRadius: Style.rowRadius).fill(Style.raisedFill)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var textColor: Color {
        switch row.style {
        case .counting: Style.ink
        case .pending: Style.inkGap
        case .elapsed: Style.inkTertiary
        }
    }
}

struct FertilizerTimelineList: View {
    let rows: [FertilizerSchedulePresentation.TimelineRow]
    var isCard = false
    let onSelectStep: (UUID) -> Void

    var body: some View {
        VStack(spacing: 6) {
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
