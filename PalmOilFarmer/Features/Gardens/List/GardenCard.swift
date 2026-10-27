import SwiftUI

struct GardenCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let garden: Garden
    var referenceImage: String? = nil
    var metrics: GardenDisplayMetrics? = nil

    private var displayMetrics: GardenDisplayMetrics {
        metrics ?? GardenDisplayMetrics(boundary: garden.boundary)
    }

    var body: some View {
        let displayMetrics = displayMetrics
        let metricsLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 4))
        VStack(spacing: 0) {
            GardenMapView(boundary: garden.boundary, referenceImage: referenceImage)
                .frame(height: 201)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 8) {
                Text(garden.name)
                    .font(.title3.weight(.semibold))
                metricsLayout {
                    VStack(alignment: .leading, spacing: 6) {
                        Label { Text(displayMetrics.area) } icon: { GardenAreaIcon() }
                        Label(garden.soilType.rawValue, systemImage: "leaf")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: 6) {
                        Label(displayMetrics.perimeter, systemImage: "rectangle.dashed")
                        Label(String(garden.plantingYear), systemImage: "calendar")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.footnote)
                if let review = garden.review {
                    Label(review.status == .completed ? "Hasil peninjauan tersedia" : "Dalam proses peninjauan",
                          systemImage: review.status == .completed ? "checkmark.seal" : "clock")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Garden Card", traits: .sizeThatFitsLayout) {
    GardenCard(garden: GardenPreviewData.garden, referenceImage: "GardenCardMap",
               metrics: GardenDisplayMetrics(area: "2,4 ha", perimeter: "2324 m"))
        .padding(16)
        .frame(width: 402)
        .background(KropsTheme.background)
}
#endif
