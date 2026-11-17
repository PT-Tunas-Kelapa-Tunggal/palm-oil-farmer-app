import SwiftUI

/// Main screen displaying the Assessment Results Overview report (Ringkasan Hasil).
/// Sliced from Sketch: "Hasil Peninjauan / Ringkasan Hasil / Default"
@MainActor
public struct ResultOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ResultOverviewViewModel
    private let gardenBoundaryCoordinates: [FarmMapCoordinate]

    public var onBack: (() -> Void)?
    public var onOpenFertilizerSchedule: (() -> Void)?
    public var fertilizerScheduleTransitionNamespace: Namespace.ID?
    public var onOpenNutrientCondition: (() -> Void)?
    public var onOpenFarmGreenness: (() -> Void)?
    public var onOpenFertilizerEstimation: (() -> Void)?
    public var onOpenGardenIdentity: (() -> Void)?
    public var onOpenGardenLogs: (() -> Void)?
    public var onOpenAssessmentSubmission: (() -> Void)?

    public init(
        viewModel: ResultOverviewViewModel,
        gardenBoundaryCoordinates: [FarmMapCoordinate] = [],
        onBack: (() -> Void)? = nil,
        onOpenFertilizerSchedule: (() -> Void)? = nil,
        fertilizerScheduleTransitionNamespace: Namespace.ID? = nil,
        onOpenNutrientCondition: (() -> Void)? = nil,
        onOpenFarmGreenness: (() -> Void)? = nil,
        onOpenFertilizerEstimation: (() -> Void)? = nil,
        onOpenGardenIdentity: (() -> Void)? = nil,
        onOpenGardenLogs: (() -> Void)? = nil,
        onOpenAssessmentSubmission: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.gardenBoundaryCoordinates = gardenBoundaryCoordinates
        self.onBack = onBack
        self.onOpenFertilizerSchedule = onOpenFertilizerSchedule
        self.fertilizerScheduleTransitionNamespace = fertilizerScheduleTransitionNamespace
        self.onOpenNutrientCondition = onOpenNutrientCondition
        self.onOpenFarmGreenness = onOpenFarmGreenness
        self.onOpenFertilizerEstimation = onOpenFertilizerEstimation
        self.onOpenGardenIdentity = onOpenGardenIdentity
        self.onOpenGardenLogs = onOpenGardenLogs
        self.onOpenAssessmentSubmission = onOpenAssessmentSubmission
    }

    public init(
        gardenBoundaryCoordinates: [FarmMapCoordinate] = [],
        onBack: (() -> Void)? = nil,
        onOpenFertilizerSchedule: (() -> Void)? = nil,
        fertilizerScheduleTransitionNamespace: Namespace.ID? = nil,
        onOpenNutrientCondition: (() -> Void)? = nil,
        onOpenFarmGreenness: (() -> Void)? = nil,
        onOpenFertilizerEstimation: (() -> Void)? = nil,
        onOpenGardenIdentity: (() -> Void)? = nil,
        onOpenGardenLogs: (() -> Void)? = nil,
        onOpenAssessmentSubmission: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: ResultOverviewViewModel())
        self.gardenBoundaryCoordinates = gardenBoundaryCoordinates
        self.onBack = onBack
        self.onOpenFertilizerSchedule = onOpenFertilizerSchedule
        self.fertilizerScheduleTransitionNamespace = fertilizerScheduleTransitionNamespace
        self.onOpenNutrientCondition = onOpenNutrientCondition
        self.onOpenFarmGreenness = onOpenFarmGreenness
        self.onOpenFertilizerEstimation = onOpenFertilizerEstimation
        self.onOpenGardenIdentity = onOpenGardenIdentity
        self.onOpenGardenLogs = onOpenGardenLogs
        self.onOpenAssessmentSubmission = onOpenAssessmentSubmission
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let overview = viewModel.overview {
                    // 1. Map Hero Header
                    ResultOverviewMapHeaderView(
                        gardenName: overview.gardenName,
                        locationName: overview.locationName,
                        heroImageName: overview.heroImageName,
                        gardenBoundaryCoordinates: gardenBoundaryCoordinates,
                        onBack: handleBack
                    )

                    // 2. Hub Content Cards (Overlapping bottom gradient of the map, gap: 12 matching Sketch)
                    VStack(spacing: 12) {
                        // Card 1: Rekomendasi Pemupukan
                        recommendationCard(overview: overview)

                        // Card 2: Kondisi Hara
                        NutrientConditionSummaryCardView(
                            title: "Kondisi Hara",
                            statusBadgeText: overview.nutrientStatusTitle,
                            summaryText: overview.nutrientStatusSummary,
                            nutrients: overview.nutrients,
                            onTap: onOpenNutrientCondition
                        )

                        // Card 3: Hasil Pemantauan Drone
                        FarmGreennessSummaryCardView(
                            title: "Hasil Pemantauan Drone",
                            greenness: overview.greenness,
                            onTap: onOpenFarmGreenness
                        )

                        // Card 4: Perkiraan Biaya Pupuk
                        FertilizerEstimationSummaryCardView(
                            title: "Perkiraan Biaya Pupuk",
                            estimation: overview.fertilizerEstimation,
                            onTap: onOpenFertilizerEstimation
                        )

                        // Section 5: Data Kebun
                        GardenDataSummarySectionView(
                            rows: overview.gardenDataRows,
                            onTapRow: handleTapGardenDataRow
                        )
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, -52)
                    .padding(.bottom, 32)
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)

                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Coba Lagi") {
                            Task { await viewModel.load() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(KropsTheme.surfaceInverse)
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, minHeight: 300)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea(edges: .top)
        .background(KropsTheme.surfaceBackground.ignoresSafeArea())
        .task {
            if viewModel.overview == nil {
                await viewModel.load()
            }
        }
        .onAppear {
            if viewModel.overview != nil {
                Task { await viewModel.refresh() }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Actions

    @ViewBuilder
    private func recommendationCard(overview: ResultOverviewItem) -> some View {
        let card = FertilizerRecommendationCardView(
            title: overview.recommendationTitle,
            subtitle: overview.recommendationSubtitle,
            periods: overview.periods,
            onTap: onOpenFertilizerSchedule
        )

        if let fertilizerScheduleTransitionNamespace {
            card.matchedTransitionSource(id: viewModel.gardenId, in: fertilizerScheduleTransitionNamespace)
        } else {
            card
        }
    }

    private func handleBack() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    private func handleTapGardenDataRow(_ item: GardenDataSummaryRowItem) {
        switch item.id {
        case "identity":
            onOpenGardenIdentity?()
        case "logs":
            onOpenGardenLogs?()
        case "request":
            onOpenAssessmentSubmission?()
        default:
            break
        }
    }
}

// MARK: - Color Hex Helper


// MARK: - Previews

#Preview("Ringkasan Hasil · Default") {
    ResultOverviewView()
}

#Preview("Ringkasan Hasil · Dark Mode") {
    ResultOverviewView()
        .preferredColorScheme(.dark)
}

