import SwiftUI

/// Production profile flow. Existing GardenProfileView callers retain their callback API.
struct GardenProfileScreen: View {
    @State private var flow: GardenProfileFlow
    init(flow: GardenProfileFlow) { _flow = State(initialValue: flow) }

    @Environment(\.dismiss) private var dismiss
    private var garden: Garden { flow.viewModel.garden }
    private var currentReviewStatus: ReviewStatus? { flow.reviewBridge.activeStatus ?? garden.review?.status }
    private var currentReport: FertilizerRecommendationReport? {
        flow.reviewBridge.activeReport ?? (currentReviewStatus == .completed ? DemoReviewReport.make(for: garden) : nil)
    }

    var body: some View {
        @Bindable var model = flow.viewModel
        @Bindable var coordinator = flow.coordinator
        profileContent
        .sheet(item: $coordinator.sheet, onDismiss: coordinator.sheetDidDismiss) { presentation in
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
        .navigationDestination(isPresented: $coordinator.showsReviewStatus) {
            statusDestination
        }
        .navigationDestination(isPresented: $coordinator.showsResults) {
            resultsDestination
        }
        .onChange(of: coordinator.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .task { await flow.reviewBridge.load(for: model.gardenID, repository: flow.reviewRepository) }
    }

    private var deleteAction: (() -> Void)? {
        guard flow.viewModel.canDelete else { return nil }
        return { flow.coordinator.requestDelete() }
    }

    private var profileContent: some View {
        GardenProfileContent(
            garden: garden, currentReviewStatus: currentReviewStatus, isComplete: flow.viewModel.isComplete,
            onBack: flow.coordinator.close, onEditGarden: { flow.coordinator.open(.details) },
            onEditFertilizer: { flow.coordinator.open(.fertilizer) }, onEditHarvest: { flow.coordinator.open(.harvest) },
            onReviewAction: {
                guard flow.viewModel.isComplete else { return }
                flow.coordinator.reviewAction(flow.reviewBridge.action(for: garden))
            },
            onDelete: deleteAction
        )
    }

    @ViewBuilder
    private func sheetContent(_ presentation: GardenProfileSheet) -> some View {
        switch presentation.kind {
        case .details:
            GardenDetailsView(flow: flow.makeDetailsEditor(presentation))
        case .fertilizer:
            FertilizerHistoryEditor(flow: flow.makeFertilizerEditor(presentation))
        case .harvest:
            HarvestHistoryEditor(flow: flow.makeHarvestEditor(presentation))
        case .review:
            ReviewRequestView { contact in
                try await submitReview(contact, from: presentation)
            }
        }
    }

    @ViewBuilder
    private var statusDestination: some View {
        if let status = currentReviewStatus {
            ReviewStatusView(
                gardenName: garden.name, status: status,
                entries: !flow.reviewBridge.activeEntries.isEmpty ? flow.reviewBridge.activeEntries
                    : garden.review.map { ReviewTimelineEntry.entries(for: $0) } ?? [],
                resultsDownloaded: flow.reviewBridge.activeStatus == .completed || (garden.review?.resultsDownloaded ?? false),
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

    // Consent/contact and asynchronous submission remain the existing Part 9 boundary.
    private func submitReview(_ contact: ReviewContactDetails, from presentation: GardenProfileSheet) async throws {
        guard flow.coordinator.isCurrent(presentation), flow.viewModel.isAvailable else { throw ReviewServiceError.unavailable }
        let saved = try await flow.submitReview(garden, contact)
        guard flow.coordinator.isCurrent(presentation) else { return }
        flow.reviewBridge.submitted(saved)
        flow.coordinator.closeSheet(presentation)
    }
}
