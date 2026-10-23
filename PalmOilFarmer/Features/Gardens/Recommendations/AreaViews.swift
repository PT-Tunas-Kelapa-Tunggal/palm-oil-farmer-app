import SwiftUI
import MapKit

/// Satellite map of the garden's areas with the selected area outlined.
struct AllocationAreaMap: View {
    let boundary: GardenBoundary
    let areas: [FertilizerAllocationArea]
    let selectedID: String?
    var showsUser = false
    var position: Binding<MapCameraPosition>? = nil
    /// Tapping inside an area, or on its label, selects it.
    var onSelect: ((String) -> Void)? = nil

    var body: some View {
        MapReader { proxy in
            Group {
                if let position {
                    Map(position: position) { content }
                } else {
                    Map(initialPosition: .rect(AllocationAreaMap.rect(for: boundary)), interactionModes: []) { content }
                }
            }
            .mapStyle(.imagery(elevation: .flat))
            .mapControls {}
            .onTapGesture(coordinateSpace: .local) { location in
                guard let onSelect, let coordinate = proxy.convert(location, from: .local),
                      let area = areas.first(where: { $0.zone?.contains(coordinate) == true }) else { return }
                onSelect(area.id)
            }
        }
        .sensoryFeedback(.selection, trigger: selectedID)
    }

    @MapContentBuilder
    private var content: some MapContent {
        ForEach(areas) { area in
            if let zone = area.zone {
                ForEach(zone.fragments.indices, id: \.self) { index in
                    MapPolygon(coordinates: zone.fragments[index])
                        .foregroundStyle(area.id == selectedID ? KropsTheme.accent.opacity(0.45) : .white.opacity(0.08))
                }
                ForEach(zone.outlineSegments.indices, id: \.self) { index in
                    MapPolyline(coordinates: zone.outlineSegments[index])
                        .stroke(.white.opacity(area.id == selectedID ? 1 : 0.6),
                                lineWidth: area.id == selectedID ? 4 : 1)
                }
                Annotation("", coordinate: zone.destination) {
                    Button { onSelect?(area.id) } label: {
                        Text(area.id)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(onSelect == nil)
                    .accessibilityLabel("Area " + area.id)
                    .accessibilityAddTraits(area.id == selectedID ? .isSelected : [])
                }
                .annotationTitles(.hidden)
            }
        }
        if showsUser {
            UserAnnotation()
        }
    }

    static func rect(for boundary: GardenBoundary) -> MKMapRect {
        let points = boundary.coordinates.map { MKMapPoint($0) }
        guard let first = points.first else { return .world }
        let rect = points.dropFirst().reduce(MKMapRect(origin: first, size: MKMapSize(width: 1, height: 1))) {
            $0.union(MKMapRect(origin: $1, size: MKMapSize(width: 1, height: 1)))
        }
        return rect.insetBy(dx: -rect.width * 0.12, dy: -rect.height * 0.12)
    }
}

extension WaypointZone {
    /// Even-odd ray casting per fragment; fragments are small enough to treat degrees as planar.
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        fragments.contains { fragment in
            var inside = false
            var previous = fragment.last
            for point in fragment {
                if let previous,
                   (point.latitude > coordinate.latitude) != (previous.latitude > coordinate.latitude),
                   coordinate.longitude < (previous.longitude - point.longitude)
                       * (coordinate.latitude - point.latitude) / (previous.latitude - point.latitude) + point.longitude {
                    inside.toggle()
                }
                previous = point
            }
            return inside
        }
    }

    /// Fragments are triangles; edges used by only one fragment form the zone's outline.
    var outlineSegments: [[CLLocationCoordinate2D]] {
        struct Key: Hashable { let latitude: Int64, longitude: Int64 }
        func key(_ coordinate: CLLocationCoordinate2D) -> Key {
            Key(latitude: Int64((coordinate.latitude * 1e8).rounded()),
                longitude: Int64((coordinate.longitude * 1e8).rounded()))
        }
        var counts: [Set<Key>: Int] = [:]
        var edges: [(Set<Key>, [CLLocationCoordinate2D])] = []
        for fragment in fragments {
            for index in fragment.indices {
                let start = fragment[index], end = fragment[(index + 1) % fragment.count]
                let edge: Set<Key> = [key(start), key(end)]
                guard edge.count == 2 else { continue }
                if counts[edge] == nil { edges.append((edge, [start, end])) }
                counts[edge, default: 0] += 1
            }
        }
        return edges.filter { counts[$0.0] == 1 }.map(\.1)
    }
}

