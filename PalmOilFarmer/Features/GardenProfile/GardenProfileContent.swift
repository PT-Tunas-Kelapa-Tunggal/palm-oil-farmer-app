import SwiftUI

/// Profile layout only; presentation and review operations belong to GardenProfileScreen.
struct GardenProfileContent: View {
    let garden: Garden
    var referenceMapImage: String? = nil
    var metrics: GardenDisplayMetrics? = nil
    var showsHeader = true
    var layout = GardenProfileLayout.standard
    var chartValues: [Double] = []
    var currentReviewStatus: ReviewStatus? = nil
    let onEditFertilizer: () -> Void
    let onEditHarvest: () -> Void
    let onReview: () -> Void

    private var fertilizers: [FertilizerRecord] { garden.fertilizerRecords ?? [] }
    private var isComplete: Bool { !fertilizers.isEmpty && garden.harvestRecord != nil }

    @ViewBuilder
    var body: some View {
        if layout == .overview {
            VStack(spacing: 12) {
                map.clipShape(RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 8) {
                    Text(garden.name).font(.title)
                    GardenSummaryView(garden: garden, metrics: metrics)
                }
                .padding(10)
                .background(.background, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
            }
            .padding(.horizontal, KropsTheme.Spacing.screen)
        } else {
            VStack(spacing: 0) {
                if showsHeader && layout == .standard {
                    GardenMapView(boundary: garden.boundary, referenceImage: referenceMapImage)
                        .frame(height: 380)
                        .clipped()
                        .overlay(alignment: .top) {
                            // Keep the native navigation title readable over satellite imagery.
                            LinearGradient(colors: [.black.opacity(0.5), .clear],
                                           startPoint: .top, endPoint: .bottom)
                                .frame(height: 185)
                                .allowsHitTesting(false)
                        }
                } else {
                    map
                }
                Text(garden.name)
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)

                GardenSummaryView(garden: garden, metrics: metrics)
                    .padding(.horizontal, KropsTheme.Spacing.screen)
                    .padding(.vertical, 8)

                if layout == .chart {
                    GardenHistoryChart(values: chartValues, onContinue: onEditHarvest)
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                        .padding(.top, 8)
                    profileProgress(step: .harvest)
                } else {
                    if isComplete || currentReviewStatus != nil {
                        PrimaryActionButton(title: reviewActionTitle, systemImage: reviewActionImage,
                                            imagePlacement: .trailing, action: onReview)
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                        .padding(.vertical, 8)
                    }

                    if !fertilizers.isEmpty {
                        GardenFertilizerHistorySection(fertilizers: fertilizers, hasHarvest: garden.harvestRecord != nil) {
                            onEditFertilizer()
                        }
                    }

                    if let harvest = garden.harvestRecord {
                        GardenHarvestHistorySection(harvest: harvest) { onEditHarvest() }
                    }

                    if !isComplete {
                        profileProgress(step: fertilizers.isEmpty ? .fertilizer : .harvest)
                    }
                }
            }
        }
    }

    private var reviewActionTitle: String {
        switch currentReviewStatus {
        case nil: "Ajukan peninjauan"
        case .completed: "Lihat hasil peninjauan"
        default: "Lihat status pengajuan"
        }
    }

    private var reviewActionImage: String {
        currentReviewStatus == nil ? "paperplane.fill" : "chart.bar.fill"
    }

    private var map: some View {
        GardenMapView(boundary: garden.boundary, referenceImage: referenceMapImage)
            .frame(height: 201)
    }

    private func profileProgress(step: GardenProfileStep) -> some View {
        GardenProfileProgressView(step: step) {
            if step == .fertilizer {
                onEditFertilizer()
            } else {
                onEditHarvest()
            }
        }
    }

}

#if DEBUG
#Preview("Isi profil") {
    ScrollView {
        GardenProfileContent(garden: GardenPreviewData.completedGarden,
                             referenceMapImage: "CodedProfileMap",
                             showsHeader: false,
                             onEditFertilizer: {}, onEditHarvest: {}, onReview: {})
    }
}
#endif
