import SwiftUI

/// Standalone experimental entry point. The production app entry point is unchanged.
struct FindingWaypointFlow: View {
    @State private var store = GardenStore()
    @State private var selectedGardenID: UUID?
    @State private var showsRegistration = false
    @State private var pendingLocation: GardenLocation?
    @State private var mappingLocation: GardenLocation?

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    GardenListScreen(gardens: store.gardens, onSelectGarden: {
                        selectedGardenID = $0.id
                    }) {
                        showsRegistration = true
                    }
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(item: $selectedGardenID) { id in
                        if let garden = store.gardens.first(where: { $0.id == id }) {
                            GardenProfileScreen(garden: garden, onDelete: store.delete, onUpdate: store.update)
                        }
                    }
                }
            }
            Tab("Pemupukan", systemImage: "leaf") {
                NavigationStack {
                    WaypointGardenListScreen(gardens: store.gardens)
                }
            }
        }
        .sheet(isPresented: $showsRegistration, onDismiss: {
            mappingLocation = pendingLocation
            pendingLocation = nil
        }) {
            RegistrationFlow {
                pendingLocation = $0
                showsRegistration = false
            }
        }
        .fullScreenCover(item: $mappingLocation) { location in
            GardenBoundaryScreen(location: location, onSave: store.add)
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
}

#if DEBUG
#Preview("Finding Waypoint — data tersimpan") {
    FindingWaypointFlow()
}

#Preview("Pemupukan — contoh") {
    NavigationStack {
        WaypointGardenListScreen(gardens: [WaypointPreviewData.garden])
    }
}
#endif
