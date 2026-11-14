import SwiftUI

/// Main screen displaying the Fertilizing Map (Peta Dosis Pupuk).
/// Supports Per Zona, Per Pohon, and Seluruh Kebun across in-period and out-of-period states.
public typealias FertilizerMapView = FertilizingMapView

@MainActor
public struct FertilizingMapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FertilizingMapViewModel

    public var onBack: (() -> Void)?

    public init(
        viewModel: FertilizingMapViewModel,
        onBack: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onBack = onBack
    }

    public init(
        gardenId: String = "garden-default",
        initialFertilizerName: String? = nil,
        isInPeriod: Bool = true,
        initialAreaDivision: AreaDivisionMode = .perZona,
        onBack: (() -> Void)? = nil
    ) {
        _viewModel = State(
            initialValue: FertilizingMapViewModel(
                gardenId: gardenId,
                initialFertilizerName: initialFertilizerName,
                isInPeriod: isInPeriod,
                initialAreaDivision: initialAreaDivision
            )
        )
        self.onBack = onBack
    }

    public init(
        gardenId: UUID,
        initialFertilizerName: String? = nil,
        isInPeriod: Bool = true,
        initialAreaDivision: AreaDivisionMode = .perZona,
        onBack: (() -> Void)? = nil
    ) {
        self.init(
            gardenId: gardenId.uuidString,
            initialFertilizerName: initialFertilizerName,
            isInPeriod: isInPeriod,
            initialAreaDivision: initialAreaDivision,
            onBack: onBack
        )
    }

    public init(
        gardenID: UUID,
        initialFertilizerName: String? = nil,
        isInPeriod: Bool = true,
        initialAreaDivision: AreaDivisionMode = .perZona,
        onBack: (() -> Void)? = nil
    ) {
        self.init(
            gardenId: gardenID.uuidString,
            initialFertilizerName: initialFertilizerName,
            isInPeriod: isInPeriod,
            initialAreaDivision: initialAreaDivision,
            onBack: onBack
        )
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            if let item = viewModel.item {
                // 1. Fullscreen Map Canvas
                FertilizingMapCanvasView(
                    mode: viewModel.areaDivision,
                    zones: item.zones,
                    selectedFertilizerName: item.selectedFertilizer.name,
                    selectedFertilizerTotalDose: item.selectedFertilizer.totalDose,
                    selectedZone: viewModel.selectedZone,
                    userLocation: viewModel.userLocation,
                    orthomosaic: item.orthomosaic,
                    onSelectZone: { zone in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.selectZone(zone)
                        }
                    }
                )
                .ignoresSafeArea()

                // 2. Floating Top Header
                VStack(spacing: 0) {
                    FertilizingMapHeaderView(
                        fertilizerName: item.selectedFertilizer.name,
                        onTapFertilizer: {
                            viewModel.openFertilizerSelector()
                        },
                        onTapAreaDivision: {
                            viewModel.openAreaDivisionSelector()
                        },
                        onBack: {
                            if let onBack {
                                onBack()
                            } else {
                                dismiss()
                            }
                        }
                    )
                    Spacer()
                }

                // 3. Bottom Detail Panel
                if shouldShowDetailSheet {
                    FertilizingMapDetailSheetView(
                        mode: viewModel.areaDivision,
                        selectedFertilizer: item.selectedFertilizer,
                        isInPeriod: viewModel.isInPeriod,
                        totalZones: item.totalZoneCount,
                        totalDoseKg: item.totalDoseKg,
                        selectedZone: viewModel.selectedZone,
                        isMarkedDone: item.isMarkedDone,
                        onToggleDone: {
                            Task {
                                await viewModel.toggleMarkDone()
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text(error)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Button("Coba Lagi") {
                        Task { await viewModel.load() }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .glassEffect(.regular.interactive(), in: Capsule())
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await viewModel.load()
        }
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .sheet(item: $viewModel.activeModalSheet) { sheet in
            switch sheet {
            case .chooseFertilizer:
                if let item = viewModel.item {
                    ChooseFertilizerSheetView(
                        selectedFertilizer: item.selectedFertilizer,
                        availableFertilizers: item.availableFertilizers,
                        onSelect: { selected in
                            Task { await viewModel.selectFertilizer(selected) }
                        },
                        onClose: {
                            viewModel.closeActiveSheet()
                        }
                    )
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.hidden)
                }

            case .chooseAreaDivision:
                AreaDivisionSheetView(
                    selectedMode: viewModel.areaDivision,
                    onSelect: { mode in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.selectAreaDivision(mode)
                        }
                    },
                    onClose: {
                        viewModel.closeActiveSheet()
                    }
                )
                .presentationDetents([.height(290)])
                .presentationDragIndicator(.hidden)
            }
        }
    }

    private var shouldShowDetailSheet: Bool {
        // Shown if in active period, or if in Per Pohon/Whole Farm, or if a zone is selected
        if viewModel.isInPeriod { return true }
        if viewModel.areaDivision == .perPohon || viewModel.areaDivision == .wholeFarm { return true }
        return viewModel.selectedZone != nil
    }
}

#if DEBUG
#Preview("Per Zona · In Period") {
    FertilizingMapView(
        gardenId: "preview-garden",
        initialFertilizerName: "Dolomit",
        isInPeriod: true,
        initialAreaDivision: .perZona
    )
}

#Preview("Per Zona · Out of Period") {
    FertilizingMapView(
        gardenId: "preview-garden",
        initialFertilizerName: "Dolomit",
        isInPeriod: false,
        initialAreaDivision: .perZona
    )
}

#Preview("Per Pohon · In Period") {
    FertilizingMapView(
        gardenId: "preview-garden",
        initialFertilizerName: "Dolomit",
        isInPeriod: true,
        initialAreaDivision: .perPohon
    )
}

#Preview("Seluruh Kebun · NPK") {
    FertilizingMapView(
        gardenId: "preview-garden",
        initialFertilizerName: "NPK 15-15-15",
        isInPeriod: true,
        initialAreaDivision: .wholeFarm
    )
}
#endif

