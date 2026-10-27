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
            BlockAreaPicker(blocks: blocks, selectedID: $selectedBlockID)
        }
        .fullScreenCover(isPresented: $showsMap) {
            FindingBlockMapView(garden: garden, zones: blocks, selectedZoneID: $selectedBlockID)
        }
    }
}

private struct BlockAreaPicker: View {
    let blocks: [GardenBlock]
    @Binding var selectedID: Int
    @State private var pendingID: Int
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    init(blocks: [GardenBlock], selectedID: Binding<Int>) {
        self.blocks = blocks
        _selectedID = selectedID
        _pendingID = State(initialValue: selectedID.wrappedValue)
    }

    private var filteredBlocks: [GardenBlock] {
        blocks.filter { query.isEmpty || $0.code.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Area Kebun", confirmationAction: {
                selectedID = pendingID
                dismiss()
            }, onClose: { dismiss() })
            TextField("Cari kode area", text: $query)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(16)
                .background(KropsTheme.tertiaryFill, in: Capsule())
                .padding(.horizontal, 16)
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredBlocks) { block in
                        Button { pendingID = block.id } label: {
                            HStack(spacing: 16) {
                                BlockAreaThumbnail(block: block)
                                    .frame(width: 68, height: 68)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text("Area " + block.code).font(.title3)
                                Spacer()
                                if pendingID == block.id {
                                    Image(systemName: "checkmark").foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(pendingID == block.id ? .isSelected : [])
                    }
                    if filteredBlocks.isEmpty { ContentUnavailableView.search(text: query) }
                }
                .padding(16)
            }
        }
        .presentationDetents([.large])
    }
}

private struct BlockAreaThumbnail: View {
    let block: GardenBlock

    var body: some View {
        Canvas { context, size in
            let points = block.fragments.flatMap { $0.map { MKMapPoint($0) } }
            guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
                  let minY = points.map(\.y).min(), let maxY = points.map(\.y).max() else { return }
            let scale = min((size.width - 14) / max(maxX - minX, 1),
                            (size.height - 14) / max(maxY - minY, 1))
            func projected(_ coordinate: CLLocationCoordinate2D) -> CGPoint {
                let point = MKMapPoint(coordinate)
                return CGPoint(x: (point.x - (minX + maxX) / 2) * scale + size.width / 2,
                               y: (point.y - (minY + maxY) / 2) * scale + size.height / 2)
            }
            for edge in block.outlineEdges {
                var path = Path()
                path.addLines(edge.map(projected))
                context.stroke(path, with: .color(.black.opacity(0.55)), lineWidth: 1.5)
            }
        }
        .background(Color(white: 0.62))
        .accessibilityHidden(true)
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
    BlockAreaPicker(blocks: BlockZoning.zones(for: GardenPreviewData.completedGarden.boundary),
                    selectedID: $selectedID)
}
#endif
