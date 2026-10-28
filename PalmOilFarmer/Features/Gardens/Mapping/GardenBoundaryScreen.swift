import SwiftUI
import MapKit

struct GardenBoundaryScreen: View {
    let location: GardenLocation
    let onSave: (Garden) -> Bool
    var onDefer: ((MappingDraft) -> Bool)? = nil
    var onSearchAgain: (() -> Void)? = nil
    var resumesDraft = false

    @Environment(\.dismiss) private var dismiss
    @State private var boundary = GardenBoundary()
    @State private var position: MapCameraPosition
    @State private var showsDetails = false
    @State private var showsExitConfirmation = false
    @State private var isRegionOverview = true
    @State private var photoConfirmed: Bool
    @State private var locationProvider = CurrentLocationProvider()
    @State private var isLocating = false
    @State private var locationError: String?

    init(location: GardenLocation, initialBoundary: GardenBoundary = GardenBoundary(),
         resumesDraft: Bool = false, onDefer: ((MappingDraft) -> Bool)? = nil, onSearchAgain: (() -> Void)? = nil,
         onSave: @escaping (Garden) -> Bool) {
        self.location = location
        self.onSave = onSave
        self.onDefer = onDefer
        self.onSearchAgain = onSearchAgain
        self.resumesDraft = resumesDraft
        _boundary = State(initialValue: initialBoundary)
        _photoConfirmed = State(initialValue: location.source != .photo || !initialBoundary.points.isEmpty)
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: location.coordinate.mapCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )))
    }

    var body: some View {
        Group {
            if photoConfirmed {
                editor
            } else {
                PhotoLocationConfirmationScreen(location: location, onConfirm: {
                    photoConfirmed = true
                }, onSearchAgain: {
                    onSearchAgain?()
                    dismiss()
                })
            }
        }
    }

    private var editor: some View {
        MapReader { proxy in
            BoundaryEditorLayout(
                boundary: boundary, isRegionOverview: isRegionOverview,
                allowsDeferring: location.source == .search && onDefer != nil,
                closeConfirmation: ScreenCloseConfirmation(
                    isPresented: $showsExitConfirmation,
                    title: "Keluar dari pemetaan?",
                    message: "Batas yang belum disimpan perlu dipetakan ulang saat kamu kembali.",
                    destructiveTitle: "Jangan Simpan",
                    cancelTitle: "Lanjutkan pemetaan",
                    onDiscard: { dismiss() }
                ),
                onClose: close, onSkip: deferMapping,
                onRecenter: recenter,
                onUndo: { _ = boundary.points.popLast() },
                onClear: { boundary.points.removeAll() },
                onConfirm: { showsDetails = true }
            ) {
                Map(position: $position) {
                    UserAnnotation()
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
                    if boundary.points.isEmpty {
                        Annotation(isRegionOverview ? "Lokasi terpilih" : "", coordinate: location.coordinate.mapCoordinate) {
                            Circle().fill(.white).frame(width: 28, height: 28)
                                .padding(10).background(.white.opacity(0.35), in: Circle())
                                .padding(8).background(.white.opacity(0.2), in: Circle())
                        }
                    }
                }
                .mapStyle(.imagery)
                .mapControls {}
                .onMapCameraChange { context in
                    isRegionOverview = context.region.span.latitudeDelta > 0.03
                }
                .simultaneousGesture(SpatialTapGesture().onEnded { tap in
                    guard let coordinate = proxy.convert(tap.location, from: .local) else { return }
                    let point = GardenCoordinate(coordinate)
                    guard !boundary.points.contains(point) else { return }
                    boundary.points.append(point)
                })
            }
        }
        .sheet(isPresented: $showsDetails) {
            GardenDetailsScreen(location: location, boundary: boundary) { garden in
                guard onSave(garden) else { return false }
                showsDetails = false
                dismiss()
                return true
            }
        }
        .task { if resumesDraft { recenter() } }
        .task(id: isLocating) {
            guard isLocating else { return }
            defer { isLocating = false }
            do {
                let coordinate = try await locationProvider.coordinate()
                try Task.checkCancellation()
                withAnimation {
                    position = .userLocation(followsHeading: false, fallback: .region(
                        MKCoordinateRegion(center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005))))
                }
            } catch {
                guard !Task.isCancelled else { return }
                locationError = "Lokasi tidak dapat diperoleh. Periksa izin lokasi dan coba lagi."
            }
        }
        .alert("Pemetaan kebun", isPresented: Binding(
            get: { locationError != nil }, set: { if !$0 { locationError = nil } }
        )) {
            Button("Mengerti", role: .cancel) {}
        } message: { Text(locationError ?? "") }
    }

    private func close() {
        if boundary.points.isEmpty { dismiss() } else { showsExitConfirmation = true }
    }

    private func deferMapping() {
        guard let onDefer else { return }
        if onDefer(MappingDraft(location: location, boundary: boundary)) {
            dismiss()
        } else {
            locationError = "Draf belum tersimpan. Coba lagi."
        }
    }

    private func recenter() {
        guard !isLocating else { return }
        isLocating = true
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
#Preview("11 · Peta Kabupaten Live") {
    GardenBoundaryScreen(location: GardenPreviewData.location, onSave: { _ in true })
}
#endif
