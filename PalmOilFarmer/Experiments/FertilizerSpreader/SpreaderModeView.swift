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
    @Environment(\.dismiss) private var dismiss

    init(garden: Garden, zones: [WaypointZone]) {
        self.garden = garden
        self.zones = zones
        plans = SpreaderZonePlan.sample(for: zones)
        separators = SpreaderGeometry.separators(for: zones)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let fix = location.freshLocation(at: context.date)
            VStack(spacing: -32) {
                SpreaderModeMapView(
                    garden: garden, zones: zones, separators: separators, plans: plans,
                    currentZoneID: currentZoneID, fix: fix,
                    camera: $camera, followsUser: $followsUser
                )
                .ignoresSafeArea(edges: .top)
                .frame(maxHeight: .infinity)

                SpreaderModePanel(
                    spreader: spreader,
                    zoneID: currentZoneID,
                    plan: currentZoneID.flatMap { plans[$0] },
                    fertilizedTrees: currentZoneID.map { fertilizedTrees[$0, default: 0] } ?? 0,
                    now: context.date,
                    onDispense: dispense
                )
            }
            .ignoresSafeArea(edges: .bottom)
        }
        // Outside the map, which runs under the status bar, so the header stays below the Dynamic Island.
        .overlay(alignment: .top) {
            SpreaderModeHeader(onBack: { dismiss() }, backDisabled: spreader.isRunning)
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
        guard let zoneID = currentZoneID, let plan = plans[zoneID] else { return }
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
        guard let fix = location.freshLocation(at: .now) else { return }
        if followsUser {
            camera = .region(MKCoordinateRegion(center: fix.coordinate, latitudinalMeters: 120, longitudinalMeters: 120))
        }
        guard !spreader.isRunning, !location.reducedAccuracy, fix.horizontalAccuracy <= 25 else { return }
        let zoneID = SpreaderGeometry.zoneID(containing: fix.coordinate, in: zones)
        if zoneID != currentZoneID { currentZoneID = zoneID }
    }
}

#if DEBUG
#Preview("Mode Pemupukan") {
    let garden = WaypointPreviewData.garden
    SpreaderModeView(garden: garden, zones: WaypointZoning.zones(for: garden.boundary))
}
#endif
