import SwiftUI

/// The single interactive profile entry point.
struct GardenProfileScreen: View {
    @State private var flow: GardenProfileFlow
    private let referenceMapImage: String?

    init(flow: GardenProfileFlow, referenceMapImage: String? = nil) {
        _flow = State(initialValue: flow)
        self.referenceMapImage = referenceMapImage
    }

    @AppStorage("gardenReview.hideIntroduction") private var hideReviewIntroduction = false
    @Environment(\.dismiss) private var dismiss
    private var garden: Garden { flow.viewModel.garden }
    private var currentReviewStatus: ReviewStatus? { flow.reviewPresentation.activeStatus ?? garden.review?.status }
    private var currentReport: FertilizerRecommendationReport? {
        flow.reviewPresentation.activeReport ?? (currentReviewStatus == .completed ? DemoReviewReport.make(for: garden) : nil)
    }

    var body: some View {
        @Bindable var model = flow.viewModel
        @Bindable var coordinator = flow.coordinator
        profileContent
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
        .navigationDestination(isPresented: $coordinator.showsReviewStatus) {
            statusDestination
        }
        .navigationDestination(isPresented: $coordinator.showsResults) {
            resultsDestination
        }
        .onChange(of: coordinator.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .task { await flow.reviewPresentation.load(for: model.gardenID, repository: flow.reviewRepository) }
    }

    private var rootSheet: Binding<GardenProfileSheet?> {
        Binding(get: { flow.coordinator.showsSummary ? nil : flow.coordinator.sheet },
                set: { flow.coordinator.sheet = $0 })
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
                guard flow.viewModel.isComplete else { return }
                if currentReviewStatus == nil && !hideReviewIntroduction {
                    flow.coordinator.open(.reviewInformation)
                } else {
                    flow.coordinator.reviewAction(flow.reviewPresentation.action(for: garden))
                }
            },
            onViewSummary: flow.coordinator.openSummary,
            onViewReviewInformation: { flow.coordinator.open(.reviewInformation) },
            onDelete: deleteAction
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
            ReviewRequestView(flow: flow.makeReviewRequest(presentation))
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
