import SwiftUI

struct GardenListView: View {
    var gardens: [Garden] = []
    var drafts: [GardenDraft] = []
    var onSelectDraft: (GardenDraft) -> Void = { _ in }
    var onDeleteDraft: (GardenDraft) -> Void = { _ in }
    var downloads: [MapDownloadItem] = []
    var onSelectDownload: (MapDownloadItem) -> Void = { _ in }
    var referenceMapImage: String? = nil
    var previewMetrics: GardenDisplayMetrics? = nil
    var onSelectGarden: (Garden) -> Void = { _ in }
    let onRegisterGarden: () -> Void
    /// Debug builds only: opens developer tools when the title is held.
    var onOpenDeveloperMode: (() -> Void)? = nil
    @State private var selectedFilter = GardenListFilter.all
    @AppStorage(DeveloperSettings.showsHomeFilterKey) private var showsFilter = true

    var body: some View {
        GardenListContent(
            presentation: GardenListPresentation(gardens: gardens, drafts: drafts,
                                                  filter: showsFilter ? selectedFilter : .all),
            selectedFilter: $selectedFilter,
            showsFilter: showsFilter,
            onSelectDraft: onSelectDraft,
            onDeleteDraft: onDeleteDraft,
            downloads: downloads,
            onSelectDownload: onSelectDownload,
            referenceMapImage: referenceMapImage,
            previewMetrics: previewMetrics,
            onSelectGarden: onSelectGarden,
            onRegisterGarden: onRegisterGarden,
            onOpenDeveloperMode: onOpenDeveloperMode
        )
    }
}

struct GardenDraftCard: View {
    let draft: GardenDraft
    var referenceImage: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            LocationMapPreview(location: draft.location, referenceImage: referenceImage)
                .frame(height: 201)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 8) {
                Text("Lanjutkan pemetaan")
                    .font(.title3.weight(.semibold))
                Label(draft.title, systemImage: "location.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .padding(8)
        .background(.background, in: RoundedRectangle(cornerRadius: 24))
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Buka peta untuk memetakan batas kebun")
    }
}

#Preview("01 · Kebun Kosong") {
    GardenListView(onRegisterGarden: {})
}

#if DEBUG
#Preview("Kebun · Draft") {
    GardenListView(drafts: [GardenDraft(location: GardenLocation(
        name: "Malang rapat", subtitle: "Gunung Kijang, Bintan",
        coordinate: GardenPreviewData.location.coordinate
    ))], onRegisterGarden: {})
}
#Preview("01 Copy · Daftar Kebun") {
    GardenListView(
        gardens: GardenPreviewData.gardens,
        referenceMapImage: "GardenCardMap",
        previewMetrics: GardenDisplayMetrics(area: "2,4 ha", perimeter: "2324 m"),
        onRegisterGarden: {}
    )
}
#endif
