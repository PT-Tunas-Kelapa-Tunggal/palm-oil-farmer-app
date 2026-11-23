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
    /// The bottom sheet is a real sheet, open for as long as the page is shown.
    @State private var showsSheet = true
    /// Set by the back button: the sheet closes first, then the page leaves (see `finishLeaving`).
    @State private var isLeaving = false

    /// Current sheet height. Kept apart from the content state so a content change only moves the
    /// sheet to a new height (an animated resize) instead of swapping its set of heights.
    @State private var detent: PresentationDetent

    /// Sheet heights: summary, detail / area picker, legend.
    private static let collapsedDetent = PresentationDetent.height(90)
    private static let detailDetent = PresentationDetent.fraction(0.3)
    private static let legendDetent = PresentationDetent.medium

    /// The height each content opens at.
    private static func detent(for state: FarmGreenIndexSheetState) -> PresentationDetent {
        state == .collapsed ? collapsedDetent : expandedDetent(for: state)
    }

    /// The open height a drag can reach from this content (from the summary, dragging up opens the legend).
    private static func expandedDetent(for state: FarmGreenIndexSheetState) -> PresentationDetent {
        switch state {
        case .collapsed, .legend: legendDetent
        case .detail, .areaPicker: detailDetent
        }
    }

    public var onBack: (() -> Void)?

    public init(
        viewModel: FarmGreenIndexViewModel,
        onBack: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        _detent = State(initialValue: Self.detent(for: viewModel.sheetState))
        self.onBack = onBack
    }

    public init(onBack: (() -> Void)? = nil) {
        _viewModel = State(initialValue: FarmGreenIndexViewModel())
        _detent = State(initialValue: Self.collapsedDetent)
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
                    pins: item.pins,
                    selectedPin: viewModel.selectedPin,
                    selectedCategory: visibleCategory,
                    showsZones: viewModel.selectedAreaDivision == .perZona,
                    onSelectPin: { pin in
                        animateSheet {
                            viewModel.selectPin(pin)
                        }
                    },
                    onRecenter: {
                        animateSheet {
                            viewModel.deselectPin()
                        }
                    },
                    onTapBackground: {
                        animateSheet {
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
                        animateSheet {
                            viewModel.toggleSheet()
                        }
                    },
                    onOpenAreaPicker: {
                        animateSheet {
                            viewModel.openAreaPicker()
                        }
                    }
                )
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
                        .tint(KropsTheme.surfaceInverse)
                    }
                    .padding(32)
                }
            }
        }
        // 3. Bottom sheet: a native sheet resting at the summary height or the height of its content,
        // with the map and header still usable behind it.
        .sheet(isPresented: sheetPresented, onDismiss: finishLeaving) {
            if let item = viewModel.item {
                DetentSheet(detents: sheetDetents, selection: detentSelection,
                            backgroundInteractiveUpThrough: Self.legendDetent) {
                    sheetContent(item)
                }
            }
        }
        // Safety net for content changes made outside `animateSheet` (e.g. previews).
        .onChange(of: viewModel.sheetState) { _, state in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                detent = Self.detent(for: state)
            }
        }
        .task {
            if viewModel.item == nil {
                await viewModel.load()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var visibleCategory: TreeConditionCategory? {
        guard viewModel.selectedAreaDivision == .perPohon,
              case .detail(let category) = viewModel.sheetState else { return nil }
        return category
    }

    // MARK: - Bottom Sheet

    private var sheetPresented: Binding<Bool> {
        Binding(get: { showsSheet && viewModel.item != nil }, set: { showsSheet = $0 })
    }

    /// Heights a drag can stop at: the summary and the current content's height, so dragging down from the
    /// legend goes straight to the summary. The height the sheet is at stays in the set while it animates
    /// to a new one; removing it mid-way would make the sheet jump instead of resize.
    private var sheetDetents: Set<PresentationDetent> {
        [Self.collapsedDetent, Self.expandedDetent(for: viewModel.sheetState), detent]
    }

    /// The farmer dragged the sheet: keep the new height, and change the content where the height asks for it.
    private var detentSelection: Binding<PresentationDetent> {
        Binding(
            get: { detent },
            set: { detent in
                self.detent = detent
                animateSheet {
                    if detent == Self.collapsedDetent {
                        // Dragged down: the area picker returns to where it came from, the rest collapse.
                        if viewModel.sheetState == .areaPicker {
                            viewModel.closeAreaPicker()
                        } else {
                            viewModel.collapseSheet()
                        }
                    } else if viewModel.sheetState == .collapsed {
                        // Dragged up from the summary.
                        viewModel.showLegend()
                    }
                }
            }
        )
    }

    @ViewBuilder
    private func sheetContent(_ item: FarmGreenIndexItem) -> some View {
        switch viewModel.sheetState {
        case .collapsed:
            FarmGreenIndexCollapsedPillView(
                subtitle: "\(item.treesToPayAttentionCount) dari \(item.totalTrees) pohon perlu diperhatikan",
                onExpand: {
                    animateSheet {
                        viewModel.showLegend()
                    }
                }
            )
            .transition(.opacity)

        case .legend:
            ScrollView {
                FarmGreenIndexLegendSheetView(
                    categories: item.categories,
                    onSelectCategory: { category in
                        animateSheet {
                            viewModel.selectCategory(category)
                        }
                    },
                    onCollapse: {
                        animateSheet {
                            viewModel.collapseSheet()
                        }
                    }
                )
            }
            .scrollBounceBehavior(.basedOnSize)
            .transition(.opacity)

        case .detail(let category):
            if let summary = item.categories.first(where: { $0.category == category }) {
                ScrollView {
                    FarmGreenIndexDetailSheetView(
                        summary: summary,
                        onBack: {
                            animateSheet {
                                viewModel.showLegend()
                            }
                        },
                        onCollapse: {
                            animateSheet {
                                viewModel.collapseSheet()
                            }
                        }
                    )
                }
                .scrollBounceBehavior(.basedOnSize)
                .transition(.opacity)
            }

        case .areaPicker:
            ScrollView {
                FarmGreenIndexAreaPickerSheetView(
                    selectedMode: viewModel.selectedAreaDivision,
                    onSelectMode: { mode in
                        animateSheet {
                            viewModel.selectAreaDivision(mode)
                        }
                    },
                    onClose: {
                        animateSheet {
                            viewModel.closeAreaPicker()
                        }
                    }
                )
            }
            .scrollBounceBehavior(.basedOnSize)
            .transition(.opacity)
        }
    }

    // MARK: - Actions

    /// Changes the sheet content and its height in the same animation, so the sheet resizes while the
    /// content changes instead of swapping the content first and resizing a moment later.
    private func animateSheet(_ change: () -> Void) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            change()
            detent = Self.detent(for: viewModel.sheetState)
        }
    }

    /// The sheet sits above the navigation stack, so it closes before the page leaves.
    private func handleBack() {
        guard sheetPresented.wrappedValue else { return leave() }
        isLeaving = true
        showsSheet = false
    }

    private func finishLeaving() {
        guard isLeaving else { return }
        isLeaving = false
        leave()
    }

    private func leave() {
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

