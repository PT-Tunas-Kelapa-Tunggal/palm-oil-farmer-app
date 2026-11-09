import SwiftUI

struct LocationSearchView: View {
    @State private var flow: GardenRegistrationFlow
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    init(flow: GardenRegistrationFlow) {
        _flow = State(initialValue: flow)
    }

    var body: some View {
        @Bindable var model = flow.searchViewModel
        @Bindable var coordinator = flow.coordinator
        LocationSearchContent(
            query: $model.query, isSearchFocused: $isSearchFocused,
            results: model.results, isSearching: model.isSearching,
            isLocating: model.isLocating, errorMessage: model.errorMessage,
            onSelect: { location in
                isSearchFocused = false
                model.selectResult(location)
            },
            onCurrentLocation: {
                isSearchFocused = false
                model.requestCurrentLocation()
            },
            onPhoto: {
                isSearchFocused = false
                model.cancelPendingWork()
                coordinator.openPhotoPicker()
            },
            onClose: { coordinator.cancel(); dismiss() }
        )
        .task { isSearchFocused = !model.query.isEmpty }
        .task(id: model.query) { await model.search() }
        .task(id: model.locationRequestID) { await model.locateCurrentIfRequested() }
        .sheet(isPresented: $coordinator.showsPhotoPicker, onDismiss: coordinator.photoPickerDidDismiss) {
            GardenPhotoPickerView(viewModel: flow.photoViewModel)
        }
        .onChange(of: coordinator.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .onDisappear {
            model.cancelPendingWork()
            coordinator.cancel()
        }
    }
}

/// Pure presentation shared by production search and deterministic Sketch previews.
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
            .scrollDismissesKeyboard(.interactively)
        }
        .background(RegistrationStyle.background)
        .presentationBackground(RegistrationStyle.background)
    }
}

#Preview("COdedUI5 · Cari Alamat Awal") {
    LocationSearchView(onSelect: { _ in })
}

#if DEBUG
#Preview("COdedUI5 · Cari Alamat Terisi") {
    LocationSearchView(initialQuery: "smkn gunung kijang",
                       initialResults: [GardenPreviewData.location], onSelect: { _ in })
}
#endif
