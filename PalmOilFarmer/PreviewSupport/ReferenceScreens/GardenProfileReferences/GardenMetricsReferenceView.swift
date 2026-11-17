#if DEBUG
import SwiftUI

struct GardenMetricsReferenceView: View {
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
            GardenMetricReferenceTile(title: "Luas", value: displayMetrics.area, kind: .area)
            GardenMetricReferenceTile(title: "Perimeter", value: displayMetrics.perimeter, kind: .perimeter)
            GardenMetricReferenceTile(title: "Tahun tanam", value: String(garden.plantingYear), kind: .year)
        }
    }
}

struct GardenMetricReferenceTile: View {
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
        VStack(alignment: .leading, spacing: 10) {
            Group {
                switch kind {
                case .area: GardenAreaIcon().scaleEffect(1.1)
                case .perimeter: Image(systemName: "rectangle.dashed")
                case .year: Image(systemName: "calendar")
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(kind.ink)
            .frame(width: 32, height: 32)
            .background(kind.ink.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.headline).foregroundStyle(.primary)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(kind.fill, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Garden Summary", traits: .sizeThatFitsLayout) {
    GardenMetricsReferenceView(garden: GardenPreviewData.garden, metrics: GardenPreviewData.metrics)
        .padding(16)
        .frame(width: 402)
        .background(KropsTheme.background)
}

#Preview("Metric Tile", traits: .sizeThatFitsLayout) {
    GardenMetricReferenceTile(title: "Luas", value: "2,3 ha", kind: .area)
        .frame(width: 119).padding()
}
#endif

#endif
