import CoreLocation
import MapKit
import SwiftUI

/// Satellite map with compact zone markers and the farmer's position.
enum SpreaderModeTab: String, CaseIterable, Identifiable, Equatable {
    case mode = "Mode Pemupukan"
    case custom = "Custom"
    var id: String { rawValue }
}

struct SpreaderModeMapView: View {

    let garden: Garden
    let zones: [WaypointZone]
    let assessmentMap: FarmOrthomosaicMapData?
    let currentZoneID: Int?
    let tab: SpreaderModeTab
    let customZones: [WaypointZone]
    let selectedCustomZoneID: Int?
    let draftBoundary: [CLLocationCoordinate2D]
    let isDrawingCustomZone: Bool
    let onMapTap: (CLLocationCoordinate2D) -> Void
    let onMoveBoundaryPoint: (Int, CLLocationCoordinate2D) -> Void
    let onSelectCustomZone: (Int) -> Void
    let fix: CLLocation?
    @Binding var camera: MapCameraPosition
    @Binding var followsUser: Bool
    @State private var draggingIndex: Int?
    @State private var dragOffset: CGSize?
    @State private var cameraRequestID = 0
    @GestureState private var isDraggingPoint = false
    private let markerHitSize: CGFloat = 44

    var body: some View {
        if let assessmentMap {
            SpreaderAssessmentMapKitView(
                data: assessmentMap,
                zones: zones,
                currentZoneID: currentZoneID,
                fix: fix,
                camera: $camera,
                cameraRequestID: cameraRequestID,
                followsUser: $followsUser
            )
            .overlay(alignment: .top) { topFade }
            .overlay(alignment: .topTrailing) {
                controls.padding(.top, 210).padding(.trailing, 16)
            }
            .onAppear { frameGarden() }
        } else {
        MapReader { proxy in
        Map(position: $camera, interactionModes: [.pan, .zoom, .rotate]) {
            if tab == .mode {
                ForEach(zones) { zone in
                    Annotation("Zona \(zone.id)", coordinate: zone.destination) {
                        ZoneLabel(zoneID: zone.id, isCurrent: zone.id == currentZoneID)
                            .allowsHitTesting(false)  // the current zone follows GPS only
                    }
                    .annotationTitles(.hidden)
                }
            } else {
                ForEach(customZones) { zone in
                    BoundaryGeometryMapContent(
                        coordinates: zone.fragments.first ?? [],
                        isClosed: true,
                        fillOpacity: zone.id == selectedCustomZoneID ? 0.24 : 0.08
                    )
                    Annotation("Zona custom", coordinate: zone.destination) {
                        Button { onSelectCustomZone(zone.id) } label: {
                            ZoneLabel(zoneID: zone.id - 10_000,
                                      isCurrent: zone.id == selectedCustomZoneID)
                        }
                        .buttonStyle(.plain)
                    }
                    .annotationTitles(.hidden)
                }
                BoundaryGeometryMapContent(
                    coordinates: draftBoundary,
                    isClosed: !isDrawingCustomZone && draftBoundary.count >= 3,
                    fillOpacity: 0.16
                )
                ForEach(draftBoundary.indices, id: \.self) { index in
                    Annotation("Titik batas \(index + 1)", coordinate: draftBoundary[index], anchor: .center) {
                        RegistrationBoundaryMarker(
                            number: index + 1,
                            isActive: index == (draggingIndex ?? draftBoundary.indices.last)
                        )
                        .frame(width: markerHitSize, height: markerHitSize)
                        .contentShape(Circle())
                        .highPriorityGesture(moveGesture(for: index, proxy: proxy))
                        .accessibilityHint("Geser untuk memindahkan titik")
                    }
                    .annotationTitles(.hidden)
                }
                let edgeCount = draftBoundary.count >= 3 ? draftBoundary.count : max(0, draftBoundary.count - 1)
                ForEach(0..<edgeCount, id: \.self) { index in
                    let first = draftBoundary[index]
                    let second = draftBoundary[(index + 1) % draftBoundary.count]
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
            if let fix {
                Annotation("Posisi Anda", coordinate: fix.coordinate) {
                    UserLocationMarker()
                }
                .annotationTitles(.hidden)
            }
        }
        .simultaneousGesture(SpatialTapGesture(coordinateSpace: .global).onEnded { tap in
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(60))
                guard isDrawingCustomZone, draggingIndex == nil,
                      !isOnMarker(tap.location, proxy: proxy),
                      let coordinate = proxy.convert(tap.location, from: .global) else { return }
                onMapTap(coordinate)
            }
        })
        .onChange(of: isDraggingPoint) { _, isDragging in
            if !isDragging {
                dragOffset = nil
                draggingIndex = nil
            }
        }
        .mapStyle(.imagery(elevation: .flat))
        .onMapCameraChange(frequency: .onEnd) { _ in
            if camera.positionedByUser { followsUser = false }
        }
        .overlay(alignment: .top) { topFade }
        .overlay(alignment: .topTrailing) {
            // Sketch: Kontrol Peta at x 338, y 210 from the top of the screen (the map runs under the status bar).
            controls.padding(.top, tab == .custom ? 278 : 210).padding(.trailing, 16)
        }
        .onAppear { frameGarden() }
        }
        }
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
                    cameraRequestID += 1
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
        cameraRequestID += 1
        camera = .rect(rect.insetBy(dx: -padding, dy: -padding * 1.6))
    }

