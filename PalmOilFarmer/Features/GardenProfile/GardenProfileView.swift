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
    @Environment(GardenStore.self) private var store: GardenStore?
    @Environment(\.farmerReviewRepository) private var reviewRepository
    @State private var editor: HistoryEditor?
    @State private var showsReview = false
    @State private var showsReviewStatus = false
    @State private var showsResults = false
    @State private var showsGardenEditor = false
    @State private var showsDeleteConfirmation = false
    @State private var showsDeleteError = false
    @State private var activeReviewStatus: ReviewStatus?
    @State private var activeReviewEntries: [ReviewTimelineEntry] = []
    @State private var activeReport: FertilizerRecommendationReport?

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
    private var currentReviewStatus: ReviewStatus? { activeReviewStatus ?? reviewStatus ?? garden.review?.status }
    private var currentReport: FertilizerRecommendationReport? {
        activeReport ?? recommendationReport ?? (currentReviewStatus == .completed ? DemoReviewReport.make(for: garden) : nil)
    }

    var body: some View {
        GardenProfileContent(
            garden: garden, referenceMapImage: referenceMapImage, metrics: metrics,
            showsHeader: showsHeader, layout: layout, chartValues: chartValues,
            currentReviewStatus: currentReviewStatus, isComplete: garden.isProfileComplete,
            onBack: { dismiss() }, onEditGarden: { showsGardenEditor = true },
            onEditFertilizer: { editor = .fertilizer }, onEditHarvest: { editor = .harvest },
            onReviewAction: {
                switch currentReviewStatus {
                case nil: showsReview = true
                case .completed where (activeReviewStatus == .completed) || (garden.review?.resultsDownloaded ?? (reviewStatus != nil)):
                    showsResults = true
                default: showsReviewStatus = true
                }
            },
            onDelete: onDelete == nil ? nil : { showsDeleteConfirmation = true }
        )
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
                if let status = currentReviewStatus {
                    ReviewStatusView(
                        gardenName: garden.name, status: status,
                        entries: !activeReviewEntries.isEmpty ? activeReviewEntries : (reviewEntries.isEmpty
                            ? garden.review.map { ReviewTimelineEntry.entries(for: $0) } ?? []
                            : reviewEntries),
                        resultsDownloaded: (activeReviewStatus == .completed) || (garden.review?.resultsDownloaded ?? false),
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
        .sheet(isPresented: $showsReview) {
            ReviewRequestView { contact in
                if let store {
                    let saved = try await store.submitReview(for: garden, contact: contact)
                    activeReviewStatus = saved.status
                    activeReviewEntries = saved.timeline.entries(for: saved.status)
                } else {
                    try await submitReview(details: contact)
                }
                showsReview = false
            }
        }
        .task {
            await loadReview()
        }
    }

    private func updateReview(of garden: Garden, _ change: (inout GardenReview) -> Void) {
        guard var review = garden.review else { return }
        change(&review)
        var updated = garden
        updated.review = review
        _ = onUpdate(updated)
    }

    private func loadReview() async {
        if let existing = try? await reviewRepository.fetchRequest(for: garden.id) {
            await MainActor.run {
                activeReviewStatus = existing.status
                activeReviewEntries = existing.timeline.entries(for: existing.status)
                activeReport = existing.makeRecommendationReport()
            }
        }
    }

    private func submitReview(details: ReviewContactDetails) async throws {
        let request = PlantationReviewRequest(garden: garden, contact: details)

        let saved = try await reviewRepository.submitRequest(request)
        await MainActor.run {
            activeReviewStatus = saved.status
            activeReviewEntries = saved.timeline.entries(for: saved.status)
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
