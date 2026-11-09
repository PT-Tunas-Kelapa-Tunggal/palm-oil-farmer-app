import SwiftUI
import MapKit

struct GardenBoundaryView: View {
    @State private var flow: GardenMappingFlow
    private var location: GardenLocation { flow.viewModel.location }
    private var boundary: GardenBoundary { flow.viewModel.boundary }
    private enum Stage { case location, guide, drawing }
    @State private var showsMapSheet = false
    @State private var mapSheetHeight: CGFloat = 0
    @State private var guide = BoundaryDrawingGuideState()
    @State private var stage: Stage
    @State private var showsSearchConfirmation = false
    @State private var showsDraftSaveError = false
    @State private var showsSavedConfirmation = false
    private var isDrawing: Bool { stage == .drawing }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition
    @State private var latestCamera: MapCamera?
    /// Finger position minus the dragged marker's tip, so a point does not jump under the finger.
    /// Drags use the global space: annotation views are hosted apart from the map's own hierarchy.
    @State private var dragOffset: CGSize?
    @State private var draggingIndex: Int?
    @State private var ignoresMapTapsUntil = ContinuousClock.now
    @GestureState private var isDraggingPoint = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private static let markerHitSize: CGFloat = 44

    init(flow: GardenMappingFlow) {
        _flow = State(initialValue: flow)
        _stage = State(initialValue: flow.viewModel.location.source == .draft ? .drawing : .location)
        let location = flow.viewModel.location
        let region = MKCoordinateRegion(
            center: location.coordinate.mapCoordinate,
            latitudinalMeters: 400,
            longitudinalMeters: 400
        )
        // A resumed draft is mapped on site, so the camera follows the farmer.
        _position = State(initialValue: (location.source == .draft || location.source == .currentLocation)
            ? .userLocation(fallback: .region(region))
            : .region(region))
    }

