import SwiftUI

/// The single interactive profile entry point.
struct GardenProfileScreen: View {
    @State private var flow: GardenProfileFlow
    @State private var previewReview: GardenReview?
    @State private var showsAssessmentStatus = false
    @State private var showsPreviewUpdateError = false
    @State private var isPresentingReviewCompletion = false
    @State private var showHistoryAfterConfirmationDismisses = false
    @State private var assessmentResults = AssessmentResultsViewModel(
        repository: PlaceholderAssessmentResultsDownloadRepository(),
        expectedByteCount: PlaceholderAssessmentResultsDownloadRepository.resultByteCount
    )
    private let referenceMapImage: String?

    init(flow: GardenProfileFlow, referenceMapImage: String? = nil) {
        _flow = State(initialValue: flow)
        self.referenceMapImage = referenceMapImage
    }

    @AppStorage("gardenReview.hideIntroduction") private var hideReviewIntroduction = false
    @Environment(\.dismiss) private var dismiss
    private var garden: Garden { flow.viewModel.garden }
    private var activePreviewReview: GardenReview? {
        guard flow.reviewPresentation.activeStatus == nil, garden.review == nil else { return nil }
        return previewReview
    }

    private var currentReviewStatus: ReviewStatus? {
        flow.reviewPresentation.activeStatus ?? garden.review?.status ?? activePreviewReview?.status
    }
    private var currentReport: FertilizerRecommendationReport? {
        flow.reviewPresentation.activeReport ?? (currentReviewStatus == .completed ? DemoReviewReport.make(for: garden) : nil)
    }

    var body: some View {
        @Bindable var model = flow.viewModel
        @Bindable var coordinator = flow.coordinator
        @Bindable var results = assessmentResults
        profileContent
        .blur(radius: showsAssessmentStatus ? 2 : 0)
        .sheet(isPresented: $showsAssessmentStatus, onDismiss: assessmentStatusDidDismiss) {
            if let review = activePreviewReview {
                AssessmentStatusView(
                    viewModel: AssessmentStatusViewModel(review: review),
                    onAdvance: advanceAssessmentPreview
                )
                .alert("Status belum dapat diperbarui", isPresented: $showsPreviewUpdateError) {
                    Button("Mengerti", role: .cancel) {}
                }
            }
        }
        .fullScreenCover(item: $results.confirmation, onDismiss: assessmentConfirmationDidDismiss) { confirmation in
            AssessmentResultsConfirmationView(
                confirmation: confirmation,
                gardenName: garden.name,
                downloadWasSimulated: assessmentResults.downloadWasSimulated,
                onContinue: { assessmentResults.confirmation = nil },
                onViewHistory: {
                    showHistoryAfterConfirmationDismisses = true
                    assessmentResults.confirmation = nil
                }
            )
        }
        .alert("Unduhan belum selesai", isPresented: $results.showsDownloadError) {
            Button("Mengerti", role: .cancel) {}
        } message: {
            Text("Coba unduh hasil peninjauan kembali.")
        }
        .sheet(item: rootSheet, onDismiss: coordinator.sheetDidDismiss) { presentation in
            sheetContent(presentation)
        }
        .confirmationDialog("Hapus kebun?", isPresented: $coordinator.showsDeleteConfirmation, titleVisibility: .visible) {
            Button("Hapus kebun", role: .destructive) { _ = model.delete() }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Kebun \"\(garden.name)\" beserta riwayat pupuk dan panennya akan dihapus. Tindakan ini tidak dapat dibatalkan.")
        }
        .alert("Kebun belum dihapus", isPresented: $model.showsDeleteError) {
            Button("Mengerti", role: .cancel) {}
        } message: {
            Text("Data tidak dapat dihapus dari perangkat. Coba lagi.")
        }
        .navigationDestination(isPresented: $coordinator.showsSummary) {
            GardenProfileSummaryView(garden: garden,
                onClose: coordinator.closeSummary, onEdit: coordinator.editSummary)
                .sheet(item: $coordinator.sheet, onDismiss: coordinator.sheetDidDismiss) { presentation in
                    sheetContent(presentation)
                }
        }
        .navigationDestination(item: reviewDestination) { presentation in
            assessmentDestination(presentation)
                .onDisappear {
                    if flow.coordinator.sheet == nil {
                        flow.coordinator.sheetDidDismiss()
                    }
                }
        }
        .navigationDestination(isPresented: $coordinator.showsReviewStatus) {
            statusDestination
        }
        .navigationDestination(isPresented: $coordinator.showsResults) {
            resultsDestination
        }
        .onChange(of: coordinator.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .task(id: model.gardenID) {
            refreshAssessmentPreview()
            assessmentResults.load(for: model.gardenID)
            await flow.reviewPresentation.load(for: model.gardenID, repository: flow.reviewRepository)
        }
    }

    private func assessmentDestination(_ presentation: GardenProfileSheet) -> some View {
        AssessmentRequestFlow(
            gardenID: garden.id,
            gardenName: garden.name,
            areaHectares: garden.boundary.areaHectares,
            contactRepository: DeviceAssessmentContactRepository(),
            submissionRepository: PlaceholderAssessmentSubmissionRepository(),
            onSubmitted: {
                if flow.coordinator.isCurrent(presentation) { refreshAssessmentPreview() }
            },
            onClose: { flow.coordinator.closeSheet(presentation) }
        )
    }

    private func refreshAssessmentPreview() {
        previewReview = try? PlaceholderAssessmentSubmissionRepository().loadReview(for: garden.id)
    }

