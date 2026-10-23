import SwiftUI

enum GardenProfileLayout {
    case standard, overview, chart
}

struct GardenProfileView: View {
    let garden: Garden
    let onUpdate: (Garden) -> Bool
    let onDelete: ((Garden) -> Bool)?
    var referenceMapImage: String? = nil
    var metrics: GardenDisplayMetrics? = nil
    var showsHeader = true
    var layout = GardenProfileLayout.standard
    var chartValues: [Double] = []
    var reviewStatus: ReviewStatus? = nil
    var reviewEntries: [ReviewTimelineEntry] = []
    var recommendationReport: FertilizerRecommendationReport? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var editor: HistoryEditor?
    @State private var showsReview = false
    @State private var showsReviewStatus = false
    @State private var opensStatusAfterReview = false
    @State private var showsResults = false
    @State private var showsGardenEditor = false
    @State private var showsDeleteConfirmation = false
    @State private var showsDeleteError = false
    /// True once the map has scrolled under the pinned toolbar.
    @State private var isToolbarOverContent = false

    private enum HistoryEditor: String, Identifiable {
        case fertilizer, harvest
        var id: String { rawValue }
    }

    init(
        garden: Garden,
        referenceMapImage: String? = nil,
        metrics: GardenDisplayMetrics? = nil,
        showsHeader: Bool = true,
        layout: GardenProfileLayout = .standard,
        chartValues: [Double] = [],
        reviewStatus: ReviewStatus? = nil,
        reviewEntries: [ReviewTimelineEntry] = [],
        recommendationReport: FertilizerRecommendationReport? = nil,
        onDelete: ((Garden) -> Bool)? = nil,
        onUpdate: @escaping (Garden) -> Bool
    ) {
        self.garden = garden
        self.referenceMapImage = referenceMapImage
        self.metrics = metrics
        self.showsHeader = showsHeader
        self.layout = layout
        self.chartValues = chartValues
        self.reviewStatus = reviewStatus
        self.reviewEntries = reviewEntries
        self.recommendationReport = recommendationReport
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }

