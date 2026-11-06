import SwiftUI

struct GardenMetricsView: View {
    let garden: Garden
    var metrics: GardenDisplayMetrics? = nil
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let metrics = metrics ?? GardenDisplayMetrics(boundary: garden.boundary)
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 7)) : AnyLayout(HStackLayout(spacing: 7))
        layout {
            tile("Luas tanah", value: metrics.area)
            tile("Perimeter", value: metrics.perimeter)
            tile("Tahun Tanam", value: String(garden.plantingYear))
        }
    }

    private func tile(_ title: String, value: String) -> some View {
        VStack(spacing: 0) {
            Text(title).font(.caption)
            Text(value).font(.body.weight(.semibold))
        }
        .multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 40)
        .padding(.vertical, 16).padding(.horizontal, 8)
        .background(GardenProfileStyle.card, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Metrik kebun", traits: .sizeThatFitsLayout) {
    GardenMetricsView(garden: GardenProfileCanvasFixtures.emptyGarden, metrics: GardenPreviewData.metrics)
        .padding().frame(width: 402).background(GardenProfileStyle.background)
}
#endif
