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
                if garden.review != nil {
                    GardenStageLabel(stage: garden.stage)
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

/// The card's status line. Colour supports the icon and wording; it never carries the meaning alone.
struct GardenStageLabel: View {
    let stage: GardenStage

    private var content: (text: String, symbol: String, ink: Color, fill: Color) {
        switch stage {
        case .incomplete:
            ("Lengkapi profil kebun", "exclamationmark.circle.fill", KropsTheme.warningText, KropsTheme.warningFill)
        case .readyForReview:
            ("Siap diajukan untuk peninjauan", "paperplane.fill", KropsTheme.primaryText, KropsTheme.Metric.areaFill)
        case .inReview(.scheduled):
            ("Kunjungan petugas dijadwalkan", "calendar.badge.clock", KropsTheme.warningText, KropsTheme.warningFill)
        case .inReview:
            ("Dalam proses peninjauan", "hourglass", KropsTheme.secondaryText, KropsTheme.cardFill)
        case .results(let downloaded):
            (downloaded ? "Hasil analisis tersedia" : "Hasil analisis baru tersedia", "chart.bar.fill",
             KropsTheme.primaryText, KropsTheme.Metric.areaFill)
        }
    }

    var body: some View {
        let content = content
        HStack(spacing: 6) {
            Image(systemName: content.symbol)
            Text(content.text)
            Spacer(minLength: 0)
            if stage.needsAction {
                Image(systemName: "chevron.right").font(.caption.weight(.semibold))
            }
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(content.ink)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
        .background(content.fill, in: Capsule())
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
