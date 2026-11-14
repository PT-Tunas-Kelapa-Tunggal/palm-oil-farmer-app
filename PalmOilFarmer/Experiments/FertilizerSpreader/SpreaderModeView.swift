import CoreLocation
import MapKit
import SwiftUI

/// Mode Pemupukan: the farmer stands in a zone, connects the spreader, and releases one tree's dose per press.
/// Opened from the Pemupukan garden list and from the FindingWaypoint map (tombol "Semprot").
struct SpreaderModeView: View {
    let garden: Garden
    let zones: [WaypointZone]
    private let plans: [Int: SpreaderZonePlan]
    private let separators: [[CLLocationCoordinate2D]]

    /// Zone the farmer stands in, from GPS only. nil until a precise fix lands inside a zone.
    @State private var currentZoneID: Int?
    @State private var spreader = SpreaderBLEManager()
    @State private var location = WaypointLocationSession()
    @State private var camera: MapCameraPosition = .automatic
    @State private var followsUser = false
    /// Trees fertilized in this session, per zone. Counted only when every pulse of a dose was sent.
    @State private var fertilizedTrees: [Int: Int] = [:]
    @State private var selectedTab: SpreaderModeTab = .mode
    @State private var customZones: [WaypointZone] = []
    @State private var selectedCustomZoneID: Int?
    @State private var draftBoundary: [CLLocationCoordinate2D] = []
    @State private var isDrawingCustomZone = false
    @State private var customZoneError: String?
    @Environment(\.dismiss) private var dismiss

    init(garden: Garden, zones: [WaypointZone]) {
        self.garden = garden
        self.zones = zones
        plans = SpreaderZonePlan.sample(for: zones)
        separators = SpreaderGeometry.separators(for: zones)
    }

    private var customPlans: [Int: SpreaderZonePlan] {
        SpreaderZonePlan.sample(for: customZones)
    }

    private var activeZoneID: Int? {
        selectedTab == .custom ? selectedCustomZoneID : currentZoneID
    }

    private var activePlans: [Int: SpreaderZonePlan] {
        selectedTab == .custom ? customPlans : plans
    }

