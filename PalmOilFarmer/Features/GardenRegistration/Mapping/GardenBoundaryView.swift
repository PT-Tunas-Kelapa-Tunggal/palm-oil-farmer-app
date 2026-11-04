import SwiftUI
import MapKit

struct GardenBoundaryView: View {
    @State private var flow: GardenMappingFlow
    private var location: GardenLocation { flow.viewModel.location }
    private var boundary: GardenBoundary { flow.viewModel.boundary }
    private var isConfirmingPhoto: Bool { flow.viewModel.isConfirmingPhoto }

    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition
    @State private var isRegionOverview = false
    /// Finger position minus the dragged marker's tip, so a point does not jump under the finger.
    /// Drags use the global space: annotation views are hosted apart from the map's own hierarchy.
    @State private var dragOffset: CGSize?
    @State private var draggingIndex: Int?

    init(flow: GardenMappingFlow) {
        _flow = State(initialValue: flow)
        let location = flow.viewModel.location
        let region = MKCoordinateRegion(
            center: location.coordinate.mapCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
        )
        // A resumed draft is mapped on site, so the camera follows the farmer.
        _position = State(initialValue: location.source == .draft
            ? .userLocation(fallback: .region(region))
            : .region(region))
    }

    var body: some View {
        @Bindable var coordinator = flow.coordinator
        MapReader { proxy in
            BoundaryEditorLayout(
                boundary: boundary, isRegionOverview: isRegionOverview,
                hint: "Ketuk peta untuk menandai sudut-sudut kebun Anda. Geser titik untuk memindahkannya.",
                showsControls: !isConfirmingPhoto,
                onClose: flow.viewModel.close,
                onSkip: skipAction,
                onRecenter: recenter,
                onUndo: flow.viewModel.undo,
                onClear: flow.viewModel.clear,
                onConfirm: flow.viewModel.confirmBoundary
            ) {
                Map(position: $position) {
                    mapContent(proxy)
                }
                .mapStyle(.imagery)
                .mapControls {}
                .onMapCameraChange { context in
                    isRegionOverview = context.region.span.latitudeDelta > 0.03
                }
                .simultaneousGesture(SpatialTapGesture().onEnded { tap in
                    guard !isConfirmingPhoto, !isOnMarker(tap.location, proxy: proxy),
                          let coordinate = proxy.convert(tap.location, from: .local) else { return }
                    flow.viewModel.addPoint(GardenCoordinate(coordinate))
                })
            }
        }
        .overlay(alignment: .bottom) {
            if isConfirmingPhoto { photoConfirmation }
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
                BoundaryPointMarker(number: index + 1)
                    .scaleEffect(draggingIndex == index ? 1.2 : 1)
                    .highPriorityGesture(moveGesture(for: index, proxy: proxy))
                    .accessibilityHint("Geser untuk memindahkan titik")
            }
        }
        ForEach(boundary.points.indices, id: \.self) { index in
            if boundary.points.count > 1 {
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
        }
        if isConfirmingPhoto {
            Annotation("", coordinate: location.coordinate.mapCoordinate, anchor: .bottom) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 44))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.white, KropsTheme.primary)
                    .shadow(radius: 4)
                    .accessibilityLabel("Lokasi dari foto")
            }
        } else if boundary.points.isEmpty && location.source != .draft {
            Annotation("", coordinate: location.coordinate.mapCoordinate) {
                Circle().fill(.white).frame(width: 28, height: 28)
                    .padding(10).background(.white.opacity(0.35), in: Circle())
                    .padding(8).background(.white.opacity(0.2), in: Circle())
                    .accessibilityLabel("Lokasi terpilih")
            }
        }
        UserAnnotation()
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

    private var photoConfirmation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Lokasi Ditemukan dari Foto").font(.title3.weight(.semibold))
            Text("Pastikan titik yang ditampilkan di peta adalah lokasi kebun Anda.")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 8)
            PrimaryActionButton(title: "Ya, Ini kebun saya") {
                withAnimation { flow.viewModel.confirmPhoto() }
            }
            Button("Cari Lagi") {
                flow.viewModel.searchAgain()
            }
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
    }

    private var skipAction: (() -> Void)? {
        guard flow.viewModel.canSaveLocationDraft else { return nil }
        return { _ = flow.viewModel.saveDraft() }
    }

    private func recenter() {
        withAnimation {
            position = .userLocation(fallback: .region(MKCoordinateRegion(
                center: location.coordinate.mapCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
            )))
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
