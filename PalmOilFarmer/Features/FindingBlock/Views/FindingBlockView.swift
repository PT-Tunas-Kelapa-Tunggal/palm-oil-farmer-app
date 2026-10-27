import MapKit
import SwiftUI

struct FindingBlockView: View {
    let garden: Garden
    var report: FertilizerRecommendationReport? = nil
    @State private var blocks: [GardenBlock] = []
    @State private var selectedBlockID = 1
    @State private var showsMap = false
    @State private var showsAreaPicker = false
    @State private var camera: MapCameraPosition = .automatic
    @State private var isLoading = true

    private var selectedBlock: GardenBlock? { blocks.first { $0.id == selectedBlockID } }
    private var periods: [FertilizerAllocationPeriod] {
        guard let block = selectedBlock else { return [] }
        return report?.areas.first { $0.id == block.code }?.periods ?? []
    }

    var body: some View {
        VStack(spacing: 24) {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if let block = selectedBlock {
                Map(position: $camera, interactionModes: []) {
                    BlockMapOverlay(blocks: blocks, selectedID: selectedBlockID)
                }
                .mapStyle(.imagery)
                .mapControls {}
                .frame(height: 206)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Peta alokasi kebun \(garden.name), Area \(block.code) dipilih")

                HStack {
                    Button { showsAreaPicker = true } label: {
                        HStack {
                            Text("Area " + block.code)
                            Image(systemName: "chevron.down").font(.footnote)
                        }
                        .font(.title3.weight(.medium))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .glassEffect(.regular.interactive(), in: Capsule())
                    }
                    Spacer()
                    Button { showsMap = true } label: {
                        Label("Buka Map", systemImage: "figure.walk")
                            .font(.title3)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(KropsTheme.tertiaryFill, in: Capsule())
                    }
                }
                .buttonStyle(.plain)

                if periods.isEmpty {
                    Text("Rincian pupuk per periode belum tersedia.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: 24))
                } else {
                    ForEach(periods) { period in
                        FertilizerAllocationSection(period: period)
                    }
                }
            } else {
                ContentUnavailableView("Area kebun belum tersedia", systemImage: "map",
                    description: Text("Periksa kembali batas kebun."))
            }
        }
        .task(id: garden.boundary.points) {
            isLoading = true
            blocks = BlockZoning.zones(for: garden.boundary)
            if !blocks.contains(where: { $0.id == selectedBlockID }) {
                selectedBlockID = blocks.first?.id ?? 1
            }
            camera = BlockMapCamera.position(for: garden.boundary.coordinates)
            isLoading = false
        }
        .sheet(isPresented: $showsAreaPicker) {
            BlockAreaPickerScreen(blocks: blocks, selectedID: $selectedBlockID)
        }
        .fullScreenCover(isPresented: $showsMap) {
            FindingBlockMapScreen(garden: garden, zones: blocks, selectedZoneID: $selectedBlockID)
        }
    }
}

#if DEBUG
#Preview("Alokasi · Sketch") {
    ScrollView {
        FindingBlockView(garden: GardenPreviewData.completedGarden).padding(16)
    }
    .background(KropsTheme.background)
}
#Preview("Pilih Area · Sketch") {
    @Previewable @State var selectedID = 3
    BlockAreaPickerScreen(blocks: BlockZoning.zones(for: GardenPreviewData.completedGarden.boundary),
                    selectedID: $selectedID)
}
#endif
