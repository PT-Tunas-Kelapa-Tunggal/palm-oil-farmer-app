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
            GardenMetricTile(title: "Luas tanah", value: displayMetrics.area, kind: .area)
            GardenMetricTile(title: "Perimeter", value: displayMetrics.perimeter, kind: .perimeter)
            GardenMetricTile(title: "Tahun Tanam", value: String(garden.plantingYear), kind: .year)
        }
    }
}

struct GardenMetricTile: View {
    enum Kind {
        case area, perimeter, year

        var fill: Color {
            switch self {
            case .area: KropsTheme.Metric.areaFill
            case .perimeter: KropsTheme.Metric.perimeterFill
            case .year: KropsTheme.Metric.yearFill
            }
        }

        var ink: Color {
            switch self {
            case .area: KropsTheme.Metric.areaInk
            case .perimeter: KropsTheme.Metric.perimeterInk
            case .year: KropsTheme.Metric.yearInk
            }
        }
    }

    let title: String
    let value: String
    let kind: Kind

    var body: some View {
        VStack(spacing: 3) {
            Text(title).font(.caption)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .padding(.horizontal, 8)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
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
    GardenMetricTile(title: "Luas", value: "2,3 ha", kind: .area)
        .frame(width: 119).padding()
}
#endif
