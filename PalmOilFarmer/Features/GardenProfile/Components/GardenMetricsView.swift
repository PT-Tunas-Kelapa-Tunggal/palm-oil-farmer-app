import SwiftUI

struct GardenMetricsView: View {
    let garden: Garden
    var metrics: GardenDisplayMetrics? = nil
    var usesAssessmentBand = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let metrics = metrics ?? GardenDisplayMetrics(boundary: garden.boundary)
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    tile("Luas", value: metrics.area, symbol: "square.dashed.inset.filled")
                    tile("Keliling", value: metrics.perimeter, symbol: "square.dashed")
                    tile("Tahun Tanam", value: String(garden.plantingYear), symbol: "calendar")
                }
            } else {
                GeometryReader { geometry in
                    let available = max(0, geometry.size.width - 34)
                    HStack(spacing: 8) {
                        tile("Luas", value: metrics.area, symbol: "square.dashed.inset.filled")
                            .frame(width: available * 88 / 304)
                        divider
                        tile("Keliling", value: metrics.perimeter, symbol: "square.dashed")
                            .frame(width: available * 96 / 304)
                        divider
                        tile("Tahun Tanam", value: String(garden.plantingYear), symbol: "calendar")
                    }
                }.frame(height: 43)
            }
        }
        .padding(.horizontal, usesAssessmentBand ? 20 : 16)
        .padding(.top, usesAssessmentBand ? 20 : 16)
        .padding(.bottom, usesAssessmentBand ? 52 : 16)
        .background {
            if usesAssessmentBand {
                UnevenRoundedRectangle(topLeadingRadius: 40, topTrailingRadius: 40)
                    .fill(AssessmentPalette.ink)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(GardenProfileStyle.card)
            }
        }
    }

    private var divider: some View {
        Divider()
            .overlay {
                if usesAssessmentBand { Color.white.opacity(0.2) }
            }
            .frame(width: 1, height: 36)
    }

    private func tile(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: symbol).foregroundStyle(usesAssessmentBand ? .white : GardenProfileStyle.accent)
                Text(title).foregroundStyle(usesAssessmentBand ? Color.white : .secondary)
            }.font(.caption2)
            Text(value).font(.title2.bold()).foregroundStyle(usesAssessmentBand ? Color.white : .primary)
        }
        .frame(maxWidth: .infinity, minHeight: 43, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Metrik kebun", traits: .sizeThatFitsLayout) {
    GardenMetricsView(garden: GardenProfileCanvasFixtures.emptyGarden, metrics: GardenPreviewData.metrics)
        .padding().frame(width: 402).background(GardenProfileStyle.background)
}
#endif
