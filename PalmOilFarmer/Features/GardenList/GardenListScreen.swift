import SwiftUI

struct GardenListScreen: View {
    var gardens: [Garden] = []
    /// When supplied, this repository provides the gardens shown by the list.
    /// Otherwise the screen uses the `gardens` value passed by its app owner.
    var repository: (any GardenListRepository)? = nil
    var drafts: [MappingDraft] = []
    var onResumeDraft: (MappingDraft) -> Void = { _ in }
    var downloads: [MapDownloadItem] = []
    var onSelectDownload: (MapDownloadItem) -> Void = { _ in }
    var referenceMapImage: String? = nil
    var previewMetrics: GardenDisplayMetrics? = nil
    var onSelectGarden: (Garden) -> Void = { _ in }
    let onRegisterGarden: () -> Void

    private var displayedGardens: [Garden] { repository?.gardens ?? gardens }

    var body: some View {
        VStack(spacing: 0) {
            Text("Kebun")
                .font(.largeTitle.bold())
                .foregroundStyle(displayedGardens.isEmpty ? KropsTheme.titleText : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(KropsTheme.Spacing.screen)

            if displayedGardens.isEmpty && downloads.isEmpty && drafts.isEmpty {
                GeometryReader { geometry in
                    ScrollView {
                        EmptyStateView(
                            title: "Belum ada kebun terdaftar",
                            message: "Gambar batas kebun di peta untuk mulai memantau kondisi dan hasil panen."
                        ) {
                            SeedlingIcon()
                        }
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(drafts) { draft in
                            Button { onResumeDraft(draft) } label: {
                                MappingDraftCard(draft: draft)
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(displayedGardens) { garden in
                            Button {
                                onSelectGarden(garden)
                            } label: {
                                GardenCard(garden: garden, referenceImage: referenceMapImage, metrics: previewMetrics)
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(downloads) { item in
                            Button {
                                onSelectDownload(item)
                            } label: {
                                MapDownloadCard(location: item.location, state: item.state,
                                                referenceMapImage: item.referenceMapImage)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, KropsTheme.Spacing.screen)
                    .padding(.bottom, 12)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(KropsTheme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryActionButton(title: "Daftarkan Kebun", systemImage: "plus", action: onRegisterGarden)
                .padding(.horizontal, 34)
                .padding(.bottom, 2)
                .padding(.top, 12)
                .background(KropsTheme.background)
        }
    }
}

#Preview("01 · Kebun Kosong") {
    GardenListScreen(onRegisterGarden: {})
}

#Preview("01 · Kebun Dummy") {
    GardenListScreen(repository: DummyGardenListRepository(), onRegisterGarden: {})
}

#if DEBUG
#Preview("01 Copy · Daftar Kebun") {
    GardenListScreen(
        gardens: GardenPreviewData.gardens,
        referenceMapImage: "GardenCardMap",
        previewMetrics: GardenDisplayMetrics(area: "2,4 ha", perimeter: "2324 m"),
        onRegisterGarden: {}
    )
}
#endif
