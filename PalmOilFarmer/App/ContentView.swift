import SwiftUI

struct ContentView: View {
    @State private var store = GardenStore()
    @State private var selectedGardenID: UUID?
    @State private var showsRegistration = false
    @State private var registrationStep = RegistrationIntroView.Step.guide
    @State private var pendingLocation: GardenLocation?
    @State private var mappingLocation: GardenLocation?
    @State private var reopensSearch = false

    var body: some View {
        NavigationStack {
            GardenListView(
                gardens: store.gardens,
                drafts: store.drafts,
                onSelectDraft: { mappingLocation = $0.location },
                onDeleteDraft: { _ = store.deleteDraft($0) },
                onSelectGarden: { selectedGardenID = $0.id }
            ) {
                registrationStep = .guide
                showsRegistration = true
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedGardenID) { id in
                if let garden = store.gardens.first(where: { $0.id == id }) {
                    GardenProfileView(garden: garden, onDelete: store.delete, onUpdate: store.update)
                }
            }
        }
        .environment(store)
        .sheet(isPresented: $showsRegistration, onDismiss: openMappingIfNeeded) {
            RegistrationIntroView(initialStep: registrationStep) { location in
                pendingLocation = location
                showsRegistration = false
            }
        }
        .fullScreenCover(item: $mappingLocation, onDismiss: reopenSearchIfNeeded) { location in
            GardenBoundaryView(
                location: location,
                onSave: { store.add($0, completingDraft: location.draftID) },
                onSaveDraft: { store.addDraft(GardenDraft(location: $0)) },
                onSearchAgain: { reopensSearch = true }
            )
        }
        .alert("Data kebun", isPresented: Binding(
            get: { store.errorMessage != nil && mappingLocation == nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("Mengerti", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    /// Wait until the intro sheet closes before presenting the full-screen map.
    private func openMappingIfNeeded() {
        mappingLocation = pendingLocation
        pendingLocation = nil
    }

    /// "Cari Lagi" on a photo location returns to the address search.
    private func reopenSearchIfNeeded() {
        guard reopensSearch else { return }
        reopensSearch = false
        registrationStep = .search
        showsRegistration = true
    }
}

#Preview {
    ContentView()
}
