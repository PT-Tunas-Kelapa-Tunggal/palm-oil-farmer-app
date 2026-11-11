import SwiftUI

/// Standalone experimental entry point. The production app entry point is unchanged.
struct FindingWaypointView: View {
    @State private var store = GardenStore()
    @State private var selectedGardenID: UUID?
    @State private var showsRegistration = false
    @State private var pendingLocation: GardenLocation?
    @State private var mappingLocation: GardenLocation?

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    GardenListView(gardens: store.gardens, onSelectGarden: {
                        selectedGardenID = $0.id
                    }) {
                        showsRegistration = true
                    }
                    .toolbar(.hidden, for: .navigationBar)
                    .navigationDestination(item: $selectedGardenID) { id in
                        if let garden = store.gardens.first(where: { $0.id == id }) {
                            GardenProfileScreen(viewModel: GardenProfileFactory(
                                source: GardenProfileRepository(gardens: store),
                                reviewRepository: CloudKitFarmerReviewRepository.shared,
                                reviewRequestFactory: ReviewRequestFactory(submission: SubmitGardenReview(gateway: store))
                            ).makeViewModel(garden: garden))
                        }
                    }
                }
            }
            Tab("Pemupukan", systemImage: "leaf") {
                NavigationStack {
                    WaypointGardenList(gardens: store.gardens)
                }
            }
        }
        .sheet(isPresented: $showsRegistration, onDismiss: {
            mappingLocation = pendingLocation
            pendingLocation = nil
        }) {
            RegistrationIntroView {
                pendingLocation = $0
                showsRegistration = false
            }
        }
        .fullScreenCover(item: $mappingLocation) { location in
            GardenBoundaryView(location: location, onSave: { store.add($0) })
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

struct WaypointGardenList: View {
    let gardens: [Garden]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("EKSPERIMEN", systemImage: "location.north.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Pilih kebun, lalu tuju zona pemupukan.")
                        .font(.title3.weight(.semibold))
                    Text("6 zona otomatis • Peta online")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if gardens.isEmpty {
                    ContentUnavailableView("Belum ada kebun", systemImage: "leaf",
                        description: Text("Daftarkan dan petakan kebun melalui tab Home."))
                }
                ForEach(gardens) { garden in
                    WaypointGardenCard(garden: garden)
                }
            }
            .padding()
        }
        .background(KropsTheme.background)
        .navigationTitle("Pemupukan")
    }
}

private struct WaypointGardenCard: View {
    let garden: Garden
    @State private var zones: [WaypointZone] = []

    var body: some View {
        NavigationLink {
            WaypointMapView(garden: garden, zones: zones)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                WaypointZoneThumbnail(zones: zones)
                    .frame(height: 180)
                    .clipped()
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(garden.name).font(.headline)
                        Text(garden.locationName).font(.subheadline).foregroundStyle(.secondary)
                        Text(zones.count == 6 ? "6 zona • Pilih tujuan" : "Batas kebun belum dapat dibagi")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding([.horizontal, .bottom])
            }
            .background(.background, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
        }
        .buttonStyle(.plain)
        .disabled(zones.count != 6)
        .task(id: garden.boundary.points) {
            zones = WaypointZoning.zones(for: garden.boundary)
        }
    }
}

#if DEBUG
#Preview("Finding Waypoint — data tersimpan") {
    FindingWaypointView()
}

#Preview("Pemupukan — contoh") {
    NavigationStack {
        WaypointGardenList(gardens: [WaypointPreviewData.garden])
    }
}
#endif
