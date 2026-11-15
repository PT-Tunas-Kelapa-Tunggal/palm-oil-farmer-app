import SwiftUI

/// Main screen displaying the Farm Green Index (Peta Kondisi Kebun) assessment scan.
/// Sliced from Sketch:
/// - "Hasil Peninjauan / Peta Kondisi Kebun / Collapsed"
/// - "Hasil Peninjauan / Peta Kondisi Kebun / Legend"
/// - "Hasil Peninjauan / Detail Kondisi / Normal"
/// - "Hasil Peninjauan / Detail Kondisi / Terindikasi"
/// - "Hasil Peninjauan / Detail Kondisi / Defisiensi"
/// - "Hasil Peninjauan / Detail Kondisi / Tidak Wajar"
@MainActor
public struct FarmGreenIndexView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FarmGreenIndexViewModel
    @State private var sheetDragOffsetY: CGFloat = 0

    public var onBack: (() -> Void)?

    public init(
        viewModel: FarmGreenIndexViewModel,
        onBack: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onBack = onBack
    }

    public init(onBack: (() -> Void)? = nil) {
        _viewModel = State(initialValue: FarmGreenIndexViewModel())
        self.onBack = onBack
    }

    public var body: some View {
        ZStack(alignment: .top) {
            if let item = viewModel.item {
                // 1. Fullscreen Map Canvas
                FarmGreenIndexMapView(
                    mapImageName: item.orthomosaic?.imageURL == nil && viewModel.selectedAreaDivision == .perZona
                        ? "FarmGreenIndexZoneMap" : item.mapImageName,
                    orthomosaic: item.orthomosaic,
                    pins: visiblePins(for: item),
                    selectedPin: viewModel.selectedPin,
                    showsZones: viewModel.selectedAreaDivision == .perZona,
                    onSelectPin: { pin in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.selectPin(pin)
                        }
                    },
                    onRecenter: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.deselectPin()
                        }
                    },
                    onTapBackground: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.collapseSheet()
                            viewModel.deselectPin()
                        }
                    }
                )

                // 2. Floating Top Navigation Bar
                FarmGreenIndexHeaderView(
                    gardenName: item.gardenName,
                    locationName: item.locationName,
                    onBack: handleBack,
                    onToggleLegend: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.toggleSheet()
                        }
                    },
                    onOpenAreaPicker: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.openAreaPicker()
                        }
                    }
                )

                // 3. Floating Bottom Sheet (Interactive & Swipable)
                VStack {
                    Spacer()
                    bottomSheetContent(item)
                        .offset(y: sheetDragOffsetY)
                        .simultaneousGesture(sheetDragGesture)
                }
                .ignoresSafeArea(edges: .bottom)
            } else if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                }
            } else if let error = viewModel.errorMessage {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.white)

                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)

                        Button("Coba Lagi") {
                            Task { await viewModel.load() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(red: 0.18, green: 0.42, blue: 0.25))
                    }
                    .padding(32)
                }
            }
        }
        .task {
            if viewModel.item == nil {
                await viewModel.load()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func visiblePins(for item: FarmGreenIndexItem) -> [TreePinItem] {
        guard viewModel.selectedAreaDivision == .perPohon else { return [] }
        if case .detail(let category) = viewModel.sheetState {
            return item.pins.filter { $0.category == category }
        }
        return []
    }

    // MARK: - Bottom Sheet Builder

    @ViewBuilder
    private func bottomSheetContent(_ item: FarmGreenIndexItem) -> some View {
        switch viewModel.sheetState {
        case .collapsed:
            FarmGreenIndexCollapsedPillView(
                subtitle: "\(item.treesToPayAttentionCount) dari \(item.totalTrees) pohon perlu diperhatikan",
                onExpand: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.showLegend()
                    }
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))

        case .legend:
            FarmGreenIndexLegendSheetView(
                categories: item.categories,
                onSelectCategory: { category in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.selectCategory(category)
                    }
                },
                onCollapse: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.collapseSheet()
                    }
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))

        case .detail(let category):
            if let summary = item.categories.first(where: { $0.category == category }) {
                FarmGreenIndexDetailSheetView(
                    summary: summary,
                    onBack: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.showLegend()
                        }
                    },
                    onCollapse: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.collapseSheet()
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

        case .areaPicker:
            FarmGreenIndexAreaPickerSheetView(
                selectedMode: viewModel.selectedAreaDivision,
                onSelectMode: { mode in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.selectAreaDivision(mode)
                    }
                },
                onClose: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        viewModel.closeAreaPicker()
                    }
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Swipe Gesture

    private var sheetDragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                let translation = value.translation.height
                switch viewModel.sheetState {
                case .collapsed:
                    // Swiping up from collapsed: allows dragging up (negative translation)
                    if translation < 0 {
                        sheetDragOffsetY = translation * 0.4
                    } else {
                        // Light elastic resistance downwards
                        sheetDragOffsetY = translation * 0.1
                    }

                case .legend, .detail, .areaPicker:
                    // Swiping down from expanded sheet: allows dragging down (positive translation)
                    if translation > 0 {
                        sheetDragOffsetY = translation * 0.5
                    } else {
                        // Light elastic resistance upwards
                        sheetDragOffsetY = translation * 0.1
                    }
                }
            }
            .onEnded { value in
                let translation = value.translation.height
                let velocity = value.predictedEndTranslation.height - translation

                switch viewModel.sheetState {
                case .collapsed:
                    // Swipe up condition: dragged up > 25pt or fast upward velocity -> expand
                    if translation < -25 || velocity < -100 {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                            sheetDragOffsetY = 0
                            viewModel.showLegend()
                        }
                    } else {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            sheetDragOffsetY = 0
                        }
                    }

                case .legend:
                    // Swipe down condition: dragged down > 25pt or fast downward velocity -> hide/collapse
                    if translation > 25 || velocity > 100 {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                            sheetDragOffsetY = 0
                            viewModel.collapseSheet()
                        }
                    } else {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            sheetDragOffsetY = 0
                        }
                    }

                case .detail:
                    // Swipe down condition: dragged down > 25pt or fast downward velocity -> hide/collapse
                    if translation > 25 || velocity > 100 {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                            sheetDragOffsetY = 0
                            viewModel.collapseSheet()
                        }
                    } else if value.translation.width > 50 {
                        // Horizontal swipe right -> back to legend
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                            sheetDragOffsetY = 0
                            viewModel.showLegend()
                        }
                    } else {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            sheetDragOffsetY = 0
                        }
                    }

                case .areaPicker:
                    // Swipe down condition: dragged down > 25pt or fast downward velocity -> close area picker
                    if translation > 25 || velocity > 100 {
                        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
                            sheetDragOffsetY = 0
                            viewModel.closeAreaPicker()
                        }
                    } else {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            sheetDragOffsetY = 0
                        }
                    }
                }
            }
    }

    // MARK: - Actions

    private func handleBack() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }
}

// MARK: - Previews

#Preview("Peta Kondisi Kebun · Pembagian Area") {
    let vm = FarmGreenIndexViewModel()
    vm.sheetState = .areaPicker
    vm.selectedAreaDivision = .perZona
    return FarmGreenIndexView(viewModel: vm)
}

#Preview("Peta Kondisi Kebun · Legend") {
    let vm = FarmGreenIndexViewModel()
    vm.sheetState = .legend
    return FarmGreenIndexView(viewModel: vm)
}

#Preview("Peta Kondisi Kebun · Collapsed") {
    let vm = FarmGreenIndexViewModel()
    vm.sheetState = .collapsed
    return FarmGreenIndexView(viewModel: vm)
}

#Preview("Detail Kondisi · Normal") {
    let vm = FarmGreenIndexViewModel()
    vm.sheetState = .detail(.normal)
    return FarmGreenIndexView(viewModel: vm)
}

#Preview("Detail Kondisi · Defisiensi") {
    let vm = FarmGreenIndexViewModel()
    vm.sheetState = .detail(.defisiensi)
    return FarmGreenIndexView(viewModel: vm)
}

