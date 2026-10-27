import SwiftUI

struct GardenSummaryView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let garden: Garden
    var metrics: GardenDisplayMetrics? = nil

    private var displayMetrics: GardenDisplayMetrics {
        metrics ?? GardenDisplayMetrics(boundary: garden.boundary)
    }

    var body: some View {
        let displayMetrics = displayMetrics
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 7))
            : AnyLayout(HStackLayout(spacing: 7))
        layout {
            GardenMetricTile(title: "Luas", value: displayMetrics.area, systemImage: "point.topleft.down.to.point.bottomright.curvepath")
            GardenMetricTile(title: "Perimeter", value: displayMetrics.perimeter, systemImage: "rectangle.dashed")
            GardenMetricTile(title: "Tahun tanam", value: String(garden.plantingYear), systemImage: "calendar")
        }
    }
}

struct GardenMetricTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption2)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(minHeight: 67)
        .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            Group {
                if systemImage == "point.topleft.down.to.point.bottomright.curvepath" {
                    GardenAreaIcon().scaleEffect(1.4)
                } else {
                    Image(systemName: systemImage).font(.title2)
                }
            }
            .foregroundStyle(.tertiary)
            .padding(.top, 4)
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Garden Summary", traits: .sizeThatFitsLayout) {
    GardenSummaryView(garden: GardenPreviewData.garden, metrics: GardenPreviewData.metrics)
        .padding(16)
        .frame(width: 402)
        .background(KropsTheme.background)
}

#Preview("Metric Tile", traits: .sizeThatFitsLayout) {
    GardenMetricTile(title: "Luas", value: "2,3 ha", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
        .frame(width: 119).padding()
}
#endif
