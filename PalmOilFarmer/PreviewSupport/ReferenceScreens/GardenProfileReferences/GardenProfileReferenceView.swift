#if DEBUG
import SwiftUI

enum GardenProfileReferenceLayout {
    case standard, overview, chart
}

/// Static historical layouts reuse production components without a second app flow.
struct GardenProfileReferenceView: View {
    let garden: Garden
    var referenceMapImage: String? = nil
    var metrics: GardenDisplayMetrics? = nil
    var showsHeader = true
    var layout = GardenProfileReferenceLayout.standard
    var chartValues: [Double] = []
    var reviewStatus: ReviewStatus? = nil

    var body: some View {
        Group {
            switch layout {
            case .standard:
                GardenProfileContentView(garden: garden, referenceMapImage: referenceMapImage,
                    metrics: metrics, showsHeader: showsHeader,
                    currentReviewStatus: reviewStatus ?? garden.review?.status,
                    isComplete: garden.isProfileComplete,
                    onBack: {}, onEditGarden: {}, onEditProfile: {}, onReviewAction: {},
                    onViewSummary: {}, onViewReviewInformation: {})
            case .overview:
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        map.frame(height: 201).clipShape(RoundedRectangle(cornerRadius: 16))
                        Text(garden.name).font(.title)
                        GardenMetricsReferenceView(garden: garden, metrics: metrics)
                    }
                    .padding(16)
                }
            case .chart:
                ScrollView {
                    VStack(spacing: 16) {
                        map.frame(height: 201)
                        FertilizerChartReferenceView(values: chartValues, onContinue: {})
                    }
                }
            }
        }
        .background(KropsTheme.surfaceBackground)
    }

    private var map: some View {
        GardenMapView(boundary: garden.boundary, referenceImage: referenceMapImage)
    }
}

#Preview("Profil · Belum lengkap") {
    GardenProfileReferenceView(garden: GardenPreviewData.garden,
        referenceMapImage: "CodedProfileMap", metrics: GardenPreviewData.metrics)
}
#Preview("Profil · Lengkap") {
    GardenProfileReferenceView(garden: GardenPreviewData.completedGarden,
        referenceMapImage: "CodedProfileMap", metrics: GardenPreviewData.metrics)
}
#Preview("Profil · Overview") {
    GardenProfileReferenceView(garden: GardenPreviewData.garden,
        referenceMapImage: "GardenProfileMap", metrics: GardenPreviewData.metrics,
        showsHeader: false, layout: .overview)
}
#Preview("Profil · Grafik") {
    GardenProfileReferenceView(garden: GardenPreviewData.fertilizedGarden,
        referenceMapImage: "GardenProfileMap", metrics: GardenPreviewData.metrics,
        showsHeader: false, layout: .chart, chartValues: [1, 3, 1.5, 0.5])
}
#endif
