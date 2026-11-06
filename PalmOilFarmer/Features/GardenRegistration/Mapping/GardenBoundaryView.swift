import SwiftUI
import MapKit

struct GardenBoundaryView: View {
    @State private var flow: GardenMappingFlow
    private var location: GardenLocation { flow.viewModel.location }
    private var boundary: GardenBoundary { flow.viewModel.boundary }
    private enum Stage { case location, guide, drawing }
    @State private var stage: Stage
    @State private var showsSearchConfirmation = false
    @State private var showsDraftSaveError = false
    private var isDrawing: Bool { stage == .drawing }

    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition
    /// Finger position minus the dragged marker's tip, so a point does not jump under the finger.
    /// Drags use the global space: annotation views are hosted apart from the map's own hierarchy.
    @State private var dragOffset: CGSize?
    @State private var draggingIndex: Int?

    init(flow: GardenMappingFlow) {
        _flow = State(initialValue: flow)
        _stage = State(initialValue: flow.viewModel.location.source == .draft ? .drawing : .location)
        let location = flow.viewModel.location
        let region = MKCoordinateRegion(
            center: location.coordinate.mapCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        )
        // A resumed draft is mapped on site, so the camera follows the farmer.
        _position = State(initialValue: (location.source == .draft || location.source == .currentLocation)
            ? .userLocation(fallback: .region(region))
            : .region(region))
    }

    var body: some View {
        @Bindable var coordinator = flow.coordinator
        MapReader { proxy in
            BoundaryEditorLayout(
                boundary: boundary,
                showsControls: isDrawing,
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
                .simultaneousGesture(SpatialTapGesture().onEnded { tap in
                    guard isDrawing, !isOnMarker(tap.location, proxy: proxy),
                          let coordinate = proxy.convert(tap.location, from: .local) else { return }
                    flow.viewModel.addPoint(GardenCoordinate(coordinate))
                })
            }
        }
        .overlay(alignment: .bottom) {
            if stage == .location {
                LocationConfirmationPanel(
                    location: location,
                    onSaveDraft: saveDraftAction,
                    onBack: flow.viewModel.searchAgain
                ) {
                    flow.viewModel.confirmPhoto()
                    stage = .guide
                }

            } else if stage == .guide {
                BoundaryDrawingGuidePanel { stage = .drawing }

            }
        }
        .overlay {
            if stage == .guide { BoundaryDrawingGuideOverlay() }
        }
        .overlay(alignment: .topLeading) {
            if stage == .location && location.source == .photo {
                RegistrationIconButton(symbol: "xmark", label: "Tutup", action: flow.viewModel.close)
                    .padding(12)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
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
        .onAppear { flow.viewModel.requestLocationAuthorization() }
        .sheet(isPresented: $coordinator.showsDetails, onDismiss: coordinator.detailsDidDismiss) {
            GardenDetailsView(flow: flow.makeDetailsFlow())
        }
        .onChange(of: coordinator.outcome) { _, outcome in
            if outcome != nil { dismiss() }
        }
        .confirmationDialog("Keluar dari pemetaan?", isPresented: $coordinator.showsExitConfirmation, titleVisibility: .visible) {
            Button("Keluar tanpa menyimpan", role: .destructive, action: coordinator.discardAndClose)
            Button("Lanjutkan pemetaan", role: .cancel, action: coordinator.continueMapping)
        } message: {
            Text("Batas yang belum disimpan perlu dipetakan ulang saat kamu kembali.")
        }
    }

    @MapContentBuilder
    private func mapContent(_ proxy: MapProxy) -> some MapContent {
        if boundary.points.count >= 3 {
            MapPolygon(coordinates: boundary.coordinates)
                .foregroundStyle(.white.opacity(0.25))
                .stroke(.white, lineWidth: 2)
        } else if boundary.points.count == 2 {
            MapPolyline(coordinates: boundary.coordinates).stroke(.white, lineWidth: 2)
        }
        ForEach(boundary.points.indices, id: \.self) { index in
            Annotation("", coordinate: boundary.points[index].mapCoordinate, anchor: .bottom) {
                RegistrationBoundaryMarker(number: index + 1)
                    .scaleEffect(draggingIndex == index ? 1.2 : 1)
                    .highPriorityGesture(moveGesture(for: index, proxy: proxy))
                    .accessibilityHint("Geser untuk memindahkan titik")
            }
        }
        // Two points form one segment; a polygon also includes its closing edge.
        let edgeCount = boundary.points.count == 2 ? 1 : (boundary.points.count > 2 ? boundary.points.count : 0)
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
        DragGesture(minimumDistance: 4, coordinateSpace: .global)
            .onChanged { drag in
                guard boundary.points.indices.contains(index) else { return }
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
                dragOffset = nil
                draggingIndex = nil
            }
    }

    /// Markers sit above their point; a tap on one must not also add a new point.
    private func isOnMarker(_ location: CGPoint, proxy: MapProxy) -> Bool {
        boundary.points.contains { point in
            guard let tip = proxy.convert(point.mapCoordinate, to: .local) else { return false }
            return hypot(location.x - tip.x, location.y - (tip.y - 18)) < 26
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
