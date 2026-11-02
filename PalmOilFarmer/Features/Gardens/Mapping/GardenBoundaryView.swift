import SwiftUI
import MapKit

struct GardenBoundaryView: View {
    let location: GardenLocation
    let onSave: (Garden) -> Bool
    /// Saves the location as a draft for "Lakukan Nanti".
    var onSaveDraft: ((GardenLocation) -> Bool)? = nil
    /// Returns to the address search when a photo location is wrong.
    var onSearchAgain: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var boundary = GardenBoundary()
    @State private var position: MapCameraPosition
    @State private var showsDetails = false
    @State private var showsBoundaryGuide: Bool
    @State private var showsExitConfirmation = false
    @State private var isRegionOverview = false
    @State private var isConfirmingPhoto: Bool
    @State private var locationManager = CLLocationManager()
    /// Finger position minus the dragged marker's tip, so a point does not jump under the finger.
    /// Drags use the global space: annotation views are hosted apart from the map's own hierarchy.
    @State private var dragOffset: CGSize?
    @State private var draggingIndex: Int?

    init(location: GardenLocation, onSave: @escaping (Garden) -> Bool,
         onSaveDraft: ((GardenLocation) -> Bool)? = nil, onSearchAgain: (() -> Void)? = nil) {
        self.location = location
        self.onSave = onSave
        self.onSaveDraft = onSaveDraft
        self.onSearchAgain = onSearchAgain
        _isConfirmingPhoto = State(initialValue: location.source == .photo)
        _showsBoundaryGuide = State(initialValue: location.source != .photo)
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
        MapReader { proxy in
            BoundaryEditorLayout(
                boundary: boundary, isRegionOverview: isRegionOverview,
                hint: "Ketuk peta untuk menandai sudut-sudut kebun Anda. Geser titik untuk memindahkannya.",
                showsControls: !isConfirmingPhoto && !showsBoundaryGuide,
                onClose: close,
                onSkip: skipAction,
                onSearch: onSearchAgain.map { action in {
                    dismiss()
                    action()
                } },
                onRecenter: recenter,
                onUndo: { _ = boundary.points.popLast() },
                onClear: { boundary.points.removeAll() },
                onConfirm: { showsDetails = true }
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
                    guard !isConfirmingPhoto, !showsBoundaryGuide, !isOnMarker(tap.location, proxy: proxy),
                          let coordinate = proxy.convert(tap.location, from: .local) else { return }
                    let point = GardenCoordinate(coordinate)
                    guard !boundary.points.contains(point) else { return }
                    boundary.points.append(point)
                })
            }
        }
        .overlay {
            if isConfirmingPhoto || showsBoundaryGuide {
                VStack(spacing: 0) {
                    Spacer(minLength: 16)
                    ViewThatFits(in: .vertical) {
                        guidanceCard
                            .fixedSize(horizontal: false, vertical: true)
                        ScrollView {
                            guidanceCard
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                }
                // The floating card ends 8 pt from the physical screen edge, as in Sketch.
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .onAppear { locationManager.requestWhenInUseAuthorization() }
        .sheet(isPresented: $showsDetails) {
            GardenDetailsView(location: location, boundary: boundary) { garden in
                guard onSave(garden) else { return false }
                showsDetails = false
                dismiss()
                return true
            }
        }
        .confirmationDialog("Keluar dari pemetaan?", isPresented: $showsExitConfirmation, titleVisibility: .visible) {
            Button("Keluar tanpa menyimpan", role: .destructive) { dismiss() }
            Button("Lanjutkan pemetaan", role: .cancel) {}
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
                boundary.points[index] = GardenCoordinate(coordinate)
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

    @ViewBuilder
    private var guidanceCard: some View {
        if isConfirmingPhoto {
            photoConfirmation
        } else if showsBoundaryGuide {
            boundaryGuide
        }
    }

    private var photoConfirmation: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Lokasi Ditemukan dari Foto")
                .font(.title.bold())
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 8)
            Text("Pastikan titik yang ditampilkan di peta adalah lokasi kebun Anda.")
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 92))
                .frame(maxWidth: .infinity)
                .frame(height: 157)
                .accessibilityHidden(true)
            GardenFlowActionButton(title: "Ya, Ini kebun saya") {
                withAnimation {
                    isConfirmingPhoto = false
                    showsBoundaryGuide = true
                }
            }
            Button("Cari Lagi") {
                dismiss()
                onSearchAgain?()
            }
            .font(.body)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.top, 8)
        }
        .padding(24)
        .background(GardenFlowStyle.background, in: RoundedRectangle(cornerRadius: 32))
    }

    private var boundaryGuide: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Petakan batas kebun").font(.title.bold())
            Text("Tandai titik di sepanjang batas kebun, pastikan seluruh bagian kebun masuk ke dalam area pemetaan.")
                .fixedSize(horizontal: false, vertical: true)
            BoundaryGuideIllustration()
                .frame(height: 141)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .accessibilityHidden(true)
            GardenFlowActionButton(title: "Lanjut") {
                withAnimation { showsBoundaryGuide = false }
            }
        }
        .padding(24)
        .background(GardenFlowStyle.background, in: RoundedRectangle(cornerRadius: 32))
    }

    private var skipAction: (() -> Void)? {
        guard location.source == .search, onSaveDraft != nil else { return nil }
        return saveDraft
    }

    private func saveDraft() {
        guard let onSaveDraft, onSaveDraft(location) else { return }
        dismiss()
    }

    private func close() {
        if boundary.points.isEmpty { dismiss() } else { showsExitConfirmation = true }
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
