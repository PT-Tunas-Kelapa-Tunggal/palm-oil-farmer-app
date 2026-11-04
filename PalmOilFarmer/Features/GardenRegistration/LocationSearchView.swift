import SwiftUI

struct LocationSearchView: View {
    typealias PhotoStatus = GardenPhotoStatus
    @State private var flow: GardenRegistrationFlow
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    init(flow: GardenRegistrationFlow) {
        _flow = State(initialValue: flow)
    }

    var body: some View {
        @Bindable var model = flow.searchViewModel
        @Bindable var coordinator = flow.coordinator
        VStack(spacing: 0) {
            ScreenHeader(title: "Cari alamat", onClose: { flow.coordinator.cancel(); dismiss() })

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("Cari tempat terdekat dari kebun", text: $model.query)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .autocorrectionDisabled()
                    if !model.query.isEmpty {
                        Button("Hapus pencarian", systemImage: "xmark.circle.fill") { model.query = "" }
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
                    if model.isSearching {
                        ProgressView("Mencari lokasi…").padding()
                    } else if let errorMessage = model.errorMessage {
                        Text(errorMessage).foregroundStyle(.secondary).padding()
                    } else if model.hasQuery && model.results.isEmpty {
                        Text("Tempat tidak ditemukan. Coba nama desa atau tempat lain yang dekat dengan kebun.")
                            .foregroundStyle(.secondary).padding()
                    }

                    if !model.hasQuery {
                        currentLocationRow
                        photoCard
                    }

                    ForEach(model.results) { location in
                        Button {
                            model.selectResult(location)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.title3)
                                    .frame(width: 36, height: 36)
                                    .background(KropsTheme.cardFill, in: Circle())
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(location.name).font(.headline)
                                    Text(location.subtitle).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .frame(minHeight: 74)
                            .background(KropsTheme.cardFill, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
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
        .task { isSearchFocused = true }
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

    private var currentLocationRow: some View {
        let model = flow.searchViewModel
        return Button { model.requestCurrentLocation() } label: {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(KropsTheme.cardFill, in: Circle())
                VStack(alignment: .leading, spacing: 0) {
                    Text("Gunakan lokasi saat ini").font(.headline)
                    Text(model.isLocating ? "Mencari lokasi…" : "Lokasi perangkat")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if model.isLocating { ProgressView() }
            }
            .padding(16)
            .frame(minHeight: 74)
            .background(KropsTheme.cardFill, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
            .contentShape(RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
        }
        .buttonStyle(.plain)
        .disabled(model.isLocating)
    }

    private var photoCard: some View {
        let model = flow.searchViewModel
        return Button {
            model.cancelPendingWork()
            flow.coordinator.openPhotoPicker()
        } label: {
            VStack(spacing: 8) {
                if model.photoStatus == .loading {
                    ProgressView().controlSize(.large)
                } else {
                    Image(systemName: model.photoStatus.symbol)
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
                Text("Temukan Lokasi Kebun dari Foto").font(.headline)
                Text(model.photoStatus.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(KropsTheme.cardFill, in: RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
            .contentShape(RoundedRectangle(cornerRadius: KropsTheme.Radius.card))
        }
        .buttonStyle(.plain)
        .disabled(model.photoStatus == .loading)
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
