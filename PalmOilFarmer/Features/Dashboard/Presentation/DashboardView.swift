import SwiftUI

/// The dashboard screen used by the app, bound to `DashboardViewModel`.
struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel
    @AppStorage(DeveloperSettings.showsHomeFilterKey) private var showsFilter = false

    var body: some View {
        DashboardContentView(
            state: viewModel.viewState(showsFilter: showsFilter),
            selectedFilter: $viewModel.selectedFilter,
            showsFilter: showsFilter,
            onSelectDraft: viewModel.selectDraft,
            onDeleteDraft: { _ = viewModel.deleteDraft($0) },
            onSelectGarden: viewModel.selectGarden,
            onRegisterGarden: viewModel.registerGarden,
            onOpenDeveloperMode: developerModeAction
        )
        .refreshable { await viewModel.refresh() }
        .sheet(isPresented: $viewModel.showsNoConnectionSheet) {
            NoConnectionBottomSheet(onRetry: viewModel.retryPendingGarden)
        }
    }

    private var developerModeAction: (() -> Void)? {
        #if DEBUG
        return viewModel.openDeveloperMode
        #else
        return nil
        #endif
    }
}

#if DEBUG
#Preview("Dashboard") {
    DashboardView(viewModel: DashboardViewModel(
        repository: DummyDashboardRepository(gardens: DashboardPreviewData.gardens),
        onEvent: { _ in }
    ))
}
#endif
