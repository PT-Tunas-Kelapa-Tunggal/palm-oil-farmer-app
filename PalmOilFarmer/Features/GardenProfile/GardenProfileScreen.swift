import SwiftUI

enum GardenProfileLayout {
    case standard, overview, chart
}

struct GardenProfileScreen: View {
    let garden: Garden
    let onUpdate: (Garden) -> Bool
    let onDelete: ((Garden) -> Bool)?
    let onUpdateReview: ((GardenReview) -> Bool)?
    var referenceMapImage: String? = nil
    var metrics: GardenDisplayMetrics? = nil
    var showsHeader = true
    var layout = GardenProfileLayout.standard
    var chartValues: [Double] = []
    var reviewStatus: ReviewStatus? = nil
    var reviewEntries: [ReviewTimelineEntry] = []
    var recommendationReport: FertilizerRecommendationReport? = nil
    var recommendationResult: FertilizerRecommendationsResult? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var editor: HistoryEditor?
    @State private var showsReview = false
    @State private var showsReviewForm = false
    @State private var receivedReview: GardenReview?
    @State private var submittedReviewNeedsNavigation = false
    @State private var reviewError: String?
    @Environment(\.reviewService) private var reviewService
    @State private var showsReviewStatus = false
    @State private var showsResults = false
    @State private var showsGardenEditor = false
    @State private var showsDeleteConfirmation = false
    @State private var showsDeleteError = false
    @State private var isNavigationOverMap = true

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
        recommendationResult: FertilizerRecommendationsResult? = nil,
        onDelete: ((Garden) -> Bool)? = nil,
        onUpdateReview: ((GardenReview) -> Bool)? = nil,
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
        self.recommendationResult = recommendationResult
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onUpdateReview = onUpdateReview
    }

    private var demoReview: GardenReview? {
        guard garden.review?.isLocalSimulation == true else { return nil }
        return garden.review
    }

    private var currentReviewStatus: ReviewStatus? { demoReview?.status ?? garden.review?.status ?? reviewStatus }
    private var currentReviewEntries: [ReviewTimelineEntry] { demoReview?.entries ?? garden.review?.entries ?? reviewEntries }
    private var currentReport: FertilizerRecommendationReport? {
        if demoReview?.status == .completed { return .local(for: garden) }
        return garden.review?.report ?? recommendationReport
    }

    private var fertilizers: [FertilizerRecord] { garden.fertilizerRecords ?? [] }

    var body: some View {
        ScrollView {
            GardenProfileContent(
                garden: garden, referenceMapImage: referenceMapImage, metrics: metrics,
                showsHeader: showsHeader, layout: layout, chartValues: chartValues,
                currentReviewStatus: currentReviewStatus,
                onEditFertilizer: { editor = .fertilizer },
                onEditHarvest: { editor = .harvest },
                onReview: {
                    if currentReviewStatus == .completed, currentReport != nil {
                        showsResults = true
                    } else if currentReviewStatus != nil {
                        showsReviewStatus = true
                    } else {
                        showsReview = true
                    }
                }
            )
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectHidden(isNavigationOverMap, for: .top)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top < 240
        } action: { _, isOverMap in
            isNavigationOverMap = isOverMap
        }
        .refreshable { await refreshReview() }
        .ignoresSafeArea(edges: showsHeader && layout == .standard ? .top : [])
        .background(KropsTheme.background.ignoresSafeArea())
        .navigationTitle(showsHeader && layout == .standard ? "Detail Kebun" : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(showsHeader && layout == .standard ? .visible : .hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(isNavigationOverMap ? .hidden : .visible, for: .navigationBar)
        .toolbar {
            if showsHeader && layout == .standard {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Edit kebun", systemImage: "pencil") { showsGardenEditor = true }
                        if onDelete != nil {
                            Button("Hapus kebun", systemImage: "trash", role: .destructive) {
                                showsDeleteConfirmation = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel("Opsi kebun")
                }
            }
        }
        .task(id: garden.id) { await refreshReview(reportsErrors: false) }
        .alert("Status peninjauan", isPresented: Binding(
            get: { reviewError != nil }, set: { if !$0 { reviewError = nil } }
        )) {
            Button("Mengerti", role: .cancel) {}
        } message: { Text(reviewError ?? "") }
        .sheet(isPresented: $showsGardenEditor) {
            GardenDetailsScreen(editing: garden, referenceMapImage: referenceMapImage, metrics: metrics, onSave: onUpdate)
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
                FertilizerHistoryScreen(records: fertilizers) { records in
                    var updated = garden
                    updated.fertilizerRecords = records
                    return onUpdate(updated)
                }
            case .harvest:
                HarvestHistoryScreen(record: garden.harvestRecord) { record in
                    var updated = garden
                    updated.harvestRecord = record
                    return onUpdate(updated)
                }
            }
        }
        .navigationDestination(isPresented: $showsReviewStatus) {
            if let status = currentReviewStatus {
                ReviewStatusScreen(gardenName: garden.name, status: status, entries: currentReviewEntries, downloadURL: currentReport?.downloadURL,
                                 onRefresh: { await refreshReview() },
                                 onAdvanceDemo: demoAdvanceAction) {
                    showsResults = true
                }
            }
        }
        .navigationDestination(isPresented: $showsResults) {
            if let recommendationResult {
                let report = FertilizerRecommendationsResultReportAdapter.makeReport(
                    from: recommendationResult,
                    for: garden
                )
                FertilizerRecommendationScreen(
                    report: report,
                    initialTab: .nutrients,
                    isDemo: true,
                    garden: garden
                )
            } else if let report = currentReport {
                FertilizerRecommendationScreen(report: report,
                                             initialTab: report.nutrients.isEmpty ? .allocation : .nutrients,
                                             isDemo: demoReview != nil, garden: garden)
            } else {
                ContentUnavailableView("Hasil peninjauan belum tersedia", systemImage: "chart.bar.doc.horizontal")
            }
        }
        .sheet(isPresented: $showsReview, onDismiss: {
            showsReviewForm = false
            if submittedReviewNeedsNavigation {
                submittedReviewNeedsNavigation = false
                showsReviewStatus = true
            }
        }) {
            ReviewSubmissionView(showsReviewForm: $showsReviewForm, onSubmit: submitReview)
        }
    }

    // Keep the server response across failed local saves so retry does not submit twice.
    private func submitReview(_ contact: ReviewContactDetails) async throws {
        let review: GardenReview
        if let receivedReview {
            review = receivedReview
        } else {
            do {
                review = try await reviewService.submit(garden, contact)
            } catch ReviewServiceError.unavailable {
                #if DEBUG
                review = .localSimulation(for: garden.id)
                #else
                throw ReviewServiceError.unavailable
                #endif
            }
            receivedReview = review
        }
        guard saveReview(review) else { throw ReviewServiceError.persistenceFailed }
        receivedReview = nil
        submittedReviewNeedsNavigation = true
        showsReview = false
    }

    private var demoAdvanceAction: (() -> Void)? {
        guard demoReview != nil else { return nil }
        return { advanceDemoReview() }
    }

    private func advanceDemoReview() {
        #if DEBUG
        guard let review = demoReview,
              let next = ReviewStatus(rawValue: review.status.rawValue + 1) else { return }
        if !saveReview(.localSimulation(for: garden.id, status: next)) {
            reviewError = "Status belum tersimpan di perangkat. Coba lagi."
        }
        #endif
    }

    private func saveReview(_ review: GardenReview) -> Bool {
        if let onUpdateReview { return onUpdateReview(review) }
        var updated = garden
        updated.review = review
        return onUpdate(updated)
    }

    @MainActor
    private func refreshReview(reportsErrors: Bool = true) async {
        guard garden.review?.isLocalSimulation != true else { return }
        do {
            let refresh = reportsErrors ? (reviewService.refreshInteractively ?? reviewService.refresh) : reviewService.refresh
            guard let review = try await refresh(garden) else { return }
            if !saveReview(review) {
                reviewError = "Status terbaru belum tersimpan di perangkat. Coba lagi."
            }
        } catch {
            guard reportsErrors, !Task.isCancelled else { return }
            reviewError = "Status belum dapat diperbarui. Periksa koneksi dan coba lagi."
        }
    }
}

#if DEBUG
#Preview("Detail Kebun · Sudah Diajukan") {
    var garden = GardenPreviewData.completedGarden
    garden.review = GardenReview(requestID: "preview", status: .submitted,
                                 entries: ReviewTimelineEntry.referenceEntries(for: .submitted))
    return NavigationStack {
        GardenProfileScreen(garden: garden, referenceMapImage: "CodedProfileMap",
                          metrics: GardenPreviewData.metrics, onUpdate: { _ in true })
    }
}
#Preview("Detail Kebun · Navigasi") {
    NavigationStack {
        Color.clear
            .navigationDestination(isPresented: .constant(true)) {
                GardenProfileScreen(garden: GardenPreviewData.completedGarden,
                                  referenceMapImage: "CodedProfileMap",
                                  metrics: GardenPreviewData.metrics,
                                  onDelete: { _ in true }, onUpdate: { _ in true })
            }
    }
}
#Preview("01 Copy 3 · Lengkapi Pupuk") {
    GardenProfileScreen(garden: GardenPreviewData.garden, referenceMapImage: "CodedProfileMap",
                      metrics: GardenPreviewData.metrics, onUpdate: { _ in true })
}
#Preview("01 Copy 4 · Lengkapi Panen", traits: .fixedLayout(width: 402, height: 1315)) {
    GardenProfileScreen(garden: GardenPreviewData.fertilizedGarden, referenceMapImage: "CodedProfileMap",
                      metrics: GardenPreviewData.metrics, onUpdate: { _ in true })
}
#Preview("01 Copy 7 · Profil Lengkap", traits: .fixedLayout(width: 402, height: 1160)) {
    GardenProfileScreen(garden: GardenPreviewData.completedGarden, referenceMapImage: "CodedProfileMap",
                      metrics: GardenPreviewData.metrics, onUpdate: { _ in true })
}
#Preview("01 Copy 2 · Ringkasan") {
    GardenProfileScreen(garden: GardenPreviewData.garden, referenceMapImage: "GardenProfileMap",
                      metrics: GardenPreviewData.metrics, showsHeader: false, layout: .overview, onUpdate: { _ in true })
}
#Preview("01 Copy 6 · Grafik") {
    GardenProfileScreen(garden: GardenPreviewData.fertilizedGarden, referenceMapImage: "GardenProfileMap",
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
    GardenProfileScreen(garden: garden, referenceMapImage: "CodedProfileMap",
                      metrics: GardenPreviewData.metrics, onUpdate: {
        garden = $0
        return true
    })
}
#endif
