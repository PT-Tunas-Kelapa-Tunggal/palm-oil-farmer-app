import SwiftUI

struct MapDownloadScreen: View {
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

#if DEBUG
#Preview("Download · Progress", traits: .sizeThatFitsLayout) {
    MapDownloadProgressView(state: .referenceProgress).padding().frame(width: 402)
}
#Preview("Unduh Peta · Downloading") {
    MapDownloadScreen(location: GardenPreviewData.location, state: .referenceProgress,
                    onMapBoundary: {}, referenceMapImage: "CodedRegionHero")
}
#Preview("Unduh Peta · Completed") {
    MapDownloadScreen(location: GardenPreviewData.location, state: .completed,
                    onMapBoundary: {}, referenceMapImage: "CodedRegionHero")
}
#Preview("Download Card", traits: .sizeThatFitsLayout) {
    MapDownloadCard(location: GardenPreviewData.location, state: .referenceProgress,
                    referenceMapImage: "CodedRegionCard").padding(16).frame(width: 402)
}
#endif
