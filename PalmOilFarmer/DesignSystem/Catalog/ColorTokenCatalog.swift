#if DEBUG
import SwiftUI

/// Every colour token in the same groups and order as Sketch › FOUNDATIONS › Colors,
/// so the two can be compared side by side. The hex is read from the token itself, not typed twice.
struct ColorTokenCatalog: View {
    var body: some View {
        VStack(alignment: .leading, spacing: KropsTheme.Spacing.content) {
            ForEach(Self.groups) { group in
                VStack(alignment: .leading, spacing: KropsTheme.Spacing.field) {
                    Text(group.title)
                        .font(.title3.bold())
                        .foregroundStyle(KropsTheme.labelPrimary)
                    VStack(spacing: 0) {
                        ForEach(group.tokens) { token in
                            ColorTokenRow(token: token)
                            if token.id != group.tokens.last?.id {
                                Divider().background(KropsTheme.separatorDefault).padding(.leading, 72)
                            }
                        }
                    }
                    .background(KropsTheme.surfaceCard, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
                }
            }
        }
    }

    struct Token: Identifiable {
        let sketchName: String
        let codeName: String
        let color: Color
        var id: String { sketchName }
    }

    struct TokenGroup: Identifiable {
        let title: String
        let tokens: [Token]
        var id: String { title }
    }

    static let groups: [TokenGroup] = [
        TokenGroup(title: "Accent", tokens: [
            Token(sketchName: "Accent/Hero", codeName: "accentHero", color: KropsTheme.accentHero),
            Token(sketchName: "Accent/Primary", codeName: "accentPrimary", color: KropsTheme.accentPrimary),
            Token(sketchName: "Accent/Section Label", codeName: "accentSectionLabel", color: KropsTheme.accentSectionLabel),
            Token(sketchName: "Accent/Soft", codeName: "accentSoft", color: KropsTheme.accentSoft),
            Token(sketchName: "Accent/Success", codeName: "accentSuccess", color: KropsTheme.accentSuccess),
        ]),
        TokenGroup(title: "Surface", tokens: [
            Token(sketchName: "Surface/Background", codeName: "surfaceBackground", color: KropsTheme.surfaceBackground),
            Token(sketchName: "Surface/Card", codeName: "surfaceCard", color: KropsTheme.surfaceCard),
            Token(sketchName: "Surface/Card Raised", codeName: "surfaceCardRaised", color: KropsTheme.surfaceCardRaised),
            Token(sketchName: "Surface/Control", codeName: "surfaceControl", color: KropsTheme.surfaceControl),
            Token(sketchName: "Surface/Inverse", codeName: "surfaceInverse", color: KropsTheme.surfaceInverse),
            Token(sketchName: "Surface/Inverse Raised", codeName: "surfaceInverseRaised", color: KropsTheme.surfaceInverseRaised),
        ]),
        TokenGroup(title: "Label", tokens: [
            Token(sketchName: "Label/Emphasis", codeName: "labelEmphasis", color: KropsTheme.labelEmphasis),
            Token(sketchName: "Label/Inverse Primary", codeName: "labelInversePrimary", color: KropsTheme.labelInversePrimary),
            Token(sketchName: "Label/Inverse Secondary", codeName: "labelInverseSecondary", color: KropsTheme.labelInverseSecondary),
            Token(sketchName: "Label/Inverse Tertiary", codeName: "labelInverseTertiary", color: KropsTheme.labelInverseTertiary),
            Token(sketchName: "Label/Primary", codeName: "labelPrimary", color: KropsTheme.labelPrimary),
            Token(sketchName: "Label/Quaternary", codeName: "labelQuaternary", color: KropsTheme.labelQuaternary),
            Token(sketchName: "Label/Secondary", codeName: "labelSecondary", color: KropsTheme.labelSecondary),
            Token(sketchName: "Label/Tertiary", codeName: "labelTertiary", color: KropsTheme.labelTertiary),
        ]),
        TokenGroup(title: "Separator", tokens: [
            Token(sketchName: "Separator/Default", codeName: "separatorDefault", color: KropsTheme.separatorDefault),
            Token(sketchName: "Separator/Opaque", codeName: "separatorOpaque", color: KropsTheme.separatorOpaque),
        ]),
        TokenGroup(title: "Fill", tokens: [
            Token(sketchName: "Fill/Black 4", codeName: "fillBlack4", color: KropsTheme.fillBlack4),
            Token(sketchName: "Fill/Black 8", codeName: "fillBlack8", color: KropsTheme.fillBlack8),
            Token(sketchName: "Fill/Black 12", codeName: "fillBlack12", color: KropsTheme.fillBlack12),
            Token(sketchName: "Fill/Black 20", codeName: "fillBlack20", color: KropsTheme.fillBlack20),
            Token(sketchName: "Fill/Black 30", codeName: "fillBlack30", color: KropsTheme.fillBlack30),
            Token(sketchName: "Fill/Black 45", codeName: "fillBlack45", color: KropsTheme.fillBlack45),
            Token(sketchName: "Fill/Gray 1", codeName: "fillGray1", color: KropsTheme.fillGray1),
            Token(sketchName: "Fill/Gray 2", codeName: "fillGray2", color: KropsTheme.fillGray2),
            Token(sketchName: "Fill/Gray 3", codeName: "fillGray3", color: KropsTheme.fillGray3),
            Token(sketchName: "Fill/Scrim 40", codeName: "fillScrim40", color: KropsTheme.fillScrim40),
            Token(sketchName: "Fill/White 6", codeName: "fillWhite6", color: KropsTheme.fillWhite6),
            Token(sketchName: "Fill/White 8", codeName: "fillWhite8", color: KropsTheme.fillWhite8),
            Token(sketchName: "Fill/White 12", codeName: "fillWhite12", color: KropsTheme.fillWhite12),
            Token(sketchName: "Fill/White 15", codeName: "fillWhite15", color: KropsTheme.fillWhite15),
            Token(sketchName: "Fill/White 25", codeName: "fillWhite25", color: KropsTheme.fillWhite25),
            Token(sketchName: "Fill/White 55", codeName: "fillWhite55", color: KropsTheme.fillWhite55),
        ]),
        TokenGroup(title: "Status", tokens: [
            Token(sketchName: "Status/Caution", codeName: "statusCaution", color: KropsTheme.statusCaution),
            Token(sketchName: "Status/Critical", codeName: "statusCritical", color: KropsTheme.statusCritical),
            Token(sketchName: "Status/Neutral", codeName: "statusNeutral", color: KropsTheme.statusNeutral),
            Token(sketchName: "Status/Warning", codeName: "statusWarning", color: KropsTheme.statusWarning),
        ]),
        TokenGroup(title: "Material", tokens: [
            Token(sketchName: "Material/Bar", codeName: "materialBar", color: KropsTheme.materialBar),
        ]),
    ]
}

private struct ColorTokenRow: View {
    let token: ColorTokenCatalog.Token

