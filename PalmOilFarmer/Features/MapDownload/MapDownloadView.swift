import SwiftUI

struct MapDownloadItem: Identifiable {
    let id: UUID
    let location: GardenLocation
    let state: MapDownloadState
    var referenceMapImage: String? = nil
}

enum MapDownloadState {
    case downloading(progress: Double, receivedMB: Int, totalMB: Int, remaining: String)
    case completed
    case failed(String)

    static let referenceProgress = MapDownloadState.downloading(
        progress: 0.4, receivedMB: 48, totalMB: 120, remaining: "sekitar 3 menit lagi"
    )
}

struct MapDownloadProgressView: View {
    let state: MapDownloadState
    var usesCardBackground = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch state {
            case let .downloading(progress, received, total, remaining):
                Text("Sedang mengunduh peta").font(.headline)
                let fraction = progress.isFinite ? min(max(progress, 0), 1) : 0
                HStack(spacing: 8) {
                    ProgressView(value: fraction)
                        .tint(.secondary)
                        .accessibilityLabel("Unduhan peta")
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                        .font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                }
                HStack {
                    Text("\(received) MB dari \(total) MB")
                    Spacer()
                    Text(remaining)
                }
                .font(.footnote).foregroundStyle(.secondary)
            case .completed:
                Image(systemName: "checkmark.icloud.fill").font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Peta berhasil diunduh").font(.headline)
                    Text("Peta kini dapat dibuka di kebun tanpa sinyal internet.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            case .failed(let message):
                Label("Peta belum terunduh", systemImage: "exclamationmark.icloud")
                    .font(.headline)
                Text(message).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, usesCardBackground ? 16 : 8)
        .background(usesCardBackground ? KropsTheme.cardFill : .clear, in: RoundedRectangle(cornerRadius: 24))
    }
}

struct MapDownloadView: View {
    let location: GardenLocation
    let state: MapDownloadState
    let onMapBoundary: () -> Void
    var referenceMapImage: String? = nil
    @Environment(\.dismiss) private var dismiss

    private var locationTitle: String {
        let region = location.subtitle.components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return region.isEmpty || region == location.name ? location.name : "\(location.name), \(region)"
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    MapHeroView(title: locationTitle, topInset: geometry.safeAreaInsets.top,
                                onBack: { dismiss() }) {
                        if let referenceMapImage {
                            Image(referenceMapImage).resizable().scaledToFill()
                        } else {
                            LocationMapPreview(location: location)
                        }
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        MapDownloadProgressView(state: state)
                        if case .downloading = state {
                            Text("Anda dapat keluar dari halaman ini. Pengunduhan tetap berjalan dan Anda akan diberi tahu setelah selesai.")
                                .font(.footnote).foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                        }
                    }
                    .padding(16)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if case .completed = state {
                PrimaryActionButton(title: "Petakan Batas Kebun", action: onMapBoundary)
                    .padding(.horizontal, 24).padding(.vertical, 8)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct MapDownloadCard: View {
    let location: GardenLocation
    let state: MapDownloadState
    var referenceMapImage: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let referenceMapImage {
                    Image(referenceMapImage).resizable().scaledToFill()
                } else {
                    LocationMapPreview(location: location)
                }
            }
            .frame(height: 201)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
            MapDownloadProgressView(state: state, usesCardBackground: false).background(.background)
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
    }
}

#if DEBUG
#Preview("Download · Progress", traits: .sizeThatFitsLayout) {
    MapDownloadProgressView(state: .referenceProgress).padding().frame(width: 402)
}
#Preview("Unduh Peta · Downloading") {
    MapDownloadView(location: GardenPreviewData.location, state: .referenceProgress,
                    onMapBoundary: {}, referenceMapImage: "CodedRegionHero")
}
#Preview("Unduh Peta · Completed") {
    MapDownloadView(location: GardenPreviewData.location, state: .completed,
                    onMapBoundary: {}, referenceMapImage: "CodedRegionHero")
}
#Preview("Download Card", traits: .sizeThatFitsLayout) {
    MapDownloadCard(location: GardenPreviewData.location, state: .referenceProgress,
                    referenceMapImage: "CodedRegionCard").padding(16).frame(width: 402)
}
#endif
