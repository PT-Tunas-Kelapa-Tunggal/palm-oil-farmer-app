import SwiftUI

/// Main screen displaying the Assessment Results Overview report (Ringkasan Hasil).
/// Sliced from Sketch: "Hasil Peninjauan / Ringkasan Hasil / Default"
@MainActor
public struct ResultOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ResultOverviewViewModel
    @State private var refreshPullDistance: CGFloat = 0
    @State private var isAtScrollTop = true

    private let mapHeaderHeight: CGFloat = 360

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
        ZStack(alignment: .top) {
            if let overview = viewModel.overview {
                ResultOverviewMapHeaderView(
                    gardenName: overview.gardenName,
                    locationName: overview.locationName,
                    heroImageName: overview.heroImageName,
                    farmBoundary: viewModel.farmBoundary,
                    height: mapHeaderHeight + refreshPullDistance,
                    showsNavigation: false
                )
                .frame(maxWidth: .infinity, alignment: .top)
            }

            ScrollView {
                VStack(spacing: 0) {
                    if let overview = viewModel.overview {
                        Color.clear.frame(height: mapHeaderHeight)

                        // Hub Content Cards (overlapping the map's bottom gradient)
                        VStack(spacing: 12) {
                            recommendationCard(overview: overview)

                            NutrientConditionSummaryCardView(
                                title: "Kondisi Hara",
                                statusBadgeText: overview.nutrientStatusTitle,
                                summaryText: overview.nutrientStatusSummary,
                                nutrients: overview.nutrients,
                                onTap: onOpenNutrientCondition
                            )

                            FarmGreennessSummaryCardView(
                                title: "Hasil Pemantauan Drone",
                                greenness: overview.greenness,
                                onTap: onOpenFarmGreenness
                            )

                            FertilizerEstimationSummaryCardView(
                                title: "Perkiraan Biaya Pupuk",
                                estimation: overview.fertilizerEstimation,
                                onTap: onOpenFertilizerEstimation
                            )

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
                            .tint(Color(red: 0.18, green: 0.42, blue: 0.25))
                        }
                        .padding(32)
                        .frame(maxWidth: .infinity, minHeight: 300)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color.clear)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, offset in
                refreshPullDistance = max(0, -offset)
                isAtScrollTop = offset < 48
            }
            .refreshable {
                await viewModel.refresh()
            }

            if isAtScrollTop, let overview = viewModel.overview {
                headerNavigation(for: overview)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(hex: 0xF2F4F7).ignoresSafeArea())
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
        .navigationBarBackButtonHidden()
        .navigationTitle(isAtScrollTop ? "" : (viewModel.overview?.gardenName ?? "Hasil Peninjauan"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !isAtScrollTop {
                    Button(action: handleBack) {
                        Image(systemName: "chevron.left")
                    }
                    .tint(.white)
                    .accessibilityLabel("Kembali")
                }
            }
        }
        .toolbarBackground(Color.black.opacity(0.78), for: .navigationBar)
        .toolbarBackground(isAtScrollTop ? .hidden : .visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func headerNavigation(for overview: ResultOverviewItem) -> some View {
        HStack {
            Button(action: handleBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kembali")

            Spacer()

            VStack(spacing: 2) {
                Text(overview.gardenName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text(overview.locationName)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.4), radius: 6, y: 2)

            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
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

private extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Previews

#Preview("Ringkasan Hasil · Default") {
    ResultOverviewView()
}

#Preview("Ringkasan Hasil · Dark Mode") {
    ResultOverviewView()
        .preferredColorScheme(.dark)
}