    private func moveGesture(for index: Int, proxy: MapProxy) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .updating($isDraggingPoint) { _, isDragging, _ in isDragging = true }
            .onChanged { drag in
                guard isDrawingCustomZone, draftBoundary.indices.contains(index) else { return }
                draggingIndex = index
                if dragOffset == nil,
                   let tip = proxy.convert(draftBoundary[index], to: .global) {
                    dragOffset = CGSize(width: drag.startLocation.x - tip.x, height: drag.startLocation.y - tip.y)
                }
                let offset = dragOffset ?? .zero
                let tip = CGPoint(x: drag.location.x - offset.width, y: drag.location.y - offset.height)
                guard let coordinate = proxy.convert(tip, from: .global) else { return }
                onMoveBoundaryPoint(index, coordinate)
            }
    }

    private func isOnMarker(_ location: CGPoint, proxy: MapProxy) -> Bool {
        draftBoundary.contains { coordinate in
            guard let tip = proxy.convert(coordinate, to: .global) else { return false }
            return hypot(location.x - tip.x, location.y - tip.y) < markerHitSize / 2
        }
    }

    private func midpoint(_ first: CLLocationCoordinate2D, _ second: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: (first.latitude + second.latitude) / 2,
                               longitude: (first.longitude + second.longitude) / 2)
    }

    private func distance(_ first: CLLocationCoordinate2D, _ second: CLLocationCoordinate2D) -> String {
        CLLocation(latitude: first.latitude, longitude: first.longitude)
            .distance(from: CLLocation(latitude: second.latitude, longitude: second.longitude))
            .formatted(.number.precision(.fractionLength(0))) + " m"
    }
}

/// Sketch: Atom / Map Label / Zone / Default.
private struct ZoneLabel: View {
    let zoneID: Int
    let isCurrent: Bool

    var body: some View {
        Text("Z\(zoneID)")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(.black.opacity(isCurrent ? 0.85 : 0.65), in: Capsule())
            .accessibilityLabel("Zona \(zoneID)")
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
    @Binding var selectedTab: SpreaderModeTab
    let onBack: () -> Void
    let backDisabled: Bool
    let showsCustomTab: Bool

    var body: some View {
        HStack(spacing: 10) {
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
            .frame(width: 44)

            if showsCustomTab {
                HStack(spacing: 2) {
                    ForEach(SpreaderModeTab.allCases) { tab in
                        Button {
                            selectedTab = tab
                        } label: {
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .foregroundStyle(selectedTab == tab ? SpreaderPalette.ink : SpreaderPalette.inkSecondary)
                                .padding(.horizontal, 12)
                                .frame(height: 42)
                                .background {
                                    if selectedTab == tab {
                                        Capsule().fill(.white.opacity(0.72))
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(backDisabled)
                    }
                }
                .padding(3)
                .glassEffect(.regular, in: Capsule())
            } else {
                Text("Mode Pemupukan")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
            }

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
    }
}
