import SwiftUI

/// Search page layout without state, so previews stay deterministic.
struct LocationSearchContent: View {
    @Binding var query: String
    var isSearchFocused: FocusState<Bool>.Binding
    let results: [GardenLocation]
    var isSearching = false
    var isLocating = false
    var errorMessage: String? = nil
    let onSelect: (GardenLocation) -> Void
    let onCurrentLocation: () -> Void
    let onPhoto: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RegistrationHeader(title: "Cari Lokasi Kebun", onClose: onClose)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.title2).foregroundStyle(.secondary)
                    TextField("Cari patokan terdekat", text: $query)
                        .focused(isSearchFocused)
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Cari patokan terdekat")
                    if !query.isEmpty {
                        Button("Hapus pencarian", systemImage: "xmark.circle.fill") { query = "" }
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.tertiary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, query.isEmpty ? 16 : 4)
                .frame(minHeight: 52)
                .glassEffect(.regular, in: Capsule())
                Text("Contohnya nama desa, masjid, sekolah, atau simpang jalan di dekat kebun.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }
            .padding(.horizontal, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if isSearching {
                        ProgressView("Mencari lokasi…").padding(16)
                    }
                    if let errorMessage {
                        Text(errorMessage).font(.body).foregroundStyle(.secondary).padding(16)
                    } else if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                && !isSearching && results.isEmpty {
                        Text("Tempat tidak ditemukan. Coba nama desa atau tempat lain yang dekat dengan kebun.")
                            .font(.body).foregroundStyle(.secondary).padding(16)
                    }
                    ForEach(results) { location in
                        LocationOptionRow(title: location.name, subtitle: location.subtitle,
                                                symbol: "mappin", isBrand: false) { onSelect(location) }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Belum tahu alamat kebun").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
                        Text("Pilih cara yang paling mudah untuk Anda.")
                            .font(.body).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, results.isEmpty ? 0 : 12)
                    .padding(.bottom, 8)
                    LocationOptionRow(title: "Saya sedang di kebun",
                                            subtitle: isLocating ? "Mencari lokasi…" : "Lokasi kebun diambil dari posisi Anda saat ini.",
                                            symbol: "location.fill", isLoading: isLocating,
                                            action: onCurrentLocation)
                    LocationOptionRow(title: "Saya punya foto kebun",
                                            subtitle: "Lokasi kebun dicari dari foto yang diambil di sana.",
                                            symbol: "photo.fill",
                                            action: onPhoto)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .background(RegistrationStyle.background)
        .presentationBackground(RegistrationStyle.background)
    }
}

#if DEBUG
/// Canvas wrapper that owns the query text and focus state `LocationSearchContent` binds to.
struct LocationSearchContentPreview: View {
    @State private var query: String
    @FocusState private var isFocused: Bool
    private let results: [GardenLocation]
    private let isSearching: Bool
    private let isLocating: Bool
    private let errorMessage: String?

    init(query: String = "", results: [GardenLocation] = [], isSearching: Bool = false,
         isLocating: Bool = false, errorMessage: String? = nil) {
        _query = State(initialValue: query)
        self.results = results
        self.isSearching = isSearching
        self.isLocating = isLocating
        self.errorMessage = errorMessage
    }

    var body: some View {
        LocationSearchContent(
            query: $query, isSearchFocused: $isFocused, results: results,
            isSearching: isSearching, isLocating: isLocating, errorMessage: errorMessage,
            onSelect: { _ in }, onCurrentLocation: {}, onPhoto: {}, onClose: {}
        )
    }
}

#Preview("Isi Pencarian · Kosong") {
    LocationSearchContentPreview()
}

#Preview("Isi Pencarian · Ada hasil") {
    LocationSearchContentPreview(query: "smkn gunung kijang", results: GardenRegistrationPreview.searchResults)
}

#Preview("Isi Pencarian · Sedang mencari") {
    LocationSearchContentPreview(query: "dumai", isSearching: true)
}

#Preview("Isi Pencarian · Tidak ditemukan") {
    LocationSearchContentPreview(query: "zzz")
}

#Preview("Isi Pencarian · Gagal") {
    LocationSearchContentPreview(query: "dumai", errorMessage: "Pencarian gagal. Periksa koneksi internet lalu coba lagi.")
}

#Preview("Isi Pencarian · Mencari GPS") {
    LocationSearchContentPreview(isLocating: true)
}
#endif