    var body: some View {
        HStack(spacing: 16) {
            swatch
            VStack(alignment: .leading, spacing: 2) {
                Text(token.sketchName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(KropsTheme.labelPrimary)
                Text(".\(token.codeName)   \(Self.sketchHex(token.color))")
                    .font(.footnote.monospaced())
                    .foregroundStyle(KropsTheme.labelSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    /// Half white, half black underneath, so transparent Black and White fills are both visible.
    private var swatch: some View {
        HStack(spacing: 0) {
            Rectangle().fill(.white)
            Rectangle().fill(KropsTheme.surfaceInverse)
        }
        .overlay(Rectangle().fill(token.color))
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(KropsTheme.separatorOpaque, lineWidth: 0.5))
    }

    /// Formats a colour the way the Sketch style guide writes it: `#141517` or `#141517 72%`.
    static func sketchHex(_ color: Color) -> String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let hex = String(format: "#%02X%02X%02X", Int((red * 255).rounded()),
                         Int((green * 255).rounded()), Int((blue * 255).rounded()))
        return alpha < 0.999 ? "\(hex) \(Int((alpha * 100).rounded()))%" : hex
    }
}

#Preview("Warna · KROPS Light") {
    ScrollView {
        ColorTokenCatalog().padding(KropsTheme.Spacing.screen)
    }
    .background(KropsTheme.surfaceBackground)
}
#endif
