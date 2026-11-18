import SwiftUI

/// Search page layout without state, so previews stay deterministic.
struct LocationSearchContent: View {
    @Binding var query: String
    var isSearchFocused: FocusState<Bool>.Binding
    let results: [GardenLocation]
    var isSearching = false
    var isLocating = false
    var canDictate = false
    var isDictating = false
    var errorMessage: String? = nil
    let onSelect: (GardenLocation) -> Void
    let onCurrentLocation: () -> Void
    let onPhoto: () -> Void
    let onClose: () -> Void
    var onDictate: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            RegistrationHeader(title: "Cari Lokasi Kebun", onClose: onClose)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.title2).foregroundStyle(.secondary)
                    TextField("Cari patokan terdekat", text: $query,
                              prompt: Text(isDictating ? "Mendengarkan…" : "Cari patokan terdekat"))
                        .focused(isSearchFocused)
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Cari patokan terdekat")
                    if showsMicrophone {
                        Button(isDictating ? "Berhenti mendengarkan" : "Cari dengan suara",
                               systemImage: isDictating ? "mic.fill" : "mic", action: onDictate)
                            .labelStyle(.iconOnly)
                            .font(.title3)
                            .foregroundStyle(isDictating ? KropsTheme.accentHero : KropsTheme.labelSecondary)
                            .symbolEffect(.pulse, isActive: isDictating)
                            .frame(minWidth: 44, minHeight: 44)
                    } else if !query.isEmpty {
                        Button("Hapus pencarian", systemImage: "xmark.circle.fill") { query = "" }
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.tertiary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, showsMicrophone || !query.isEmpty ? 4 : 16)
                .frame(minHeight: 48)
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
                        Text("Belum tahu alamat kebun").font(.title3.weight(.bold)).accessibilityAddTraits(.isHeader)
                        Text("Pilih cara yang paling mudah untuk Anda.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, results.isEmpty ? 0 : 12)
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
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .background(KropsTheme.surfaceBackground)
        .presentationBackground(KropsTheme.surfaceCardRaised)
    }

    /// The microphone sits where the clear button goes: shown while the field is empty, and kept
    /// while listening so the farmer can stop it even after words appear.
    private var showsMicrophone: Bool {
        canDictate && (isDictating || query.isEmpty)
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
            isSearching: isSearching, isLocating: isLocating, canDictate: true, errorMessage: errorMessage,
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
