import CoreLocation
import MapKit
import SwiftUI

struct WaypointMapView: View {
    let garden: Garden
    let zones: [WaypointZone]
    @State private var selectedZoneID = 5
    @State private var tracking = false
    @State private var followsUser = false
    @State private var camera: MapCameraPosition = .automatic
    @State private var session = WaypointLocationSession()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    private var selectedZone: WaypointZone? {
        zones.first { $0.id == selectedZoneID }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let fix = tracking ? session.freshLocation(at: context.date) : nil
            map(fix: fix)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    guidance(fix: fix)
                }
        }
        .navigationTitle(garden.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    followsUser = false
                    frameGarden()
                } label: {
                    Image(systemName: "map")
                }
                .accessibilityLabel("Tampilkan seluruh kebun")
            }
        }
        .onAppear { frameGarden() }
        .task(id: tracking) {
            if tracking { await session.run() }
        }
        .onDisappear { tracking = false }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { tracking = false }
        }
        .onChange(of: session.location?.timestamp) { _, _ in
            if followsUser, let fix = session.freshLocation(at: .now) {
                camera = .region(MKCoordinateRegion(
                    center: fix.coordinate,
                    latitudinalMeters: 180, longitudinalMeters: 180
                ))
            }
        }
    }

    private func map(fix: CLLocation?) -> some View {
        Map(position: $camera, interactionModes: [.pan, .zoom, .rotate]) {
            ForEach(zones) { zone in
                ForEach(zone.fragments.indices, id: \.self) { index in
                    MapPolygon(coordinates: zone.fragments[index])
                        .foregroundStyle(zone.id == selectedZoneID
                            ? Color.orange.opacity(0.65)
                            : WaypointPalette.color(for: zone.id).opacity(0.7))
                }
                Annotation("Zona \(zone.id)", coordinate: zone.destination) {
                    Button {
                        selectedZoneID = zone.id
                    } label: {
                        Text("\(zone.id)").font(.headline)
                            .frame(width: 44, height: 44)
                            .foregroundStyle(zone.id == selectedZoneID ? .white : .black)
                            .background(zone.id == selectedZoneID ? Color.orange : Color.white,
                                        in: Circle())
                            .overlay(Circle().stroke(.black.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pilih zona \(zone.id)")
                }
                .annotationTitles(.hidden)
            }
            MapPolyline(coordinates: garden.boundary.coordinates + Array(garden.boundary.coordinates.prefix(1)))
                .stroke(.white, lineWidth: 2)
            if let fix {
                MapCircle(center: fix.coordinate, radius: fix.horizontalAccuracy)
                    .foregroundStyle(.blue.opacity(0.12))
                    .stroke(.blue.opacity(0.35), lineWidth: 1)
                if let zone = selectedZone, !session.reducedAccuracy, fix.horizontalAccuracy <= 25 {
                    MapPolyline(coordinates: [fix.coordinate, zone.destination])
                        .stroke(.blue, style: StrokeStyle(lineWidth: 3, dash: [7, 5]))
                }
                Annotation("Posisi Anda", coordinate: fix.coordinate) {
                    Circle().fill(.blue)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .shadow(radius: 3)
                        .accessibilityLabel("Posisi GPS Anda")
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.imagery(elevation: .flat))
        .mapControls { MapCompass(); MapScaleView() }
        .onMapCameraChange(frequency: .onEnd) { _ in
            if camera.positionedByUser { followsUser = false }
        }
        .overlay(alignment: .topLeading) {
            Text("ONLINE • EKSPERIMEN")
                .font(.caption2.bold())
                .padding(10)
                .background(.regularMaterial, in: Capsule())
                .padding()
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                followsUser = true
                if let fix {
                    camera = .region(MKCoordinateRegion(center: fix.coordinate,
                        latitudinalMeters: 180, longitudinalMeters: 180))
                }
            } label: {
                Image(systemName: followsUser ? "location.fill" : "location")
                    .frame(width: 48, height: 48)
                    .background(.regularMaterial, in: Circle())
            }
            .disabled(fix == nil)
            .accessibilityLabel("Ikuti posisi saya")
            .padding()
        }
    }

    private func guidance(fix: CLLocation?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tujuan").font(.headline)
                Spacer()
                if let zone = selectedZone {
                    Text("Zona \(zone.id) • \(zone.areaSquareMeters / 10_000, specifier: "%.2f") ha")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Picker("Zona tujuan", selection: $selectedZoneID) {
                ForEach(zones) { zone in
                    Text("\(zone.id)").tag(zone.id)
                }
            }
            .pickerStyle(.segmented)

            if let fix, let zone = selectedZone {
                let distance = WaypointLocationSession.distance(from: fix, to: zone)
                let reliable = !session.reducedAccuracy && fix.horizontalAccuracy <= 25
                HStack(alignment: .firstTextBaseline) {
                    Text(distance < 1_000
                         ? "\(distance.formatted(.number.precision(.fractionLength(0)))) m"
                         : "\((distance / 1_000).formatted(.number.precision(.fractionLength(1)))) km")
                        .font(.title.bold()).monospacedDigit()
                    Text("ke titik zona \(zone.id)").font(.subheadline)
                }
                Text(reliable
                     ? "Arah \(Int(WaypointLocationSession.bearing(from: fix.coordinate, to: zone.destination)))° dari utara • Akurasi ±\(Int(fix.horizontalAccuracy)) m"
                     : "Lokasi kurang akurat untuk panduan antar zona.")
                    .font(.caption).foregroundStyle(.secondary)
                if reliable && fix.horizontalAccuracy <= 10 && distance <= 15 {
                    Label("Dekat titik tujuan. Pastikan zona di lapangan.", systemImage: "flag.checkered")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.green)
                }
            } else {
                Text(tracking ? session.message : "Pilih zona lalu mulai panduan.")
                    .font(.subheadline).foregroundStyle(.secondary)
                if tracking && session.location != nil {
                    Text("Posisi kedaluwarsa. Menunggu GPS terbaru.")
                        .font(.caption).foregroundStyle(.orange)
                }
            }

            Text("Garis langsung ke tujuan, bukan rute jalan. Ikuti akses kebun yang dapat dilalui.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Button {
                    tracking.toggle()
                    if !tracking { followsUser = false }
                } label: {
                    Label(tracking ? "Hentikan" : "Mulai panduan",
                          systemImage: tracking ? "stop.fill" : "location.fill")
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedZone == nil)
                if session.needsSettings || session.reducedAccuracy {
                    Button("Pengaturan") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
    }

    private func frameGarden() {
        let points = garden.boundary.coordinates.map { MKMapPoint($0) }
        guard let first = points.first else { return }
        let rect = points.dropFirst().reduce(MKMapRect(
            origin: first, size: MKMapSize(width: 1, height: 1)
        )) { partial, point in
            partial.union(MKMapRect(origin: point, size: MKMapSize(width: 1, height: 1)))
        }
        camera = .rect(rect.insetBy(dx: -rect.width * 0.18, dy: -rect.height * 0.18))
    }
}

#if DEBUG
#Preview("Zona 5") {
    NavigationStack {
        WaypointMapView(garden: WaypointPreviewData.garden,
                        zones: WaypointZoning.zones(for: WaypointPreviewData.garden.boundary))
    }
}
#endif
