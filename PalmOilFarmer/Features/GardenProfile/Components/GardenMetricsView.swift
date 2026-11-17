import SwiftUI

struct GardenMetricsView: View {
    let garden: Garden
    var metrics: GardenDisplayMetrics? = nil
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
                        Divider().frame(width: 1, height: 36)
                        tile("Keliling", value: metrics.perimeter, symbol: "square.dashed")
                            .frame(width: available * 96 / 304)
                        Divider().frame(width: 1, height: 36)
                        tile("Tahun Tanam", value: String(garden.plantingYear), symbol: "calendar")
                    }
                }.frame(height: 43)
            }
        }
        .padding(16)
        .background(GardenProfileStyle.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private func tile(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: symbol).foregroundStyle(GardenProfileStyle.accent)
                Text(title).foregroundStyle(.secondary)
            }.font(.caption2)
            Text(value).font(.title2.bold())
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
