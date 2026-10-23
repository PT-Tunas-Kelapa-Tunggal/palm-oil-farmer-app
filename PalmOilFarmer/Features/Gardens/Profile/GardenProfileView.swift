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
    @State private var showsSignInNotice = false
    @State private var showsReviewStatus = false
    @State private var showsResults = false
    @State private var showsGardenEditor = false
    @State private var showsDeleteConfirmation = false
    @State private var showsDeleteError = false

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
    private var isComplete: Bool { !fertilizers.isEmpty && garden.harvestRecord != nil }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                profileContent(topInset: geometry.safeAreaInsets.top)
                    .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: showsHeader && layout == .standard ? .top : [])
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
            if let reviewStatus {
                ReviewStatusView(gardenName: garden.name, status: reviewStatus, entries: reviewEntries) {
                    showsResults = true
                }
            }
        }
        .navigationDestination(isPresented: $showsResults) {
            if let recommendationReport {
                FertilizerRecommendationView(report: recommendationReport)
            } else {
                ContentUnavailableView("Hasil peninjauan belum tersedia", systemImage: "chart.bar.doc.horizontal")
            }
        }
        .sheet(isPresented: $showsReview) {
            ReviewRequestView {
                showsSignInNotice = true
            }
            .alert("Masuk belum tersedia", isPresented: $showsSignInNotice) {
                Button("Mengerti", role: .cancel) {}
            } message: {
                Text("Layanan akun dan pengajuan peninjauan belum terhubung.")
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
                if showsHeader && layout == .standard {
                    MapHeroView(
                        title: garden.name,
                        topInset: topInset,
                        onBack: { dismiss() },
                        onEdit: { showsGardenEditor = true },
                        onDelete: onDelete == nil ? nil : { showsDeleteConfirmation = true }
                    ) {
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
                                            imagePlacement: .trailing) {
                            if reviewStatus == .completed {
                                showsResults = true
                            } else if reviewStatus != nil {
                                showsReviewStatus = true
                            } else {
                                showsReview = true
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
        if reviewStatus == .completed { return "Lihat hasil peninjauan" }
        return reviewStatus == nil ? "Ajukan peninjauan" : "Periksa peninjauan"
    }

    private var reviewActionImage: String {
        if reviewStatus == .completed { return "chart.bar.fill" }
        return reviewStatus == nil ? "paperplane.fill" : "stopwatch"
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
