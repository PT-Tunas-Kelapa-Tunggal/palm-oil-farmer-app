import SwiftUI

struct LocationSearchView: View {
    let onSelect: (GardenLocation) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query: String
    @State private var results: [GardenLocation]
    @State private var isSearching = false
    @State private var errorMessage: String?
    @FocusState private var isSearchFocused: Bool
    @State private var locationProvider = CurrentLocationProvider()
    @State private var isLocating = false
    var currentLocationSubtitle = "Gunakan lokasi perangkat"
    private let searchLocations: (String) async throws -> [GardenLocation]

    init(initialQuery: String = "", initialResults: [GardenLocation]? = nil,
         searchLocations: @escaping (String) async throws -> [GardenLocation] = LocationSearchService.search,
         onSelect: @escaping (GardenLocation) -> Void) {
        self.onSelect = onSelect
        _query = State(initialValue: initialQuery)
        _results = State(initialValue: initialResults ?? [])
        if let initialResults {
            self.searchLocations = { _ in initialResults }
        } else {
            self.searchLocations = searchLocations
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Cari Kota/Kabupaten", onClose: { dismiss() })

            HStack {
                TextField("Cari Kabupaten/Kota, Pulau", text: $query)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                if !query.isEmpty {
                    Button("Hapus pencarian", systemImage: "xmark.circle.fill") { query = "" }
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, KropsTheme.Spacing.screen)
            .frame(minHeight: 52)
            .background(Color(uiColor: .systemGray6), in: Capsule())
            .padding(.horizontal, KropsTheme.Spacing.screen)

            ScrollView {
                VStack(spacing: 8) {
                    if isSearching {
                        ProgressView("Mencari lokasi…").padding()
                    } else if let errorMessage {
                        Text(errorMessage).foregroundStyle(.secondary).padding()
                    } else if !query.isEmpty && results.isEmpty {
                        Text("Lokasi tidak ditemukan. Coba nama kabupaten atau kota lain.")
                            .foregroundStyle(.secondary).padding()
                    }

                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button { isLocating = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                    .font(.title2)
                                    .frame(width: 36, height: 36)
                                    .background(KropsTheme.tertiaryFill, in: Circle())
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Lokasi saat ini").font(.headline)
                                    Text(isLocating ? "Mencari lokasi…" : currentLocationSubtitle)
                                        .font(.subheadline)
                                }
                                Spacer()
                                if isLocating { ProgressView() }
                            }
                            .foregroundStyle(.secondary)
                            .padding(16)
                            .frame(minHeight: 74)
                            .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
                        }
                        .buttonStyle(.plain)
                        .disabled(isLocating)
                    }
                    ForEach(results) { location in
                        Button {
                            onSelect(location)
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "map.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 36, height: 36)
                                    .background(KropsTheme.tertiaryFill, in: Circle())
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(location.name).font(.headline)
                                    Text(location.subtitle).font(.subheadline)
                                }
                                .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(16)
                            .frame(minHeight: 74)
                            .background(KropsTheme.tertiaryFill, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Cari kabupaten atau kota tempat kebun berada. Koneksi internet diperlukan untuk mencari dan memuat peta.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(uiColor: .systemGray6).opacity(0.4), in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
                }
                .padding(.horizontal, KropsTheme.Spacing.screen)
                .padding(.top, 8)
            }
        }
        .task { isSearchFocused = true }
        .task(id: query) {
            await search()
        }
        .task(id: isLocating) {
            guard isLocating else { return }
            do {
                let coordinate = try await locationProvider.coordinate()
                try Task.checkCancellation()
                onSelect(GardenLocation(name: "Lokasi saat ini", subtitle: "Lokasi perangkat",
                                        coordinate: GardenCoordinate(coordinate)))
                dismiss()
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = "Lokasi tidak dapat diperoleh. Periksa izin lokasi dan coba lagi."
            }
            isLocating = false
        }
        .presentationDetents([.large])
    }

    @MainActor
    private func search() async {
        results = []
        errorMessage = nil
        let searchText = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else {
            isSearching = false
            return
        }
        isSearching = true
        do {
            try await Task.sleep(for: .milliseconds(350))
            let locations = try await searchLocations(searchText)
            try Task.checkCancellation()
            results = locations
            isSearching = false
        } catch {
            guard !Task.isCancelled else { return }
            isSearching = false
            errorMessage = "Pencarian gagal. Periksa koneksi internet lalu coba lagi."
        }
    }
}

#Preview("08 · Cari Kabupaten Awal") {
    LocationSearchView(onSelect: { _ in })
}

#if DEBUG
#Preview("09 · Cari Kabupaten Terisi") {
    LocationSearchView(initialQuery: "Dumai", initialResults: [GardenPreviewData.location], onSelect: { _ in })
}
#endif
