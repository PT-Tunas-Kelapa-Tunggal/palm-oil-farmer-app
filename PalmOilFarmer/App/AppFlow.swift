import SwiftUI

struct AppFlow: View {
    @State private var store = GardenStore()
    @State private var dummyRepository = DummyGardenListRepository()
    @State private var draftStore = MappingDraftStore()
    @State private var selectedGardenID: UUID?
    @State private var showsRegistration = false
    @State private var pendingLocation: GardenLocation?
    @State private var mappingDraft: MappingDraft?
    @State private var retrySearch = false

    var body: some View {
        NavigationStack {
            GardenListScreen(
                // To show saved gardens, pass `gardens: store.gardens` and remove
                // the repository argument.
                repository: dummyRepository,
                drafts: draftStore.drafts.filter { draft in !store.gardens.contains { $0.id == draft.id } },
                onResumeDraft: { mappingDraft = $0 },
                onSelectGarden: { garden in selectedGardenID = garden.id }
            ) {
                retrySearch = false
                showsRegistration = true
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedGardenID) { id in
                if let garden = dummyRepository.gardens.first(where: { $0.id == id }) {
                    let recommendationResult = try? dummyRepository.loadAnalysisResult(for: id)
                    GardenProfileScreen(
                        garden: garden,
                        recommendationResult: recommendationResult,
                        onDelete: { dummyRepository.delete($0) },
                        onUpdateReview: { dummyRepository.updateReview($0, for: id) },
                        onUpdate: { dummyRepository.update($0) }
                    )
                } else if let garden = store.gardens.first(where: { $0.id == id }) {
                    GardenProfileScreen(garden: garden, onDelete: store.delete,
                                      onUpdateReview: { store.updateReview($0, for: id) }, onUpdate: store.update)
                }
            }
        }
        .sheet(isPresented: $showsRegistration, onDismiss: openMappingIfNeeded) {
            RegistrationFlow(initialStep: retrySearch ? .address : .guide) { location in
                pendingLocation = location
                showsRegistration = false
            }
        }
        .fullScreenCover(item: $mappingDraft, onDismiss: {
            if retrySearch { showsRegistration = true }
        }) { draft in
            GardenBoundaryScreen(location: draft.location, initialBoundary: draft.boundary,
                               resumesDraft: draftStore.drafts.contains { $0.id == draft.id },
                               onDefer: draftStore.save, onSearchAgain: { retrySearch = true }) { garden in
                guard dummyRepository.add(garden) else { return false }
                _ = draftStore.remove(id: draft.id)
                return true
            }
        }
        .alert("Data kebun", isPresented: Binding(
            get: { (store.errorMessage ?? draftStore.errorMessage) != nil && mappingDraft == nil },
            set: {
                if !$0 {
                    store.errorMessage = nil
                    draftStore.errorMessage = nil
                }
            }
        )) {
            Button("Mengerti", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? draftStore.errorMessage ?? "")
        }
    }

    private func openMappingIfNeeded() {
        guard let pendingLocation else { return }
        retrySearch = false
        mappingDraft = MappingDraft(location: pendingLocation, boundary: GardenBoundary())
        self.pendingLocation = nil
    }
}

#Preview {
    AppFlow()
}