    private var fertilizers: [FertilizerRecord] { garden.fertilizerRecords ?? [] }
    /// Reference previews pass a fixed status; the app reads the saved review.
    private var currentReviewStatus: ReviewStatus? { reviewStatus ?? garden.review?.status }
    private var currentReport: FertilizerRecommendationReport? {
        recommendationReport ?? (currentReviewStatus == .completed ? DemoReviewReport.make(for: garden) : nil)
    }
    private var hasHero: Bool { showsHeader && layout == .standard }
    private var isComplete: Bool { !fertilizers.isEmpty && garden.harvestRecord != nil }

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
                        onBack: { dismiss() },
                        onEdit: { showsGardenEditor = true },
                        onDelete: onDelete == nil ? nil : { showsDeleteConfirmation = true },
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
        .sheet(isPresented: $showsGardenEditor) {
            GardenDetailsView(editing: garden, referenceMapImage: referenceMapImage, metrics: metrics, onSave: onUpdate)
        }
        .confirmationDialog("Hapus kebun?", isPresented: $showsDeleteConfirmation, titleVisibility: .visible) {
            Button("Hapus kebun", role: .destructive) {
                guard let onDelete else { return }
                if onDelete(garden) {
                    dismiss()
                } else {
                    showsDeleteError = true
                }
            }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Kebun \"\(garden.name)\" beserta riwayat pupuk dan panennya akan dihapus. Tindakan ini tidak dapat dibatalkan.")
        }
        .alert("Kebun belum dihapus", isPresented: $showsDeleteError) {
            Button("Mengerti", role: .cancel) {}
        } message: {
            Text("Data tidak dapat dihapus dari perangkat. Coba lagi.")
        }
        .sheet(item: $editor) { editor in
            switch editor {
            case .fertilizer:
                FertilizerHistoryEditor(records: fertilizers) { records in
                    var updated = garden
                    updated.fertilizerRecords = records
                    return onUpdate(updated)
                }
            case .harvest:
                HarvestHistoryEditor(record: garden.harvestRecord) { record in
                    var updated = garden
                    updated.harvestRecord = record
                    return onUpdate(updated)
                }
            }
        }
        .navigationDestination(isPresented: $showsReviewStatus) {
            LiveGardenReader(garden: garden) { garden in
                if let status = reviewStatus ?? garden.review?.status {
                    ReviewStatusView(
                        gardenName: garden.name, status: status,
                        entries: reviewEntries.isEmpty
                            ? garden.review.map { ReviewTimelineEntry.entries(for: $0) } ?? []
                            : reviewEntries,
                        resultsDownloaded: garden.review?.resultsDownloaded ?? false,
                        onAdvance: garden.review == nil ? nil : { updateReview(of: garden) { $0.advance() } },
                        onDownloaded: { updateReview(of: garden) { $0.resultsDownloaded = true } }
                    ) {
                        showsResults = true
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showsResults) {
            if let currentReport {
                FertilizerRecommendationView(report: currentReport)
            } else {
                ContentUnavailableView("Hasil peninjauan belum tersedia", systemImage: "chart.bar.doc.horizontal")
            }
        }
        .sheet(isPresented: $showsReview, onDismiss: {
            if opensStatusAfterReview {
                opensStatusAfterReview = false
                showsReviewStatus = true
            }
        }) {
            ReviewRequestView { contact in
                var updated = garden
                updated.review = GardenReview(contact: contact)
                guard onUpdate(updated) else { throw ReviewSaveError() }
                opensStatusAfterReview = true
                showsReview = false
            }
        }
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
                    MapHeroView(title: "Detail Kebun", topInset: topInset, onBack: { dismiss() },
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
                    GardenHistoryChart(values: chartValues) { editor = .harvest }
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                        .padding(.top, 8)
                    profileProgress(step: .harvest)
                } else {
                    if isComplete {
                        PrimaryActionButton(title: reviewActionTitle, systemImage: reviewActionImage,
                                            imagePlacement: .trailing,
                                            isProminent: currentReviewStatus == nil || currentReviewStatus == .completed) {
                            switch currentReviewStatus {
                            case nil:
                                showsReview = true
                            case .completed where garden.review?.resultsDownloaded ?? (reviewStatus != nil):
                                showsResults = true
                            default:
                                showsReviewStatus = true
                            }
                        }
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                        .padding(.vertical, 8)
                    }

                    if !fertilizers.isEmpty {
                        fertilizerHistory
                    }

                    if let harvest = garden.harvestRecord {
                        VStack(spacing: 16) {
                            GardenSectionHeader(title: "Riwayat Panen") { editor = .harvest }
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

    private func updateReview(of garden: Garden, _ change: (inout GardenReview) -> Void) {
        guard var review = garden.review else { return }
        change(&review)
        var updated = garden
        updated.review = review
        _ = onUpdate(updated)
    }

    private var map: some View {
        GardenMapView(boundary: garden.boundary, referenceImage: referenceMapImage)
            .frame(height: 201)
    }

    private var fertilizerHistory: some View {
        VStack(spacing: 16) {
            GardenSectionHeader(title: "Riwayat pupuk") { editor = .fertilizer }
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
            editor = step == .fertilizer ? .fertilizer : .harvest
        }
    }

}

private struct ReviewSaveError: LocalizedError {
    var errorDescription: String? { "Pengajuan tidak dapat disimpan di perangkat. Coba lagi." }
}

#if DEBUG
#Preview("01 Copy 3 · Lengkapi Pupuk") {
    GardenProfileView(garden: GardenPreviewData.garden, referenceMapImage: "CodedProfileMap",
                      metrics: GardenPreviewData.metrics, onUpdate: { _ in true })
}
#Preview("01 Copy 4 · Lengkapi Panen", traits: .fixedLayout(width: 402, height: 1315)) {
    GardenProfileView(garden: GardenPreviewData.fertilizedGarden, referenceMapImage: "CodedProfileMap",
                      metrics: GardenPreviewData.metrics, onUpdate: { _ in true })
}
#Preview("01 Copy 7 · Profil Lengkap", traits: .fixedLayout(width: 402, height: 1160)) {
    GardenProfileView(garden: GardenPreviewData.completedGarden, referenceMapImage: "CodedProfileMap",
                      metrics: GardenPreviewData.metrics, onUpdate: { _ in true })
}
#Preview("01 Copy 2 · Ringkasan") {
    GardenProfileView(garden: GardenPreviewData.garden, referenceMapImage: "GardenProfileMap",
                      metrics: GardenPreviewData.metrics, showsHeader: false, layout: .overview, onUpdate: { _ in true })
}
#Preview("01 Copy 6 · Grafik") {
    GardenProfileView(garden: GardenPreviewData.fertilizedGarden, referenceMapImage: "GardenProfileMap",
                      metrics: GardenPreviewData.metrics, showsHeader: false, layout: .chart,
                      chartValues: [1, 3, 1.5, 0.5], onUpdate: { _ in true })
}
#Preview("History Chart", traits: .sizeThatFitsLayout) {
    GardenHistoryChart(values: [1, 3, 1.5, 0.5], onContinue: {}).padding(16).frame(width: 402)
}
#Preview("Profil · Panen tanpa pupuk", traits: .fixedLayout(width: 402, height: 1315)) {
    @Previewable @State var garden: Garden = {
        var garden = GardenPreviewData.completedGarden
        garden.fertilizerRecords = []
        return garden
    }()
    GardenProfileView(garden: garden, referenceMapImage: "CodedProfileMap",
                      metrics: GardenPreviewData.metrics, onUpdate: {
        garden = $0
        return true
    })
}
#endif
