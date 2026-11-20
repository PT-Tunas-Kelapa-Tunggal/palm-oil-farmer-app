import SwiftUI

/// "Profil Kebun" screen, pushed from the garden list.
struct GardenProfileScreen: View {
    @State private var viewModel: GardenProfileViewModel
    private let referenceMapImage: String?
    private let onOpenRequestAssessment: (() -> Void)?
    private let onOpenResultOverview: (() -> Void)?
    private let onOpenNutrientCondition: (() -> Void)?
    private let onOpenFertilizerEstimation: (() -> Void)?

    init(
        viewModel: GardenProfileViewModel,
        referenceMapImage: String? = nil,
        onOpenRequestAssessment: (() -> Void)? = nil,
        onOpenResultOverview: (() -> Void)? = nil,
        onOpenNutrientCondition: (() -> Void)? = nil,
        onOpenFertilizerEstimation: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.referenceMapImage = referenceMapImage
        self.onOpenRequestAssessment = onOpenRequestAssessment
        self.onOpenResultOverview = onOpenResultOverview
        self.onOpenNutrientCondition = onOpenNutrientCondition
        self.onOpenFertilizerEstimation = onOpenFertilizerEstimation
    }

    @AppStorage("gardenReview.hideIntroduction") private var hideReviewIntroduction = false
    @Environment(\.dismiss) private var dismiss
    private var garden: Garden { viewModel.garden }
    private var currentReviewStatus: ReviewStatus? { viewModel.reviewViewModel.activeStatus ?? garden.review?.status }
    private var currentReport: FertilizerRecommendationReport? {
        viewModel.reviewViewModel.activeReport ?? (currentReviewStatus == .completed ? DemoReviewReport.make(for: garden) : nil)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        profileContent
        .sheet(item: rootSheet, onDismiss: viewModel.sheetDidDismiss) { presentation in
            sheetContent(presentation)
        }
        .confirmationDialog("Hapus kebun?", isPresented: $viewModel.showsDeleteConfirmation, titleVisibility: .visible) {
            Button("Hapus kebun", role: .destructive) { _ = viewModel.delete() }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Kebun \"\(garden.name)\" beserta riwayat pupuk dan panennya akan dihapus. Tindakan ini tidak dapat dibatalkan.")
        }
        .alert("Kebun belum dihapus", isPresented: $viewModel.showsDeleteError) {
            Button("Mengerti", role: .cancel) {}
        } message: {
            Text("Data tidak dapat dihapus dari perangkat. Coba lagi.")
        }
        .navigationDestination(isPresented: $viewModel.showsSummary) {
            GardenProfileSummaryView(garden: garden,
                onClose: viewModel.closeSummary, onEdit: viewModel.editSummary)
                .navigationDestination(item: summaryDestination) { presentation in
                    pushedContent(presentation)
                }
        }
        .navigationDestination(item: rootDestination) { presentation in
            pushedContent(presentation)
        }
        .sheet(isPresented: $viewModel.showsReviewStatus) {
            AssessmentStatusView(
                viewModel: AssessmentStatusViewModel(
                    status: currentReviewStatus ?? .submitted,
                    detailEvents: viewModel.reviewViewModel.detailEvents
                ),
                onAdvance: {
                    advanceAction?()
                }
            )
        }
        .navigationDestination(isPresented: $viewModel.showsResults) {
            resultsDestination
        }
        .onChange(of: viewModel.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .task {
            await viewModel.loadReview()
            if let stream = viewModel.observeReviewUpdates() {
                for await update in stream {
                    guard !Task.isCancelled else { break }
                    viewModel.reviewViewModel.applyUpdate(update)
                }
            }
        }
    }

    /// The review request and the profile form are pages pushed onto the stack; the rest are sheets.
    private static func isPushed(_ kind: GardenProfileSheet.Kind) -> Bool {
        kind == .review || kind == .profile
    }

    private var rootSheet: Binding<GardenProfileSheet?> {
        Binding(
            get: {
                guard !viewModel.showsSummary, let sheet = viewModel.sheet, !Self.isPushed(sheet.kind) else { return nil }
                return sheet
            },
            set: { viewModel.sheet = $0 }
        )
    }

    /// Pushed from the profile page itself.
    private var rootDestination: Binding<GardenProfileSheet?> {
        pushedDestination { !viewModel.showsSummary || $0 == .review }
    }

    /// Pushed from the history page ("Ubah" opens the profile form on top of it).
    private var summaryDestination: Binding<GardenProfileSheet?> {
        pushedDestination { viewModel.showsSummary && $0 == .profile }
    }

