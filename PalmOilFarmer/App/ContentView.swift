import SwiftUI

struct ContentView: View {
    @State private var store = GardenStore()
    @State private var selectedGardenID: UUID?
    @State private var showsRegistration = false
    @State private var pendingLocation: GardenLocation?
    @State private var mappingLocation: GardenLocation?

    var body: some View {
        NavigationStack {
            GardenListView(gardens: store.gardens, onSelectGarden: { garden in
                selectedGardenID = garden.id
            }) {
                showsRegistration = true
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedGardenID) { id in
                if let garden = store.gardens.first(where: { $0.id == id }) {
                    GardenProfileView(garden: garden, onDelete: store.delete, onUpdate: store.update)
                }
            }
        }
        .sheet(isPresented: $showsRegistration, onDismiss: openMappingIfNeeded) {
            RegistrationIntroView { location in
                pendingLocation = location
                showsRegistration = false
            }
        }
        .fullScreenCover(item: $mappingLocation) { location in
            GardenBoundaryView(location: location) { garden in
                store.add(garden)
            }
        }
        .alert("Data kebun", isPresented: Binding(
            get: { store.errorMessage != nil && mappingLocation == nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("Mengerti", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "test")
        }
    }

    /// Wait until the intro sheet closes before presenting the full-screen map.
    private func openMappingIfNeeded() {
        mappingLocation = pendingLocation
        pendingLocation = nil
    }
}

#Preview {
    ContentView()
}