    private func advanceAssessmentPreview() {
        do {
            if let advanced = try PlaceholderAssessmentSubmissionRepository().advanceReview(for: garden.id) {
                previewReview = advanced
                if advanced.status == .completed {
                    isPresentingReviewCompletion = true
                    showsAssessmentStatus = false
                }
            }
        } catch {
            showsPreviewUpdateError = true
        }
    }

    private func assessmentStatusDidDismiss() {
        guard isPresentingReviewCompletion else { return }
        assessmentResults.confirmation = .reviewCompleted
    }

    private func assessmentConfirmationDidDismiss() {
        isPresentingReviewCompletion = false
        guard showHistoryAfterConfirmationDismisses else { return }
        showHistoryAfterConfirmationDismisses = false
        showsAssessmentStatus = activePreviewReview?.status == .completed
    }

    private func openPreviewReview(_ review: GardenReview) {
        guard review.status == .completed else {
            showsAssessmentStatus = true
            return
        }
        switch assessmentResults.state {
        case .ready: assessmentResults.startDownload()
        case .downloading: assessmentResults.cancelDownload()
        case .downloaded: break
        }
    }

    private var rootSheet: Binding<GardenProfileSheet?> {
        Binding(
            get: {
                guard !flow.coordinator.showsSummary, flow.coordinator.sheet?.kind != .review else { return nil }
                return flow.coordinator.sheet
            },
            set: { flow.coordinator.sheet = $0 }
        )
    }

    private var reviewDestination: Binding<GardenProfileSheet?> {
        Binding(
            get: { flow.coordinator.sheet?.kind == .review ? flow.coordinator.sheet : nil },
            set: { newValue in
                if newValue == nil, flow.coordinator.sheet?.kind == .review {
                    flow.coordinator.sheetDidDismiss()
                }
            }
        )
    }

    private var deleteAction: (() -> Void)? {
        guard flow.viewModel.canDelete else { return nil }
        return { flow.coordinator.requestDelete() }
    }

    private var profileContent: some View {
        GardenProfileContentView(
            garden: garden, referenceMapImage: referenceMapImage, profileJustSaved: flow.coordinator.profileJustSaved, currentReviewStatus: currentReviewStatus, isComplete: flow.viewModel.isComplete,
            onBack: flow.coordinator.close, onEditGarden: { flow.coordinator.open(.details) },
            onEditProfile: { flow.coordinator.open(.profile) },
            onReviewAction: {
                if let review = activePreviewReview {
                    openPreviewReview(review)
                    return
                }
                guard flow.viewModel.isComplete else { return }
                if currentReviewStatus == nil && !hideReviewIntroduction {
                    flow.coordinator.open(.reviewInformation)
                } else {
                    flow.coordinator.reviewAction(flow.reviewPresentation.action(for: garden))
                }
            },
            onViewSummary: flow.coordinator.openSummary,
            onViewReviewInformation: { flow.coordinator.open(.reviewInformation) },
            onDelete: deleteAction,
            assessmentContactName: activePreviewReview?.contact.name,
            // Reveal the completed card once the profile is visible again.
            assessmentResultsState: activePreviewReview?.status == .completed && !isPresentingReviewCompletion
                ? assessmentResults.state : nil,
            assessmentCompletedAt: activePreviewReview?.date(for: .completed),
            assessmentResultByteCount: assessmentResults.expectedByteCount
        )
    }

    @ViewBuilder
    private func sheetContent(_ presentation: GardenProfileSheet) -> some View {
        switch presentation.kind {
        case .details:
            GardenDetailsView(flow: flow.makeDetailsEditor(presentation))
        case .profile:
            GardenProfileEditorView(model: flow.makeProfileEditor(presentation),
                onClose: { flow.coordinator.closeSheet(presentation) })
        case .review:
            NavigationStack {
                assessmentDestination(presentation)
            }
        case .reviewInformation:
            GardenReviewInformationView(
                onClose: { flow.coordinator.closeSheet(presentation) },
                onApply: {
                    guard flow.viewModel.isComplete else { return }
                    flow.coordinator.applyForReview(from: presentation,
                        action: flow.reviewPresentation.action(for: garden))
                })
        }
    }

    @ViewBuilder
    private var statusDestination: some View {
        if let status = currentReviewStatus {
            ReviewStatusView(
                gardenName: garden.name, status: status,
                entries: !flow.reviewPresentation.activeEntries.isEmpty ? flow.reviewPresentation.activeEntries
                    : garden.review.map { ReviewTimelineEntry.entries(for: $0) } ?? [],
                resultsDownloaded: flow.reviewPresentation.activeStatus == .completed || (garden.review?.resultsDownloaded ?? false),
                onAdvance: advanceAction,
                onDownloaded: { flow.viewModel.updateReview { $0.resultsDownloaded = true } },
                onViewResults: flow.coordinator.openResults
            )
        }
    }

    private var advanceAction: (() -> Void)? {
        guard garden.review != nil else { return nil }
        return { flow.viewModel.updateReview { $0.advance() } }
    }

    @ViewBuilder
    private var resultsDestination: some View {
        if let currentReport {
            FertilizerRecommendationView(report: currentReport)
        } else {
            ContentUnavailableView("Hasil peninjauan belum tersedia", systemImage: "chart.bar.doc.horizontal")
        }
    }

}

#if DEBUG
#Preview("Profil · Alur interaktif") {
    NavigationStack {
        GardenProfileScreen(flow: GardenProfileCanvasFixtures.makeFlow(complete: false),
                            referenceMapImage: "ProfileReferenceSatellite")
    }
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#Preview("Profil · Ringkasan dan pengajuan") {
    NavigationStack {
        GardenProfileScreen(flow: GardenProfileCanvasFixtures.makeFlow(complete: true),
                            referenceMapImage: "ProfileReferenceSatellite")
    }
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#endif
