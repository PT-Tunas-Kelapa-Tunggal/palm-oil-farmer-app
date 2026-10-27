import SwiftUI

struct WaypointGardenListScreen: View {
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
            WaypointMapScreen(garden: garden, zones: zones)
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
