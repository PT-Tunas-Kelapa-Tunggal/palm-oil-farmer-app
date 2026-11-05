import SwiftUI

/// The same profile layout serves production MVVM-C and existing reference/experiment callers.
struct GardenProfileContent: View {
    let garden: Garden
    var referenceMapImage: String? = nil
    var metrics: GardenDisplayMetrics? = nil
    var showsHeader = true
    var layout = GardenProfileLayout.standard
    var chartValues: [Double] = []
    let currentReviewStatus: ReviewStatus?
    let isComplete: Bool
    let onBack: () -> Void
    let onEditGarden: () -> Void
    let onEditFertilizer: () -> Void
    let onEditHarvest: () -> Void
    let onReviewAction: () -> Void
    var onDelete: (() -> Void)? = nil
    @State private var isToolbarOverContent = false

    private var fertilizers: [FertilizerRecord] { garden.fertilizerRecords ?? [] }
    private var hasHero: Bool { showsHeader && layout == .standard }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                profileContent(topInset: geometry.safeAreaInsets.top)
                    .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: hasHero ? .top : [])
            .onScrollGeometryChange(for: Bool.self) { scroll in
                // The hero is 380 pt tall; the toolbar bottom sits about 68 pt below the safe area.
                scroll.contentOffset.y + scroll.contentInsets.top > 380 - geometry.safeAreaInsets.top - 68
            } action: { _, isOver in
                isToolbarOverContent = isOver
            }
            .overlay(alignment: .top) {
                if hasHero {
                    HeroToolbar(
                        title: "Detail Kebun",
                        onBack: onBack,
                        onEdit: onEditGarden,
                        onDelete: onDelete,
                        lockedReason: currentReviewStatus == nil ? nil : "Sudah diajukan untuk peninjauan",
                        isOverContent: isToolbarOverContent
                    )
                    .background {
                        Rectangle()
                            .fill(.bar)
                            .ignoresSafeArea(edges: .top)
                            .opacity(isToolbarOverContent ? 1 : 0)
                    }
                }
            }
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func profileContent(topInset: CGFloat) -> some View {
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
                if hasHero {
                    MapHeroView(title: "Detail Kebun", topInset: topInset, onBack: onBack,
                                showsToolbar: false) {
                        GardenMapView(boundary: garden.boundary, referenceImage: referenceMapImage)
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
                    GardenHistoryChart(values: chartValues) { onEditHarvest() }
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                        .padding(.top, 8)
                    profileProgress(step: .harvest)
                } else {
                    if isComplete {
                        PrimaryActionButton(title: reviewActionTitle, systemImage: reviewActionImage,
                                            imagePlacement: .trailing,
                                            isProminent: currentReviewStatus == nil || currentReviewStatus == .completed) {
                            onReviewAction()
                        }
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                        .padding(.vertical, 8)
                    }

                    if !fertilizers.isEmpty {
                        fertilizerHistory
                    }

                    if let harvest = garden.harvestRecord {
                        VStack(spacing: 16) {
                            GardenSectionHeader(title: "Riwayat Panen") { onEditHarvest() }
                            HarvestHistoryCard(record: harvest)
                        }
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                        .padding(.vertical, 8)
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
        default: "Lihat status peninjauan"
        }
    }

    private var reviewActionImage: String {
        currentReviewStatus == nil ? "paperplane.fill" : "chevron.right"
    }

    private var map: some View {
        GardenMapView(boundary: garden.boundary, referenceImage: referenceMapImage)
            .frame(height: 201)
    }

    private var fertilizerHistory: some View {
        VStack(spacing: 16) {
            GardenSectionHeader(title: "Riwayat pupuk") { onEditFertilizer() }
            VStack(spacing: 8) {
                ForEach(fertilizers) { record in
                    FertilizerHistoryCard(record: record)
                }
            }
        }
        .padding(.horizontal, KropsTheme.Spacing.screen)
        .padding(.top, 8)
        .padding(.bottom, garden.harvestRecord == nil ? 24 : 8)
    }

    private func profileProgress(step: GardenProfileStep) -> some View {
        GardenProfileProgressView(step: step) {
            if step == .fertilizer { onEditFertilizer() } else { onEditHarvest() }
        }
    }

}
