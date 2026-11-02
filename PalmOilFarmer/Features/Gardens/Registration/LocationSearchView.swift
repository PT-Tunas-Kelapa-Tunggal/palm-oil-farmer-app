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
    @State private var showsPhotoPicker = false
    @AppStorage("garden.location.hasSeenPhotoTip") private var hasSeenPhotoTip = false
    @State private var photoStatus: PhotoStatus
    private let searchLocations: (String) async throws -> [GardenLocation]

    enum PhotoStatus {
        case idle, loading, missingLocation, failed

        var message: String {
            switch self {
            case .idle: "Foto yang diambil di kebun menyimpan data lokasi, sehingga peta dapat langsung diarahkan ke kebun Anda."
            case .loading: "Memeriksa lokasi pada foto…"
            case .missingLocation: "Foto ini tidak menyimpan data lokasi. Coba foto lain yang diambil di kebun."
            case .failed: "Foto tidak dapat dibaca. Coba foto lain."
            }
        }

        var symbol: String {
            switch self {
            case .idle, .loading: "photo.on.rectangle"
            case .missingLocation, .failed: "exclamationmark.circle"
            }
        }
    }

    init(initialQuery: String = "", initialResults: [GardenLocation]? = nil,
         initialPhotoStatus: PhotoStatus = .idle,
         searchLocations: @escaping (String) async throws -> [GardenLocation] = LocationSearchService.search,
         onSelect: @escaping (GardenLocation) -> Void) {
        self.onSelect = onSelect
        _query = State(initialValue: initialQuery)
        _results = State(initialValue: initialResults ?? [])
        _photoStatus = State(initialValue: initialPhotoStatus)
        if let initialResults {
            self.searchLocations = { _ in initialResults }
        } else {
            self.searchLocations = searchLocations
        }
    }

    private var hasQuery: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Temukan Lokasi Kebun", onClose: { dismiss() })
                .overlay(alignment: .trailing) {
                    Button {
                        hasSeenPhotoTip = true
                        showsPhotoPicker = true
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: Circle())
                    .accessibilityLabel("Temukan lokasi dari foto")
                    .padding(.trailing, 12)
                }

            VStack(alignment: .leading, spacing: 8) {
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

                Text("Nama desa, masjid, sekolah, atau simpang jalan yang Anda kenal.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, KropsTheme.Spacing.screen)

            ScrollView {
                VStack(spacing: 8) {
                    if isSearching {
                        ProgressView("Mencari lokasi…").padding()
                    } else if let errorMessage {
                        Text(errorMessage).foregroundStyle(.secondary).padding()
                    } else if hasQuery && results.isEmpty {
                        Text("Tempat tidak ditemukan. Coba nama desa atau tempat lain yang dekat dengan kebun.")
                            .foregroundStyle(.secondary).padding()
                    }

                    if !hasQuery {
                        currentLocationRow
                        if photoStatus == .loading {
                            ProgressView(photoStatus.message).padding()
                        } else if photoStatus == .missingLocation || photoStatus == .failed {
                            VStack(spacing: 12) {
                                Text(photoStatus.message).foregroundStyle(.secondary)
                                Button("Pilih foto lain") { showsPhotoPicker = true }
                            }
                            .padding(16)
                        }
                    }

                    ForEach(results) { location in
                        Button {
                            onSelect(location)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.title3)
                                    .frame(width: 36, height: 36)
                                    .background(GardenFlowStyle.card, in: Circle())
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(location.name).font(.headline)
                                    Text(location.subtitle).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .frame(minHeight: 74)
                            .background(GardenFlowStyle.card, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
                            .contentShape(RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, KropsTheme.Spacing.screen)
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(GardenFlowStyle.background)
        .overlay(alignment: .top) {
            if !hasSeenPhotoTip && !hasQuery {
                photoTip.padding(.horizontal, 16).padding(.top, 68)
            }
        }
        .onChange(of: query) { _, value in
            if !value.isEmpty { hasSeenPhotoTip = true }
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
                let location = await LocationSearchService.location(at: coordinate)
                try Task.checkCancellation()
                onSelect(location)
                dismiss()
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = "Lokasi tidak dapat diperoleh. Periksa izin lokasi dan coba lagi."
            }
            isLocating = false
        }
        .sheet(isPresented: $showsPhotoPicker) {
            GardenPhotoPickerView { coordinate in
                // The sheet must finish closing before this one dismisses.
                Task {
                    try? await Task.sleep(for: .milliseconds(350))
                    onSelect(GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun",
                                            coordinate: coordinate, source: .photo))
                    dismiss()
                }
            }
        }
    }

    private var currentLocationRow: some View {
        Button { isLocating = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(GardenFlowStyle.card, in: Circle())
                VStack(alignment: .leading, spacing: 0) {
                    Text("Gunakan lokasi saat ini").font(.headline)
                    Text(isLocating ? "Mencari lokasi…" : "Jika Anda sedang di kebun")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isLocating { ProgressView() }
            }
            .padding(16)
            .frame(minHeight: 74)
            .background(GardenFlowStyle.card, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
            .contentShape(RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
        }
        .buttonStyle(.plain)
        .disabled(isLocating)
    }

    private var photoTip: some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                hasSeenPhotoTip = true
                showsPhotoPicker = true
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Temukan dari Foto").font(.subheadline.weight(.semibold))
                    Text("Punya foto yang diambil di kebun? Ketuk di sini untuk langsung menemukan lokasinya.")
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                hasSeenPhotoTip = true
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tutup petunjuk foto")
        }
        .padding(12)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
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

#Preview("08 · Cari Alamat Awal") {
    LocationSearchView(onSelect: { _ in })
}

#if DEBUG
#Preview("09 · Cari Alamat Terisi") {
    LocationSearchView(initialQuery: "Dumai", initialResults: [GardenPreviewData.location], onSelect: { _ in })
}
#Preview("06 · Foto Tanpa Lokasi") {
    LocationSearchView(initialPhotoStatus: .missingLocation, onSelect: { _ in })
}
#endif
