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
                .sheet(item: $viewModel.sheet, onDismiss: viewModel.sheetDidDismiss) { presentation in
                    sheetContent(presentation)
                }
        }
        .navigationDestination(item: reviewDestination) { presentation in
            Group {
                if let request = viewModel.makeReviewRequest(for: presentation) {
                    ReviewRequestView(flow: request)
                }
            }
            .onDisappear {
                if viewModel.sheet == nil {
                    viewModel.sheetDidDismiss()
                }
            }
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

    private var rootSheet: Binding<GardenProfileSheet?> {
        Binding(
            get: {
                guard !viewModel.showsSummary, viewModel.sheet?.kind != .review else { return nil }
                return viewModel.sheet
            },
            set: { viewModel.sheet = $0 }
        )
    }

    private var reviewDestination: Binding<GardenProfileSheet?> {
        Binding(
            get: { viewModel.sheet?.kind == .review ? viewModel.sheet : nil },
            set: { newValue in
                if newValue == nil, viewModel.sheet?.kind == .review {
                    viewModel.sheetDidDismiss()
                }
            }
        )
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
            onDelete: deleteAction
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
