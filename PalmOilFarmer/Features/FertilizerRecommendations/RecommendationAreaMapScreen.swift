import SwiftUI
import MapKit
import UIKit

struct RecommendationAreaMapScreen: View {
    let boundary: GardenBoundary
    let areas: [FertilizerAllocationArea]
    let selectedArea: FertilizerAllocationArea
    var mapImageName: String? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var camera: MapCameraPosition = .automatic
    @State private var session = WaypointLocationSession()

    var body: some View {
        Group {
            if let image = bundledImage {
                simulatedMap(image)
            } else {
                liveNavigationMap
            }
        }
    }

    private var bundledImage: UIImage? {
        guard let mapImageName else { return nil }
        let file = URL(fileURLWithPath: mapImageName)
        guard let url = Bundle.main.url(
            forResource: file.deletingPathExtension().lastPathComponent,
            withExtension: file.pathExtension
        ) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private func simulatedMap(_ image: UIImage) -> some View {
        let focus = selectedArea.mapPoint ?? FertilizerMapPoint(x: 0.5, y: 0.5)
        let simulatedLocation = FertilizerMapPoint(
            x: min(0.94, focus.x + 0.055),
            y: min(0.94, focus.y + 0.045)
        )

        return ZoneAnnotatedMap(
            image: image,
            areas: areas,
            highlightedAreaID: selectedArea.id,
            locationPoint: simulatedLocation,
            contentMode: .fill,
            focusPoint: focus
        )
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            ScreenHeader(title: "Navigasi", height: 60, onClose: { dismiss() })
                .foregroundStyle(.white)
                .environment(\.colorScheme, .dark)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 2) {
                Text("200 m")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("Area \(selectedArea.id)")
                    .font(.title3.weight(.bold))
                Text("Posisi dan jarak simulasi")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: 290)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
            .frame(maxWidth: .infinity)
            .padding(.bottom, 12)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var liveNavigationMap: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let fix = session.freshLocation(at: context.date)
            Map(position: $camera) {
                MapPolygon(coordinates: boundary.coordinates)
                    .foregroundStyle(.white.opacity(0.12))
                    .stroke(.white.opacity(0.7), lineWidth: 2)
                ForEach(areas) { area in
                    if let areaBoundary = area.boundary {
                        MapPolygon(coordinates: areaBoundary.coordinates)
                            .foregroundStyle(.white.opacity(area.id == selectedArea.id ? 0.4 : 0.15))
                            .stroke(.white, lineWidth: area.id == selectedArea.id ? 5 : 1)
                        if let point = area.navigationTarget ?? areaBoundary.points.first {
                            Annotation("", coordinate: point.mapCoordinate) {
                                Text(area.id).font(.headline)
                                    .padding(6)
                                    .background(.thinMaterial, in: Capsule())
                            }
                        }
                    }
                }
                if let fix {
                    MapCircle(center: fix.coordinate, radius: fix.horizontalAccuracy)
                        .foregroundStyle(.blue.opacity(0.12))
                    Annotation("Posisi Anda", coordinate: fix.coordinate) {
                        Image(systemName: "figure.walk")
                            .font(.title2).padding(14)
                            .foregroundStyle(.black).background(.white, in: Circle())
                    }
                    if let target = selectedArea.navigationTarget,
                       !session.reducedAccuracy, fix.horizontalAccuracy <= 25 {
                        MapPolyline(coordinates: [fix.coordinate, target.mapCoordinate])
                            .stroke(.white, style: StrokeStyle(lineWidth: 3, dash: [6, 5]))
                    }
                }
            }
            .mapStyle(.imagery)
            .mapControls {}
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                ScreenHeader(title: "Navigasi", onClose: { dismiss() })
                    .foregroundStyle(.white)
                    .environment(\.colorScheme, .dark)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 4) {
                    if let target = selectedArea.navigationTarget, let fix,
                       !session.reducedAccuracy, fix.horizontalAccuracy <= 25 {
                        let distance = fix.distance(from: CLLocation(
                            latitude: target.latitude, longitude: target.longitude))
                        Text(distance.formatted(.number.precision(.fractionLength(0))) + " m")
                            .font(.largeTitle.bold()).monospacedDigit()
                        Text("Area " + selectedArea.id).font(.title2.bold())
                        Text("Arah langsung · Akurasi ±" + fix.horizontalAccuracy.formatted(.number.precision(.fractionLength(0))) + " m")
                            .font(.caption)
                    } else {
                        Text("Area " + selectedArea.id).font(.title2.bold())
                        Text(selectedArea.navigationTarget == nil
                             ? "Titik tujuan belum tersedia dalam laporan."
                             : fix == nil && session.location != nil ? "Menunggu posisi GPS terbaru…" : session.message)
                            .font(.subheadline)
                    }
                    if session.needsSettings || session.reducedAccuracy {
                        Button("Pengaturan") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .multilineTextAlignment(.center)
                .padding(24)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 32))
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
        .onAppear { frameGarden() }
        .task(id: scenePhase) {
            if scenePhase == .active { await session.run() }
        }
    }

    private func frameGarden() {
        let points = (selectedArea.boundary ?? boundary).coordinates.map { MKMapPoint($0) }
        guard let first = points.first else { return }
        let rect = points.dropFirst().reduce(MKMapRect(
            origin: first, size: MKMapSize(width: 1, height: 1))) { partial, point in
            partial.union(MKMapRect(origin: point, size: MKMapSize(width: 1, height: 1)))
        }
        camera = .rect(rect.insetBy(dx: -max(rect.width * 0.5, 100),
                                    dy: -max(rect.height * 0.5, 100)))
    }
}
