import SwiftUI

/// Value-based dashboard without a view model, for reference previews and the
/// FindingWaypoint experiment. The app itself uses `DashboardView`.
struct DashboardStaticView: View {
    var gardens: [DashboardGarden] = []
    var drafts: [DashboardDraft] = []
    var onSelectDraft: (DashboardDraft) -> Void = { _ in }
    var onDeleteDraft: (DashboardDraft) -> Void = { _ in }
    var downloads: [MapDownloadItem] = []
    var onSelectDownload: (MapDownloadItem) -> Void = { _ in }
    var referenceMapImage: String? = nil
    var previewMetrics: GardenDisplayMetrics? = nil
    var onSelectGarden: (DashboardGarden) -> Void = { _ in }
    let onRegisterGarden: () -> Void
    /// Debug builds only: opens developer tools when the title is held.
    var onOpenDeveloperMode: (() -> Void)? = nil
    @State private var selectedFilter = DashboardFilter.all
    @AppStorage(DeveloperSettings.showsHomeFilterKey) private var showsFilter = false

    var body: some View {
        DashboardContentView(
            state: DashboardViewState(gardens: gardens, drafts: drafts,
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

#Preview("01 · Kebun Kosong") {
    DashboardStaticView(onRegisterGarden: {})
}

#if DEBUG
#Preview("Kebun · Draft") {
    DashboardStaticView(drafts: [DashboardPreviewData.draft], onRegisterGarden: {})
}
#Preview("01 Copy · Daftar Kebun") {
    DashboardStaticView(
        gardens: DashboardPreviewData.gardens,
        referenceMapImage: "GardenCardMap",
        previewMetrics: GardenDisplayMetrics(area: "2,4 ha", perimeter: "2324 m"),
        onRegisterGarden: {}
    )
}
#endif