    var body: some View {
        @Bindable var coordinator = flow.coordinator
        Group {
            if stage == .guide {
                BoundaryDrawingGuideDemo(
                    step: guide.step,
                    center: latestCamera?.centerCoordinate ?? location.coordinate.mapCoordinate,
                    longitudeDelta: 0.004,
                    isPlaying: showsMapSheet,
                    bottomSheetHeight: mapSheetHeight
                )
                .ignoresSafeArea()
            } else {
                mappingContent
            }
        }
        .overlay(alignment: .topLeading) {
            if stage != .drawing {
                HStack {
                    RegistrationIconButton(symbol: "chevron.left", label: "Kembali") {
                        goBack()
                    }
                    Spacer()
                    if stage == .location && location.source == .currentLocation {
                        RegistrationIconButton(symbol: "location.fill", label: "Lokasi saya") {
                            position = .userLocation(fallback: .automatic)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            flow.viewModel.requestLocationAuthorization()
            if coordinator.outcome == nil { showsMapSheet = true }
        }
        .onChange(of: isDraggingPoint) { _, isDragging in
            if !isDragging {
                dragOffset = nil
                draggingIndex = nil
            }
        }
        .sheet(isPresented: $showsMapSheet, onDismiss: mapSheetDidDismiss) {
            mapSheetContent
        }
        .onChange(of: coordinator.outcome) { _, outcome in
            if outcome != nil { showsMapSheet = false }
        }
        .fullScreenCover(isPresented: $showsSavedConfirmation, onDismiss: { dismiss() }) {
            GardenSavedConfirmationView(
                gardenName: coordinator.savedGardenName ?? location.name,
                area: GardenDisplayMetrics(boundary: boundary).area,
                onContinue: { showsSavedConfirmation = false }
            )
        }
    }

    private var mapSheetContent: some View {
        @Bindable var coordinator = flow.coordinator
        return Group {
            if stage == .guide {
                BoundaryDrawingGuideSheet(step: guide.step, onContinue: advanceGuide)
            } else {
                DynamicSheet(animation: .bouncy, size: .xsmall) {
                    if stage == .location {
                        LocationConfirmationPanel(
                            location: location,
                            onBack: goBack,
                            onContinue: {
                                flow.viewModel.confirmPhoto()
                                if let latestCamera { position = .camera(latestCamera) }
                                guide = BoundaryDrawingGuideState()
                                stage = .guide
                            }
                        )
                    } else {
                        BoundaryEditingPanel(
                            boundary: boundary,
                            showsMetrics: verticalSizeClass == .compact && dynamicTypeSize.isAccessibilitySize,
                            isClosed: flow.viewModel.isClosed,
                            onUndo: flow.viewModel.undo, onClear: flow.viewModel.clear,
                            onConfirm: flow.viewModel.confirmBoundary
                        )
                    }
                }
            }
        }
        .presentationBackgroundInteraction(.enabled)
        .presentationDragIndicator(.hidden)
        .presentationCompactAdaptation(.sheet)
        .preferredColorScheme(.light)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { mapSheetHeight = $0 }
        .sheet(isPresented: $coordinator.showsDetails, onDismiss: coordinator.detailsDidDismiss) {
            GardenDetailsView(flow: flow.makeDetailsFlow())
        }
        .confirmationDialog("Cari lokasi lain?", isPresented: $showsSearchConfirmation, titleVisibility: .visible) {
            Button("Hapus batas dan cari lokasi lain", role: .destructive) {
                flow.viewModel.clear()
                flow.viewModel.searchAgain()
            }
            Button("Lanjutkan pemetaan", role: .cancel) {}
        } message: {
            Text("Batas yang belum disimpan akan dihapus.")
        }
        .alert("Lokasi belum tersimpan", isPresented: $showsDraftSaveError) {
            Button("Mengerti", role: .cancel) {}
        } message: {
            Text("Lokasi tidak dapat disimpan di perangkat. Coba lagi.")
        }
        .confirmationDialog("Keluar dari pemetaan?", isPresented: $coordinator.showsExitConfirmation, titleVisibility: .visible) {
            Button("Keluar tanpa menyimpan", role: .destructive, action: coordinator.discardAndClose)
            Button("Lanjutkan pemetaan", role: .cancel, action: coordinator.continueMapping)
        } message: {
            Text("Batas yang belum disimpan perlu dipetakan ulang saat kamu kembali.")
        }
    }

    private func advanceGuide() {
        withAnimation(reduceMotion ? nil : .bouncy) {
            if !guide.advance() { stage = .drawing }
        }
    }

    private func goBack() {
        if stage == .guide {
            withAnimation(reduceMotion ? nil : .bouncy) {
                if !guide.goBack() { stage = .location }
            }
        } else {
            flow.viewModel.searchAgain()
        }
    }

    private func mapSheetDidDismiss() {
        if flow.coordinator.outcome == .savedGarden {
            showsSavedConfirmation = true
        } else if flow.coordinator.outcome != nil {
            dismiss()
        }
    }

    private var mappingContent: some View {
        MapReader { proxy in
            BoundaryEditorLayout(
                boundary: boundary,
                isClosed: flow.viewModel.isClosed,
                showsControls: isDrawing,
                showsBottomPanel: false,
                bottomSheetHeight: showsMapSheet ? mapSheetHeight : 0,
                onClose: flow.viewModel.close,
                onSearch: searchAgain,
                onUndo: flow.viewModel.undo,
                onClear: flow.viewModel.clear,
                onConfirm: flow.viewModel.confirmBoundary
            ) {
                Map(position: $position) {
                    mapContent(proxy)
                }
                .mapStyle(.imagery)
                .mapControls {}
                .onMapCameraChange { context in latestCamera = context.camera }
                .simultaneousGesture(DragGesture(minimumDistance: 8).onChanged { _ in
                    ignoresMapTapsUntil = .now.advanced(by: .milliseconds(250))
                }.onEnded { _ in
                    ignoresMapTapsUntil = .now.advanced(by: .milliseconds(250))
                })
                .simultaneousGesture(SpatialTapGesture(coordinateSpace: .global).onEnded { tap in
                    Task { @MainActor in
                        // Let annotation gesture callbacks settle before interpreting the map tap.
                        try? await Task.sleep(for: .milliseconds(60))
                        guard isDrawing, flow.coordinator.canEditBoundary,
                              ContinuousClock.now >= ignoresMapTapsUntil,
                              draggingIndex == nil, !isOnMarker(tap.location, proxy: proxy),
                              let coordinate = proxy.convert(tap.location, from: .global) else { return }
                        flow.viewModel.addPoint(GardenCoordinate(coordinate))
                    }
                })
            }
        }
    }

    @MapContentBuilder
    private func mapContent(_ proxy: MapProxy) -> some MapContent {
        BoundaryGeometryMapContent(
            coordinates: boundary.coordinates,
            isClosed: flow.viewModel.isClosed
        )
        ForEach(boundary.points.indices, id: \.self) { index in
            Annotation("", coordinate: boundary.points[index].mapCoordinate, anchor: .center) {
                RegistrationBoundaryMarker(
                    number: index + 1,
                    isActive: index == (draggingIndex ?? boundary.points.indices.last)
                )
                .scaleEffect(!reduceMotion && draggingIndex == index ? 1.15 : 1)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: draggingIndex == index)
                .frame(width: Self.markerHitSize, height: Self.markerHitSize)
                .contentShape(Circle())
                .highPriorityGesture(moveGesture(for: index, proxy: proxy))
                .accessibilityIdentifier("boundaryPoint\(index + 1)")
                .accessibilityHint("Geser untuk memindahkan titik")
            }
        }
        // Two points form one segment; a polygon also includes its closing edge.
        let edgeCount = flow.viewModel.isClosed ? boundary.points.count : max(0, boundary.points.count - 1)
        ForEach(0..<edgeCount, id: \.self) { index in
            let first = boundary.points[index].mapCoordinate
            let second = boundary.points[(index + 1) % boundary.points.count].mapCoordinate
            Annotation("", coordinate: midpoint(first, second)) {
                Text(distance(first, second))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.black.opacity(0.7), in: Capsule())
            }
        }
        if stage == .location && location.source == .photo {
            Annotation("", coordinate: location.coordinate.mapCoordinate, anchor: .bottom) {
                PhotoLocationMarker(image: location.photoPreviewData.flatMap { UIImage(data: $0) })
            }
        } else if stage == .location && location.source == .search {
            Annotation("", coordinate: location.coordinate.mapCoordinate) {
                RegistrationSelectedLocationMarker(name: location.name)
            }
        }
        if location.source == .currentLocation || location.source == .draft {
            UserAnnotation { RegistrationUserLocationMarker() }
        }
    }

    private func moveGesture(for index: Int, proxy: MapProxy) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .updating($isDraggingPoint) { _, isDragging, _ in isDragging = true }
            .onChanged { drag in
                guard isDrawing, boundary.points.indices.contains(index) else { return }
                ignoresMapTapsUntil = .now.advanced(by: .milliseconds(250))
                draggingIndex = index
                if dragOffset == nil,
                   let tip = proxy.convert(boundary.points[index].mapCoordinate, to: .global) {
                    dragOffset = CGSize(width: drag.startLocation.x - tip.x, height: drag.startLocation.y - tip.y)
                }
                let offset = dragOffset ?? .zero
                let tip = CGPoint(x: drag.location.x - offset.width, y: drag.location.y - offset.height)
                guard let coordinate = proxy.convert(tip, from: .global) else { return }
                flow.viewModel.movePoint(at: index, to: GardenCoordinate(coordinate))
            }
            .onEnded { _ in
                ignoresMapTapsUntil = .now.advanced(by: .milliseconds(250))
            }
    }

    /// Markers sit above their point; a tap on one must not also add a new point.
    private func isOnMarker(_ location: CGPoint, proxy: MapProxy) -> Bool {
        boundary.points.contains { point in
            guard let tip = proxy.convert(point.mapCoordinate, to: .global) else { return false }
            return hypot(location.x - tip.x, location.y - tip.y) < Self.markerHitSize / 2
        }
    }

    private var saveDraftAction: (() -> Void)? {
        guard flow.viewModel.canSaveLocationDraft else { return nil }
        return { saveDraft() }
    }

    private func saveDraft() {
        showsDraftSaveError = !flow.viewModel.saveDraft()
    }

    private func searchAgain() {
        if boundary.points.isEmpty {
            flow.viewModel.searchAgain()
        } else {
            showsSearchConfirmation = true
        }
    }

    private func midpoint(_ first: CLLocationCoordinate2D, _ second: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: (first.latitude + second.latitude) / 2,
                               longitude: (first.longitude + second.longitude) / 2)
    }

    private func distance(_ first: CLLocationCoordinate2D, _ second: CLLocationCoordinate2D) -> String {
        let distance = CLLocation(latitude: first.latitude, longitude: first.longitude)
            .distance(from: CLLocation(latitude: second.latitude, longitude: second.longitude))
        return distance.formatted(.number.precision(.fractionLength(0))) + " m"
    }
}

#if DEBUG
#Preview("11 · Peta dari Pencarian") {
    GardenBoundaryView(location: GardenPreviewData.location, onSave: { _ in true }, onSaveDraft: { _ in true })
}
#Preview("11 · Konfirmasi Lokasi Foto") {
    GardenBoundaryView(location: GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun",
                                                coordinate: GardenPreviewData.location.coordinate, source: .photo),
                       onSave: { _ in true })
}
#endif
