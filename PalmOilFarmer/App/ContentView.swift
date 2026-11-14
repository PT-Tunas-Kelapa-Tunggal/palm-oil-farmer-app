import SwiftUI

struct ContentView: View {
    @Namespace private var fertilizerScheduleTransition
    @State private var store: GardenStore
    @State private var dashboardViewModel: DashboardViewModel
    @State private var coordinator: AppCoordinator
    private let registrationFactory: GardenRegistrationFactory
    private let mappingFactory: GardenMappingFactory
    private let profileFactory: GardenProfileFactory

    init(store: GardenStore, dashboardViewModel: DashboardViewModel, coordinator: AppCoordinator,
         registrationFactory: GardenRegistrationFactory, mappingFactory: GardenMappingFactory,
         profileFactory: GardenProfileFactory) {
        _store = State(initialValue: store)
        _dashboardViewModel = State(initialValue: dashboardViewModel)
        _coordinator = State(initialValue: coordinator)
        self.registrationFactory = registrationFactory
        self.mappingFactory = mappingFactory
        self.profileFactory = profileFactory
    }

    var body: some View {
        @Bindable var coordinator = coordinator
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack(path: $coordinator.path) {
                    DashboardView(viewModel: dashboardViewModel)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                                .toolbar(.hidden, for: .tabBar)
                        }
                }
                .task {
                    await dashboardViewModel.refresh()
                }
            }
            Tab("Pemupukan", systemImage: "leaf") {
                NavigationStack {
                    WaypointGardenList(gardens: store.gardens)
                }
            }
        }
        .environment(store)
        .environment(coordinator)
        .sheet(item: $coordinator.registrationSheet, onDismiss: coordinator.registrationDidDismiss) { sheet in
            RegistrationIntroView(viewModel: registrationFactory.makeViewModel(
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
                GardenProfileScreen(
                    viewModel: profileFactory.makeViewModel(garden: garden),
                    onOpenRequestAssessment: {
                        coordinator.openRequestAssessment(id)
                    },
                    onOpenResultOverview: {
                        coordinator.openResultOverview(gardenId: id.uuidString)
                    },
                    onOpenNutrientCondition: {
                        coordinator.openNutrientCondition(gardenId: id.uuidString)
                    },
                    onOpenFertilizerEstimation: {
                        coordinator.openFertilizerEstimation(gardenId: id.uuidString)
                    }
                )
            } else {
                ContentUnavailableView("Kebun Tidak Ditemukan", systemImage: "leaf.fill")
            }
        case .requestAssessment(let id):
            if let garden = store.gardens.first(where: { $0.id == id }) {
                AssessmentRequestFlow(
                    gardenID: garden.id,
                    gardenName: garden.name,
                    areaHectares: max(garden.boundary.areaHectares, 0.1),
                    contactRepository: DeviceAssessmentContactRepository(),
                    submissionRepository: CloudKitAssessmentSubmissionRepository(gardenStore: store),
                    onSubmitted: {},
                    onClose: {
                        coordinator.pop()
                    }
                )
            } else {
                ContentUnavailableView("Kebun Tidak Ditemukan", systemImage: "leaf.fill")
            }
        case .resultOverview(let gardenId):
            ResultOverviewView(
                viewModel: ResultOverviewViewModel(
                    repository: CloudKitResultOverviewRepository(
                        containerIdentifier: AppConfiguration.cloudKitContainerIdentifier
                    ),
                    farmGreenIndexRepository: CloudKitFarmGreenIndexRepository(
                        containerIdentifier: AppConfiguration.cloudKitContainerIdentifier,
                        loadsOrthomosaicImage: true
                    ),
                    gardenId: gardenId,
                    gardenName: store.gardens.first(where: { $0.id.uuidString == gardenId })?.name,
                    locationName: store.gardens.first(where: { $0.id.uuidString == gardenId })?.locationName
                ),
                onBack: {
                    coordinator.pop()
                },
                onOpenFertilizerSchedule: {
                    coordinator.openFertilizerSchedule(gardenId: gardenId)
                },
                fertilizerScheduleTransitionNamespace: fertilizerScheduleTransition,
                onOpenNutrientCondition: {
                    coordinator.openNutrientCondition(gardenId: gardenId)
                },
                onOpenFarmGreenness: {
                    coordinator.openFarmGreenIndex(gardenId: gardenId)
                },
                onOpenFertilizerEstimation: {
                    coordinator.openFertilizerEstimation(gardenId: gardenId)
                }
            )
        case .fertilizerSchedule(let gardenId):
            if let gardenID = UUID(uuidString: gardenId) {
                FertilizerScheduleView(
                    viewModel: FertilizerScheduleViewModel(
                        gardenID: gardenID,
                        repository: CloudKitFertilizerScheduleRepository(
                            containerIdentifier: AppConfiguration.cloudKitContainerIdentifier
                        )
                    ),
                    mapRepository: CloudKitFertilizingMapRepository(
                        containerIdentifier: AppConfiguration.cloudKitContainerIdentifier
                    )
                )
                .navigationTransition(.zoom(sourceID: gardenId, in: fertilizerScheduleTransition))
            } else {
                ContentUnavailableView("Kebun Tidak Ditemukan", systemImage: "leaf.fill")
            }
        case .nutrientCondition(let gardenId):
            NutrientConditionView(
                viewModel: NutrientConditionViewModel(
                    repository: CloudKitNutrientConditionRepository(
                        containerIdentifier: AppConfiguration.cloudKitContainerIdentifier
                    ),
                    gardenId: gardenId
                ),
                onBack: {
                    coordinator.pop()
                },
                onOpenFertilizerEstimation: {
                    coordinator.openFertilizerEstimation(gardenId: gardenId)
                }
            )
        case .farmGreenIndex(let gardenId):
            FarmGreenIndexView(
                viewModel: FarmGreenIndexViewModel(
                    gardenId: gardenId,
                    repository: CloudKitFarmGreenIndexRepository(
                        containerIdentifier: AppConfiguration.cloudKitContainerIdentifier,
                        loadsOrthomosaicImage: true
                    )
                ),
                onBack: {
                    coordinator.pop()
                }
            )
        case .fertilizerEstimation(let gardenId):
            FertilizerEstimationView(
                viewModel: FertilizerEstimationViewModel(
                    repository: CloudKitFertilizerEstimationRepository(
                        containerIdentifier: AppConfiguration.cloudKitContainerIdentifier
                    ),
                    gardenId: gardenId
                ),
                onBack: {
                    coordinator.pop()
                }
            )
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
                dashboardViewModel: dependencies.dashboardViewModel,
                coordinator: dependencies.coordinator,
                registrationFactory: dependencies.registrationFactory,
                mappingFactory: dependencies.mappingFactory,
                profileFactory: dependencies.profileFactory)
        .environment(\.farmerReviewRepository, dependencies.reviewRepository)
}
#endif
