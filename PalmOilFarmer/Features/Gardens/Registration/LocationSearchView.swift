import SwiftUI
import PhotosUI

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
    @State private var photo: PhotosPickerItem?
    @State private var isReadingPhoto = false
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
            ScreenHeader(title: "Cari alamat", onClose: { dismiss() })

            HStack {
                TextField("Cari tempat terdekat dari kebun", text: $query)
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

            Text("Nama desa, masjid, sekolah, atau simpang jalan yang Anda kenal.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.vertical, 8)

            ScrollView {
                VStack(spacing: 8) {
                    if isSearching {
                        ProgressView("Mencari lokasi…").padding()
                    } else if let errorMessage {
                        Text(errorMessage).foregroundStyle(.secondary).padding()
                    } else if !query.isEmpty && results.isEmpty {
                        Text("Lokasi tidak ditemukan. Coba nama tempat atau alamat lain.")
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
                                    Text("Gunakan lokasi saat ini").font(.headline)
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

                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        GardenPhotoPickerView(isReadingPhoto: isReadingPhoto, onOpen: {
                            isSearchFocused = false
                        }) { photo = $0 }
                    }
                }
                .padding(.horizontal, KropsTheme.Spacing.screen)
                .padding(.top, 8)
            }
        }
        .task(id: photo) { await readPhoto() }
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
                                        coordinate: GardenCoordinate(coordinate), source: .currentLocation))
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
    private func readPhoto() async {
        guard let photo else { return }
        isReadingPhoto = true
        errorMessage = nil
        defer { isReadingPhoto = false }
        do {
            guard let data = try await photo.loadTransferable(type: Data.self) else {
                errorMessage = "Foto tidak dapat dibaca. Coba foto lain."
                return
            }
            try Task.checkCancellation()
            guard let coordinate = PhotoLocationReader.coordinate(in: data) else {
                errorMessage = "Data lokasi tidak ditemukan. Pilih foto lain atau cari alamat kebun."
                return
            }
            onSelect(GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun",
                                    coordinate: coordinate, source: .photo))
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = "Foto tidak dapat dibaca. Coba foto lain."
        }
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
