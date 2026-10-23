import SwiftUI
import MapKit

struct GardenBoundaryView: View {
    let location: GardenLocation
    let onSave: (Garden) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var boundary = GardenBoundary()
    @State private var position: MapCameraPosition
    @State private var showsDetails = false
    @State private var showsExitConfirmation = false
    @State private var isRegionOverview = true

    init(location: GardenLocation, onSave: @escaping (Garden) -> Bool) {
        self.location = location
        self.onSave = onSave
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: location.coordinate.mapCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )))
    }

    var body: some View {
        MapReader { proxy in
            BoundaryEditorLayout(
                boundary: boundary, isRegionOverview: isRegionOverview,
                onClose: close, onSkip: { showsExitConfirmation = true },
                onRecenter: recenter,
                onUndo: { _ = boundary.points.popLast() },
                onClear: { boundary.points.removeAll() },
                onConfirm: { showsDetails = true }
            ) {
                Map(position: $position) {
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
                .saturation(0)
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

    private func close() {
        if boundary.points.isEmpty { dismiss() } else { showsExitConfirmation = true }
    }

    private func recenter() {
        withAnimation {
            position = .region(MKCoordinateRegion(
                center: location.coordinate.mapCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
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
#Preview("11 · Peta Kabupaten Live") {
    GardenBoundaryView(location: GardenPreviewData.location, onSave: { _ in true })
}
#endif