struct AreaPickerView: View {
    let areas: [FertilizerAllocationArea]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID: String
    @State private var query = ""

    init(areas: [FertilizerAllocationArea], selectedID: String, onSelect: @escaping (String) -> Void) {
        self.areas = areas
        self.onSelect = onSelect
        _selectedID = State(initialValue: selectedID)
    }

    private var filteredAreas: [FertilizerAllocationArea] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return search.isEmpty ? areas : areas.filter { $0.id.contains(search) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Area Kebun", confirmationAction: {
                onSelect(selectedID)
                dismiss()
            }, onClose: { dismiss() })
            TextField("Cari kode area", text: $query)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(.horizontal, KropsTheme.Spacing.screen)
                .frame(minHeight: 44)
                .background(Color(uiColor: .systemGray6), in: Capsule())
                .padding(.horizontal, KropsTheme.Spacing.screen)
                .padding(.bottom, 8)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filteredAreas) { area in
                        Button { selectedID = area.id } label: {
                            HStack(spacing: 16) {
                                AreaThumbnail(zone: area.zone)
                                    .frame(width: 52, height: 52)
                                    .background(KropsTheme.cardFill, in: RoundedRectangle(cornerRadius: 8))
                                Text("Area " + area.id).font(.body)
                                Spacer()
                                if area.id == selectedID {
                                    Image(systemName: "checkmark").foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(area.id == selectedID ? .isSelected : [])
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}

/// A small outline of one area, scaled to fit its own bounds.
struct AreaThumbnail: View {
    let zone: WaypointZone?

    var body: some View {
        Canvas { context, size in
            guard let zone else { return }
            let points = zone.fragments.flatMap { $0.map { MKMapPoint($0) } }
            guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
                  let minY = points.map(\.y).min(), let maxY = points.map(\.y).max() else { return }
            let scale = min((size.width - 12) / max(maxX - minX, 1), (size.height - 12) / max(maxY - minY, 1))
            var path = Path()
            for fragment in zone.fragments {
                let projected = fragment.map {
                    let point = MKMapPoint($0)
                    return CGPoint(x: (point.x - (minX + maxX) / 2) * scale + size.width / 2,
                                   y: (point.y - (minY + maxY) / 2) * scale + size.height / 2)
                }
                guard let first = projected.first else { continue }
                path.move(to: first)
                projected.dropFirst().forEach { path.addLine(to: $0) }
                path.closeSubpath()
            }
            context.fill(path, with: .color(.secondary.opacity(0.4)))
        }
        .accessibilityHidden(true)
    }
}

/// Guides the farmer on foot to the selected area. The distance is a straight line, not a route.
struct AreaNavigationView: View {
    let boundary: GardenBoundary
    let areas: [FertilizerAllocationArea]
    let selectedID: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = WaypointLocationSession()
    @State private var position: MapCameraPosition
    @State private var isTracking = true

    init(boundary: GardenBoundary, areas: [FertilizerAllocationArea], selectedID: String) {
        self.boundary = boundary
        self.areas = areas
        self.selectedID = selectedID
        _position = State(initialValue: .rect(AllocationAreaMap.rect(for: boundary)))
    }

    private var selectedZone: WaypointZone? {
        areas.first { $0.id == selectedID }?.zone
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let fix = session.freshLocation(at: context.date)
            AllocationAreaMap(boundary: boundary, areas: areas, selectedID: selectedID,
                              showsUser: true, position: $position)
                .ignoresSafeArea()
                .overlay(alignment: .top) {
                    ScreenHeader(title: "Navigasi", onClose: { dismiss() })
                        .foregroundStyle(.white)
                        .environment(\.colorScheme, .dark)
                }
                .overlay(alignment: .bottom) {
                    distanceCard(fix: fix)
                }
        }
        .task(id: isTracking) {
            if isTracking { await session.run() }
        }
        .onChange(of: scenePhase) { _, phase in
            isTracking = phase == .active
        }
    }

    private func distanceCard(fix: CLLocation?) -> some View {
        VStack(spacing: 2) {
            if let fix, let zone = selectedZone {
                let distance = WaypointLocationSession.distance(from: fix, to: zone)
                Text(distance < 1_000
                     ? "\(distance.formatted(.number.precision(.fractionLength(0))))m"
                     : "\((distance / 1_000).formatted(.number.precision(.fractionLength(1))))km")
                    .font(.system(size: 48, weight: .semibold))
                    .monospacedDigit()
            } else {
                Text(session.message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
            }
            Text("Area " + selectedID).font(.title2.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .frame(minWidth: 220)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .combine)
        .padding(.bottom, 24)
    }
}
