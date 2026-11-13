import CoreLocation
import MapKit
import SwiftUI

/// Satellite map with white zone lines, per-zone fertilizer totals, and the farmer's position.
struct SpreaderModeMapView: View {
    let garden: Garden
    let zones: [WaypointZone]
    let separators: [[CLLocationCoordinate2D]]
    let plans: [Int: SpreaderZonePlan]
    let currentZoneID: Int?
    let fix: CLLocation?
    @Binding var camera: MapCameraPosition
    @Binding var followsUser: Bool

    var body: some View {
        Map(position: $camera, interactionModes: [.pan, .zoom, .rotate]) {
            ForEach(zones) { zone in
                if zone.id == currentZoneID {
                    ForEach(zone.fragments.indices, id: \.self) { index in
                        MapPolygon(coordinates: zone.fragments[index])
                            .foregroundStyle(.white.opacity(0.16))
                    }
                }
            }
            ForEach(separators.indices, id: \.self) { index in
                MapPolyline(coordinates: separators[index])
                    .stroke(.white.opacity(0.9), lineWidth: 2)
            }
            ForEach(zones) { zone in
                Annotation("Zona \(zone.id)", coordinate: zone.destination) {
                    ZoneLabel(zoneID: zone.id, totalKg: plans[zone.id]?.totalKg,
                              isCurrent: zone.id == currentZoneID)
                        .allowsHitTesting(false)  // the current zone follows GPS only
                }
                .annotationTitles(.hidden)
            }
            if let fix {
                Annotation("Posisi Anda", coordinate: fix.coordinate) {
                    UserLocationMarker()
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.imagery(elevation: .flat))
        .onMapCameraChange(frequency: .onEnd) { _ in
            if camera.positionedByUser { followsUser = false }
        }
        .overlay(alignment: .top) { topFade }
        .overlay(alignment: .topTrailing) {
            // Sketch: Kontrol Peta at x 338, y 210 from the top of the screen (the map runs under the status bar).
            controls.padding(.top, 210).padding(.trailing, 16)
        }
        .onAppear { frameGarden() }
    }

    // MARK: Chrome

    private var topFade: some View {
        Rectangle().fill(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .frame(height: 185)
            .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)
    }

    private var controls: some View {
        VStack(spacing: 0) {
            Button {
                followsUser = false
                frameGarden()
            } label: {
                Image(systemName: "map").frame(width: 48, height: 55)
            }
            .accessibilityLabel("Tampilkan seluruh kebun")
            Button {
                followsUser = true
                if let fix {
                    camera = .region(MKCoordinateRegion(center: fix.coordinate,
                                                        latitudinalMeters: 120, longitudinalMeters: 120))
                }
            } label: {
                Image(systemName: followsUser ? "location.fill" : "location").frame(width: 48, height: 55)
            }
            .disabled(fix == nil)
            .accessibilityLabel("Ikuti posisi saya")
        }
        .font(.title3)
        .buttonStyle(.plain)
        .foregroundStyle(SpreaderPalette.ink)
        .glassEffect(.regular.interactive(), in: Capsule())
    }

    private func frameGarden() {
        let coordinates = garden.boundary.coordinates
        guard !coordinates.isEmpty else { return }
        let rect = MKPolygon(coordinates: coordinates, count: coordinates.count).boundingMapRect
        let padding = max(rect.width, rect.height) * 0.2
        camera = .rect(rect.insetBy(dx: -padding, dy: -padding * 1.6))
    }
}

/// Sketch: Atom / Map Label / Zone / Default.
private struct ZoneLabel: View {
    let zoneID: Int
    let totalKg: Double?
    let isCurrent: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text("Zona \(zoneID)")
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 4)
                .background(.black.opacity(isCurrent ? 0.85 : 0.55), in: RoundedRectangle(cornerRadius: 3))
            if let totalKg {
                Text(SpreaderFormat.kilograms(totalKg, maxFraction: 0))
                    .font(.headline.weight(.bold))
                    .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
            }
        }
        .foregroundStyle(.white)
        .frame(minWidth: 80, minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}

/// Sketch: Atom / User Location.
private struct UserLocationMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(SpreaderPalette.rgb(0xFF6F00, opacity: 0.25))
                .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1.5))
                .frame(width: 56, height: 56)
            Circle().fill(.white)
                .frame(width: 26, height: 26)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
            Circle().fill(SpreaderPalette.brand)
                .frame(width: 18, height: 18)
        }
        .accessibilityLabel("Posisi Anda")
    }
}

/// Back button and title, placed by the screen below the status bar (Sketch: Header, y 60, 48 pt).
struct SpreaderModeHeader: View {
    let onBack: () -> Void
    let backDisabled: Bool

    var body: some View {
        ZStack {
            Text("Mode Pemupukan")
                .font(.title3.weight(.semibold))
                .foregroundStyle(SpreaderPalette.ink)
                .padding(.horizontal, 24)
                .frame(height: 48)
                .glassEffect(.regular, in: Capsule())
                .accessibilityAddTraits(.isHeader)
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(SpreaderPalette.ink)
                .glassEffect(.regular.interactive(), in: Circle())
                .disabled(backDisabled)
                .accessibilityLabel("Kembali")
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
}
