import SwiftUI

/// Production MVVM entry point. GardenListView retains the value/callback API
/// used by existing reference screens and the standalone experiment.
struct GardenListScreen: View {
    @Bindable var viewModel: GardenListViewModel
    @AppStorage(DeveloperSettings.showsHomeFilterKey) private var showsFilter = true

    var body: some View {
        GardenListContent(
            presentation: viewModel.presentation(showsFilter: showsFilter),
            selectedFilter: $viewModel.selectedFilter,
            showsFilter: showsFilter,
            onSelectDraft: viewModel.selectDraft,
            onDeleteDraft: { _ = viewModel.deleteDraft($0) },
            onSelectGarden: viewModel.selectGarden,
            onRegisterGarden: viewModel.registerGarden,
            onOpenDeveloperMode: developerModeAction
        )
        .refreshable { await viewModel.refresh() }
    }

    private var developerModeAction: (() -> Void)? {
        #if DEBUG
        return viewModel.openDeveloperMode
        #else
        return nil
        #endif
    }
}
