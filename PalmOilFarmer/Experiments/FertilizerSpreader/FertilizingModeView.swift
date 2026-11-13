import CoreLocation
import MapKit
import SwiftUI

/// Mode Pemupukan: the farmer stands in a zone, connects the spreader, and releases one tree's dose per press.
/// Opened from the Pemupukan garden list and from the FindingWaypoint map (tombol "Semprot").
struct FertilizingModeView: View {
    let garden: Garden
    let zones: [WaypointZone]
    private let plans: [Int: FertilizingZonePlan]
    private let separators: [[CLLocationCoordinate2D]]

    @State private var currentZoneID: Int?
    /// Last zone detected from GPS, so a tapped zone is kept until the farmer walks into another one.
    @State private var detectedZoneID: Int?
    @State private var spreader = SpreaderBLEManager()
    @State private var location = WaypointLocationSession()
    @State private var camera: MapCameraPosition = .automatic
    @State private var followsUser = false
    /// Trees fertilized in this session, per zone. Counted only when every pulse of a dose was sent.
    @State private var fertilizedTrees: [Int: Int] = [:]
    @Environment(\.dismiss) private var dismiss

    init(garden: Garden, zones: [WaypointZone], initialZoneID: Int?) {
        self.garden = garden
        self.zones = zones
        plans = FertilizingZonePlan.sample(for: zones)
        separators = FertilizingGeometry.separators(for: zones)
        _currentZoneID = State(initialValue: initialZoneID)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let fix = location.freshLocation(at: context.date)
            VStack(spacing: -32) {
                FertilizingMapView(
                    garden: garden, zones: zones, separators: separators, plans: plans,
                    currentZoneID: currentZoneID, fix: fix,
                    camera: $camera, followsUser: $followsUser,
                    onSelectZone: selectZone
                )
                .ignoresSafeArea(edges: .top)
                .frame(maxHeight: .infinity)

                FertilizingPanel(
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
            FertilizingHeader(onBack: { dismiss() }, backDisabled: spreader.isRunning)
        }
        .background(FertilizingPalette.panel.ignoresSafeArea())
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

    private func selectZone(_ id: Int) {
        guard !spreader.isRunning else { return }
        currentZoneID = id
    }

    /// Counts one tree when a dose ran to the end (not stopped or disconnected).
    private func count(_ finished: FinishedDispense?) {
        guard let finished, finished.completed else { return }
        withAnimation { fertilizedTrees[finished.zoneID, default: 0] += 1 }
    }

    /// Updates "Zona saat ini" when GPS shows the farmer entered another zone; never while dispensing.
    private func followLocation() {
        guard let fix = location.freshLocation(at: .now) else { return }
        if followsUser {
            camera = .region(MKCoordinateRegion(center: fix.coordinate, latitudinalMeters: 120, longitudinalMeters: 120))
        }
        guard !spreader.isRunning, !location.reducedAccuracy, fix.horizontalAccuracy <= 25,
              let zoneID = FertilizingGeometry.zoneID(containing: fix.coordinate, in: zones),
              zoneID != detectedZoneID else { return }
        detectedZoneID = zoneID
        currentZoneID = zoneID
    }
}

#if DEBUG
#Preview("Mode Pemupukan") {
    let garden = WaypointPreviewData.garden
    FertilizingModeView(garden: garden, zones: WaypointZoning.zones(for: garden.boundary), initialZoneID: 2)
}
#endif
