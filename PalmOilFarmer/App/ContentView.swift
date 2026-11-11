import SwiftUI

struct ContentView: View {
    @State private var store: GardenStore
    @State private var listViewModel: GardenListViewModel
    @State private var coordinator: AppCoordinator
    private let registrationFactory: GardenRegistrationFactory
    private let mappingFactory: GardenMappingFactory
    private let profileFactory: GardenProfileFactory

    init(store: GardenStore, listViewModel: GardenListViewModel, coordinator: AppCoordinator,
         registrationFactory: GardenRegistrationFactory, mappingFactory: GardenMappingFactory,
         profileFactory: GardenProfileFactory) {
        _store = State(initialValue: store)
        _listViewModel = State(initialValue: listViewModel)
        _coordinator = State(initialValue: coordinator)
        self.registrationFactory = registrationFactory
        self.mappingFactory = mappingFactory
        self.profileFactory = profileFactory
    }

    var body: some View {
        @Bindable var coordinator = coordinator
        NavigationStack(path: $coordinator.path) {
            GardenListScreen(viewModel: listViewModel)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .task {
            await listViewModel.refresh()
        }
        .environment(store)
        .sheet(item: $coordinator.registrationSheet, onDismiss: coordinator.registrationDidDismiss) { sheet in
            RegistrationIntroView(flow: registrationFactory.makeFlow(
                initialStep: sheet == .guide ? .guide : .search,
                onLocate: coordinator.locatedGarden, onCancel: coordinator.cancelRegistration
            ))
        }
        .fullScreenCover(item: $coordinator.mappingLocation, onDismiss: coordinator.mappingDidDismiss) { location in
            GardenBoundaryView(viewModel: mappingFactory.makeViewModel(location: location, onFinish: coordinator.mappingFinished))
        }
        .alert("Data kebun", isPresented: Binding(
            get: { store.errorMessage != nil && coordinator.mappingLocation == nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("Mengerti", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .gardenProfile(let id):
            if let garden = store.gardens.first(where: { $0.id == id }) {
                GardenProfileScreen(flow: profileFactory.makeFlow(garden: garden))
            }
        #if DEBUG
        case .developerMode:
            DeveloperModeView(gardenCount: store.gardens.count, draftCount: store.drafts.count) {
                coordinator.returnHome()
                store.eraseAll()
            }
        #endif
        }
    }
}

#if DEBUG
#Preview {
    let dependencies = AppDependencies.preview()
    ContentView(store: dependencies.gardenStore,
                listViewModel: dependencies.gardenListViewModel,
                coordinator: dependencies.coordinator,
                registrationFactory: dependencies.registrationFactory,
                mappingFactory: dependencies.mappingFactory,
                profileFactory: dependencies.profileFactory)
        .environment(\.farmerReviewRepository, dependencies.reviewRepository)
}
#endif