    private var activeZoneName: String? {
        guard let activeZoneID else { return nil }
        if selectedTab == .custom,
           let index = customZones.firstIndex(where: { $0.id == activeZoneID }) {
            return "Zona custom \(index + 1)"
        }
        return "Zona \(activeZoneID)"
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let fix = location.freshLocation(at: context.date)
            VStack(spacing: -32) {
                SpreaderModeMapView(
                    garden: garden, zones: zones, separators: separators, plans: plans,
                    currentZoneID: currentZoneID,
                    tab: selectedTab,
                    customZones: customZones,
                    selectedCustomZoneID: selectedCustomZoneID,
                    draftBoundary: draftBoundary,
                    isDrawingCustomZone: isDrawingCustomZone,
                    onMapTap: addBoundaryPoint,
                    onMoveBoundaryPoint: moveBoundaryPoint,
                    onSelectCustomZone: { selectedCustomZoneID = $0 },
                    fix: fix,
                    camera: $camera, followsUser: $followsUser
                )
                .ignoresSafeArea(edges: .top)
                .frame(maxHeight: .infinity)

                SpreaderModePanel(
                    spreader: spreader,
                    zoneID: activeZoneID,
                    zoneName: activeZoneName,
                    plan: activeZoneID.flatMap { activePlans[$0] },
                    fertilizedTrees: activeZoneID.map { fertilizedTrees[$0, default: 0] } ?? 0,
                    now: context.date,
                    onDispense: dispense
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        // Outside the map, which runs under the status bar, so the header stays below the Dynamic Island.
        .overlay(alignment: .top) {
            SpreaderModeHeader(
                selectedTab: $selectedTab,
                onBack: { dismiss() },
                backDisabled: spreader.isRunning
            )
        }
        .overlay(alignment: .top) {
            if selectedTab == .custom {
                customZoneControls
                    .padding(.top, 164)
                    .padding(.horizontal, 16)
            }
        }
        .background(SpreaderPalette.panel.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task { await location.run() }
        .onDisappear { spreader.disconnect() }
        .onChange(of: location.location?.timestamp) { _, _ in followLocation() }
        .onChange(of: spreader.lastFinished) { _, finished in count(finished) }
        .sensoryFeedback(.success, trigger: fertilizedTrees.values.reduce(0, +))
        .sensoryFeedback(.impact, trigger: spreader.isRunning)
    }

    // MARK: Actions

    private func dispense() {
        guard let zoneID = activeZoneID, let plan = activePlans[zoneID] else { return }
        spreader.dispense(liters: plan.litersPerTree, zoneID: zoneID)
    }

    /// Counts one tree when a dose ran to the end (not stopped or disconnected).
    private func count(_ finished: FinishedDispense?) {
        guard let finished, finished.completed else { return }
        withAnimation { fertilizedTrees[finished.zoneID, default: 0] += 1 }
    }

    /// "Zona saat ini" follows GPS only: the zone containing a precise fix, or none outside the zones.
    /// Never changes while fertilizer is coming out, so the dose stays in the zone it started in.
    private func followLocation() {
        guard selectedTab == .mode else { return }
        guard let fix = location.freshLocation(at: .now) else { return }
        if followsUser {
            camera = .region(MKCoordinateRegion(center: fix.coordinate, latitudinalMeters: 120, longitudinalMeters: 120))
        }
        guard !spreader.isRunning, !location.reducedAccuracy, fix.horizontalAccuracy <= 25 else { return }
        let zoneID = SpreaderGeometry.zoneID(containing: fix.coordinate, in: zones)
        if zoneID != currentZoneID { currentZoneID = zoneID }
    }

    private var customZoneControls: some View {
        VStack(spacing: 8) {
            if isDrawingCustomZone {
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Ketuk peta untuk menambah titik")
                                .font(.footnote.weight(.medium))
                            Text("\(draftBoundary.count) titik • \(draftAreaHectares.formatted(.number.precision(.fractionLength(2)))) ha")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Button("Batal") {
                            draftBoundary = []
                            isDrawingCustomZone = false
                        }
                    }
                    HStack(spacing: 10) {
                        Button("Undo") { _ = draftBoundary.popLast() }
                            .disabled(draftBoundary.isEmpty)
                        Button("Hapus titik") { draftBoundary = [] }
                            .disabled(draftBoundary.isEmpty)
                        Spacer()
                        Button("Pakai Zona") { saveCustomZone() }
                            .fontWeight(.semibold)
                            .disabled(draftBoundary.count < 3)
                    }
                }
                if let customZoneError {
                    Text(customZoneError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } else {
                HStack(spacing: 10) {
                    Button {
                        draftBoundary = []
                        customZoneError = nil
                        isDrawingCustomZone = true
                    } label: {
                        Label("Buat zona", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)

                    if customZones.isEmpty {
                        Text("Tandai batas kebun di peta")
                            .font(.footnote)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(customZones) { zone in
                                    Button("Zona \(zone.id - 10_000)") {
                                        selectedCustomZoneID = zone.id
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(selectedCustomZoneID == zone.id ? .green : .white)
                                }
                            }
                        }
                    }
                }
            }
        }
        .font(.footnote)
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func addBoundaryPoint(_ coordinate: CLLocationCoordinate2D) {
        guard selectedTab == .custom, isDrawingCustomZone else { return }
        customZoneError = nil
        draftBoundary.append(coordinate)
    }

    private func moveBoundaryPoint(at index: Int, to coordinate: CLLocationCoordinate2D) {
        guard draftBoundary.indices.contains(index) else { return }
        customZoneError = nil
        draftBoundary[index] = coordinate
    }

    private func saveCustomZone() {
        guard draftBoundary.count >= 3 else { return }
        let boundary = GardenBoundary(points: draftBoundary.map {
            GardenCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        })
        guard boundary.isValid else {
            customZoneError = "Batas harus membentuk area tertutup tanpa garis yang berpotongan."
            return
        }
        let zoneID = max(customZones.map(\.id).max() ?? 9_999, 9_999) + 1
        let zone = makeCustomZone(id: zoneID, boundary: boundary)
        withAnimation {
            customZones.append(zone)
            selectedCustomZoneID = zone.id
            draftBoundary = []
            customZoneError = nil
            isDrawingCustomZone = false
        }
    }

    private func makeCustomZone(id: Int, boundary: GardenBoundary) -> WaypointZone {
        let coordinates = boundary.coordinates
        let points = coordinates.map { MKMapPoint($0) }
        let areaInMapPoints = abs(points.indices.reduce(0.0) { sum, index in
            let first = points[index]
            let second = points[(index + 1) % points.count]
            return sum + first.x * second.y - second.x * first.y
        }) / 2
        let center = CLLocationCoordinate2D(
            latitude: coordinates.map(\.latitude).reduce(0, +) / Double(coordinates.count),
            longitude: coordinates.map(\.longitude).reduce(0, +) / Double(coordinates.count)
        )
        let pointsPerMeter = MKMapPointsPerMeterAtLatitude(center.latitude)
        return WaypointZone(
            id: id,
            fragments: [coordinates],
            destination: center,
            areaSquareMeters: areaInMapPoints / (pointsPerMeter * pointsPerMeter)
        )
    }

    private var draftAreaHectares: Double {
        GardenBoundary(points: draftBoundary.map {
            GardenCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        }).areaHectares
    }
}

#if DEBUG
#Preview("Mode Pemupukan") {
    let garden = WaypointPreviewData.garden
    SpreaderModeView(garden: garden, zones: WaypointZoning.zones(for: garden.boundary))
}
#endif
