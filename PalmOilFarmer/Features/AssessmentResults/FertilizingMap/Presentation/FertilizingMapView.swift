import SwiftUI

/// Main screen displaying the Fertilizing Map (Peta Dosis Pupuk).
/// Supports Per Zona, Per Pohon, and Seluruh Kebun across in-period and out-of-period states.
public typealias FertilizerMapView = FertilizingMapView

@MainActor
public struct FertilizingMapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FertilizingMapViewModel
    @State private var showsSpreader = false
    @State private var spreaderError: String?
    private var spreaderGarden: Garden?

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
        repository: any FertilizingMapRepositoryProtocol = DummyFertilizingMapRepository(),
        initialFertilizerName: String? = nil,
        isInPeriod: Bool = true,
        initialAreaDivision: AreaDivisionMode = .perZona,
        onBack: (() -> Void)? = nil
    ) {
        _viewModel = State(
            initialValue: FertilizingMapViewModel(
                repository: repository,
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
        repository: any FertilizingMapRepositoryProtocol = DummyFertilizingMapRepository(),
        initialFertilizerName: String? = nil,
        isInPeriod: Bool = true,
        initialAreaDivision: AreaDivisionMode = .perZona,
        onBack: (() -> Void)? = nil
    ) {
        self.init(
            gardenId: gardenId.uuidString,
            repository: repository,
            initialFertilizerName: initialFertilizerName,
            isInPeriod: isInPeriod,
            initialAreaDivision: initialAreaDivision,
            onBack: onBack
        )
    }

    public init(
        gardenID: UUID,
        repository: any FertilizingMapRepositoryProtocol = DummyFertilizingMapRepository(),
        initialFertilizerName: String? = nil,
        isInPeriod: Bool = true,
        initialAreaDivision: AreaDivisionMode = .perZona,
        onBack: (() -> Void)? = nil
    ) {
        self.init(
            gardenId: gardenID.uuidString,
            repository: repository,
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
                    orthomosaic: item.orthomosaic,
                    hidesZoneLabels: true,
                    onSelectZone: { zone in
                        viewModel.selectZone(zone)
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
                if viewModel.activeModalSheet != .chooseFertilizer {
                    VStack(spacing: 12) {
                        if shouldShowDetailSheet && (viewModel.areaDivision != .perZona || viewModel.selectedZone != nil) {
                            FertilizingMapDetailSheetView(
                                mode: viewModel.areaDivision,
                                selectedFertilizer: item.selectedFertilizer,
                                isInPeriod: viewModel.isInPeriod,
                                totalZones: item.totalZoneCount,
                                totalDoseKg: item.totalDoseKg,
                                selectedZone: viewModel.selectedZone,
                                isMarkedDone: item.isMarkedDone,
                                onToggleDone: {
                                    Task { await viewModel.toggleMarkDone() }
                                }
                            )
                        }

                        if hasZoneSpecificDoses(item) {
                            Button {
                                if let map = item.orthomosaic, !map.zones.isEmpty,
                                   gardenForSpreader(item) != nil {
                                    showsSpreader = true
                                } else {
                                    spreaderError = "Peta zona kebun belum tersedia untuk mode pemupukan."
                                }
                            } label: {
                                Label("Mulai Pemupukan", systemImage: "leaf.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 70)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.white)
                            .background(Color(red: 0.08, green: 0.08, blue: 0.09), in: Capsule())
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                            .accessibilityHint("Buka mode pemupukan untuk pupuk yang dipilih")
                        }
                    }
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
        .fullScreenCover(isPresented: $showsSpreader) {
            if let item = viewModel.item, let garden = gardenForSpreader(item) {
                SpreaderModeView(garden: garden, fertilizingMap: item)
            }
        }
        .alert("Mode Pemupukan", isPresented: Binding(
            get: { spreaderError != nil },
            set: { if !$0 { spreaderError = nil } }
        )) {
            Button("OK", role: .cancel) { spreaderError = nil }
        } message: {
            Text(spreaderError ?? "")
        }
        .sheet(item: $viewModel.activeModalSheet) { sheet in
            switch sheet {
            case .chooseFertilizer:
                if let item = viewModel.item {
                    ChooseFertilizerSheetView(
                        selectedFertilizer: item.selectedFertilizer,
                        availableFertilizers: item.availableFertilizers,
                        pendingFertilizerID: viewModel.pendingFertilizerID,
                        errorMessage: viewModel.fertilizerSelectionError,
                        onSelect: { selected in
                            Task { await viewModel.selectFertilizer(selected) }
                        },
                        onClose: viewModel.closeActiveSheet
                    )
                    .environment(\.colorScheme, .light)
                    .presentationDetents([.height(fertilizerSheetHeight(for: item.availableFertilizers.count))])
                    .presentationContentInteraction(.scrolls)
                    .presentationDragIndicator(.hidden)
                    .presentationBackground(.thickMaterial)
                    .presentationCornerRadius(38)
                    .presentationBackgroundInteraction(.enabled)
                    .interactiveDismissDisabled(viewModel.pendingFertilizerID != nil)
                }

            case .chooseAreaDivision:
                AreaDivisionSheetView(
                    selectedMode: viewModel.areaDivision,
                    onSelect: { mode in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.selectAreaDivision(mode)
                        }
                    },
                    onClose: viewModel.closeActiveSheet
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

    private func fertilizerSheetHeight(for itemCount: Int) -> CGFloat {
        min(CGFloat(100 + max(itemCount, 1) * 55), 650)
    }

    private func hasZoneSpecificDoses(_ item: FertilizingMapItem) -> Bool {
        item.selectedFertilizer.defaultDivision == .perZona
            && item.zones.filter { $0.doseKg > 0 }.count > 1
    }

    private func gardenForSpreader(_ item: FertilizingMapItem) -> Garden? {
        if let spreaderGarden { return spreaderGarden }
        guard let map = item.orthomosaic, map.farmBoundary.count >= 3 else { return nil }
        let boundary = GardenBoundary(points: map.farmBoundary.map {
            GardenCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        })
        // The spreader uses this temporary garden only to frame the assessment map.
        return Garden(
            id: item.gardenUUID ?? UUID(),
            name: item.gardenName,
            locationName: "",
            boundary: boundary,
            plantingYear: Calendar.current.component(.year, from: .now),
            soilType: .other
        )
    }

    func withSpreaderGarden(_ garden: Garden?) -> Self {
        var view = self
        view.spreaderGarden = garden
        return view
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

