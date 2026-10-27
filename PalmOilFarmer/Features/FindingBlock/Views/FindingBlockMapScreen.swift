import CoreLocation
import MapKit
import SwiftUI

struct FindingBlockMapScreen: View {
    let garden: Garden
    let zones: [GardenBlock]
    @Binding var selectedZoneID: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var camera: MapCameraPosition = .automatic
    @State private var session = BlockLocationSession()
    @State private var hasFramedLocation = false

    private var selectedBlock: GardenBlock? { zones.first { $0.id == selectedZoneID } }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let fix = scenePhase == .active ? session.freshLocation(at: context.date) : nil
            Map(position: $camera) {
                BlockMapOverlay(blocks: zones, selectedID: selectedZoneID)
                if let fix {
                    MapCircle(center: fix.coordinate, radius: fix.horizontalAccuracy)
                        .foregroundStyle(.white.opacity(0.12))
                    if let block = selectedBlock, !session.reducedAccuracy, fix.horizontalAccuracy <= 25 {
                        MapPolyline(coordinates: [fix.coordinate, block.destination])
                            .stroke(.white.opacity(0.8), style: StrokeStyle(lineWidth: 3, dash: [6, 5]))
                    }
                    Annotation("Posisi Anda", coordinate: fix.coordinate) {
                        Image(systemName: "figure.walk")
                            .font(.title2)
                            .frame(width: 62, height: 62)
                            .foregroundStyle(.black)
                            .background(.white, in: Circle())
                    }
                    .annotationTitles(.hidden)
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
            .overlay(alignment: .bottom) {
                distanceCard(fix: fix)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            camera = BlockMapCamera.position(for: garden.boundary.coordinates)
        }
        .task(id: scenePhase) {
            if scenePhase == .active { await session.run() }
        }
        .onChange(of: session.location?.timestamp) { _, _ in
            guard !hasFramedLocation, !camera.positionedByUser,
                  let fix = session.freshLocation(at: .now), let block = selectedBlock else { return }
            camera = BlockMapCamera.position(for: block.fragments.flatMap { $0 } + [fix.coordinate])
            hasFramedLocation = true
        }
    }

    private func distanceCard(fix: CLLocation?) -> some View {
        VStack(spacing: 4) {
            if let block = selectedBlock {
                if let fix, !session.reducedAccuracy, fix.horizontalAccuracy <= 25 {
                    let distance = BlockLocationSession.distance(from: fix, to: block)
                    Text(distance < 1_000
                         ? distance.formatted(.number.precision(.fractionLength(0))) + "m"
                         : (distance / 1_000).formatted(.number.precision(.fractionLength(1))) + "km")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .accessibilityLabel("Jarak langsung ke area tujuan")
                    Text("Area " + block.code).font(.title2.bold())
                } else {
                    Text("Area " + block.code).font(.title2.bold())
                    Text(session.reducedAccuracy || (fix?.horizontalAccuracy ?? 0) > 25
                         ? "Menunggu lokasi lebih akurat…"
                         : session.location != nil ? "Menunggu posisi GPS terbaru…" : session.message)
                        .font(.subheadline)
                }
                if session.needsSettings || session.reducedAccuracy {
                    Button("Pengaturan") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                }
            }
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .padding(.horizontal, 32).padding(.vertical, 16)
        .frame(minWidth: 240)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 40))
        .environment(\.colorScheme, .dark)
    }
}

#if DEBUG
#Preview("Navigasi · Sketch") {
    @Previewable @State var selectedID = 3
    FindingBlockMapScreen(garden: GardenPreviewData.completedGarden,
                        zones: BlockZoning.zones(for: GardenPreviewData.completedGarden.boundary),
                        selectedZoneID: $selectedID)
}
#endif