    private func pushedDestination(where shows: @escaping (GardenProfileSheet.Kind) -> Bool) -> Binding<GardenProfileSheet?> {
        Binding(
            get: {
                guard let sheet = viewModel.sheet, Self.isPushed(sheet.kind), shows(sheet.kind) else { return nil }
                return sheet
            },
            set: { newValue in
                // Back button or swipe back: end the session like a dismissed sheet.
                if newValue == nil, let kind = viewModel.sheet?.kind, Self.isPushed(kind) {
                    viewModel.sheetDidDismiss()
                }
            }
        )
    }

    /// A pushed page that closed itself (saved or tapped ‹) clears `sheet` first; finish the session once it is gone.
    private func pushedContent(_ presentation: GardenProfileSheet) -> some View {
        sheetContent(presentation)
            .onDisappear {
                if viewModel.sheet == nil {
                    viewModel.sheetDidDismiss()
                }
            }
    }

    private var deleteAction: (() -> Void)? {
        guard viewModel.canDelete else { return nil }
        return { viewModel.requestDelete() }
    }

    private var profileContent: some View {
        GardenProfileContentView(
            garden: garden, referenceMapImage: referenceMapImage, profileJustSaved: viewModel.profileJustSaved, currentReviewStatus: currentReviewStatus, isComplete: viewModel.isComplete,
            onBack: viewModel.close, onEditGarden: { viewModel.open(.details) },
            onEditProfile: { viewModel.open(.profile) },
            onReviewAction: {
                if currentReviewStatus == nil {
                    guard viewModel.isComplete else { return }
                    if !hideReviewIntroduction {
                        viewModel.open(.reviewInformation)
                    } else if let onOpenRequestAssessment {
                        onOpenRequestAssessment()
                    } else {
                        viewModel.reviewAction(viewModel.reviewViewModel.action(for: garden))
                    }
                } else if currentReviewStatus == .completed {
                    if let onOpenResultOverview {
                        onOpenResultOverview()
                    } else if let onOpenNutrientCondition {
                        onOpenNutrientCondition()
                    } else {
                        viewModel.reviewAction(viewModel.reviewViewModel.action(for: garden))
                    }
                } else {
                    viewModel.reviewAction(viewModel.reviewViewModel.action(for: garden))
                }
            },
            onViewSummary: viewModel.openSummary,
            onViewReviewInformation: { viewModel.open(.reviewInformation) },
            onDelete: deleteAction,
            assessmentCompletedAt: viewModel.reviewViewModel.completedAt ?? garden.review?.date(for: .completed),
            assessmentResultByteCount: currentReviewStatus == .completed ? PlaceholderAssessmentResultsDownloadRepository.resultByteCount : nil
        )
    }

    @ViewBuilder
    private func sheetContent(_ presentation: GardenProfileSheet) -> some View {
        switch presentation.kind {
        case .details:
            GardenDetailsView(viewModel: viewModel.makeDetailsEditor(for: presentation))
        case .profile:
            GardenProfileEditorView(viewModel: viewModel.makeProfileEditor(for: presentation),
                onClose: { viewModel.closeSheet(presentation) })
        case .review:
            if let request = viewModel.makeReviewRequest(for: presentation) {
                ReviewRequestView(flow: request)
            }
        case .reviewInformation:
            GardenReviewInformationView(
                onClose: { viewModel.closeSheet(presentation) },
                onApply: {
                    viewModel.closeSheet(presentation)
                    if let onOpenRequestAssessment {
                        onOpenRequestAssessment()
                    } else {
                        guard viewModel.isComplete else { return }
                        viewModel.applyForReview(from: presentation,
                            action: viewModel.reviewViewModel.action(for: garden))
                    }
                })
        }
    }



    private var advanceAction: (() -> Void)? {
        guard garden.review != nil else { return nil }
        return { viewModel.updateReview { $0.advance() } }
    }

    @ViewBuilder
    private var resultsDestination: some View {
        NutrientConditionView(
            viewModel: NutrientConditionViewModel(
                repository: CloudKitNutrientConditionRepository(
                    containerIdentifier: AppConfiguration.cloudKitContainerIdentifier
                ),
                gardenId: garden.id.uuidString
            ),
            onBack: { viewModel.showsResults = false },
            onOpenFertilizerEstimation: onOpenFertilizerEstimation
        )
    }

}

#if DEBUG
#Preview("Profil · Alur interaktif") {
    NavigationStack {
        GardenProfileScreen(viewModel: GardenProfileCanvasFixtures.makeViewModel(complete: false),
                            referenceMapImage: "ProfileReferenceSatellite")
    }
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#Preview("Profil · Ringkasan dan pengajuan") {
    NavigationStack {
        GardenProfileScreen(viewModel: GardenProfileCanvasFixtures.makeViewModel(complete: true),
                            referenceMapImage: "ProfileReferenceSatellite")
    }
    .environment(\.locale, Locale(identifier: "id_ID"))
}
#endif
