import SwiftUI
import PhotosUI

struct RegistrationIntroView: View {
    let onLocate: (GardenLocation) -> Void
    var referenceMapImage: String? = nil

    @ScaledMetric(relativeTo: .body) private var contentHeight = 141
    @State private var step = Step.guide
    @State private var photo: PhotosPickerItem?
    @State private var photoStatus = PhotoStatus.idle
    @State private var selectedLocation: GardenLocation?
    @State private var isSearching = false
    @State private var showsPhotoPicker = false

    enum Step: Int {
        case guide, photo, address

        var title: String {
            switch self {
            case .guide: "Petakan batas kebun"
            case .photo: "Temukan lokasi kebun dari foto"
            case .address: "Alamat Kabupaten/Kota"
            }
        }

        var message: String {
            switch self {
            case .guide:
                "Tandai titik titik di sepanjang batas kebun, pastikan seluruh bagian kebun masuk kedalam area pemetaan"
            case .photo:
                "Foto yang diambil langsung di kebun menyimpan data lokasi. Aplikasi menggunakan data tersebut untuk menemukan lokasi kebun secara otomatis."
            case .address:
                "Pilih kabupaten atau kota tempat kebun berada untuk mulai memetakan batas kebun."
            }
        }
    }

    enum PhotoStatus {
        case idle, loading, missingLocation, failed

        var message: String {
            switch self {
            case .idle: "Unggah foto dari galeri"
            case .loading: "Memeriksa foto"
            case .missingLocation: "Data lokasi tidak ditemukan\nCoba foto lain"
            case .failed: "Foto tidak dapat dibaca\nCoba foto lain"
            }
        }

        var symbol: String {
            switch self {
            case .idle: "photo.on.rectangle"
            case .loading: "photo"
            case .missingLocation, .failed: "xmark.circle"
            }
        }
    }

    init(
        initialStep: Step = .guide,
        initialPhotoStatus: PhotoStatus = .idle,
        initialLocation: GardenLocation? = nil,
        referenceMapImage: String? = nil,
        onLocate: @escaping (GardenLocation) -> Void
    ) {
        self.onLocate = onLocate
        self.referenceMapImage = referenceMapImage
        _step = State(initialValue: initialStep)
        _photoStatus = State(initialValue: initialPhotoStatus)
        _selectedLocation = State(initialValue: initialLocation)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(step == .address && selectedLocation == nil ? "Masukkan Kabupaten/Kota" : step.title)
                    .font(.title2.bold())
                    .padding(.bottom, 10)

                Text(step.message)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 60, alignment: .topLeading)
                    .padding(.bottom, 16)

                stepContent
                    .frame(height: contentHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                StepIndicator(currentStep: step.rawValue, totalSteps: 3)

                PrimaryActionButton(title: actionTitle) {
                    advance()
                }
                .disabled(photoStatus == .loading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 16)
        }
        .presentationDetents([.height(412), .large])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.disabled)
        .sheet(isPresented: $isSearching) {
            LocationSearchView { location in
                selectedLocation = location
            }
        }
        .sheet(isPresented: $showsPhotoPicker) {
            GardenPhotoPickerView { photo = $0 }
        }
        .task(id: photo) {
            await locatePhoto()
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .guide:
            BoundaryGuideIllustration()
        case .photo:
            Button { showsPhotoPicker = true } label: {
                VStack(spacing: 10) {
                    if photoStatus == .loading {
                        ProgressView()
                            .controlSize(.large)
                    } else {
                        Image(systemName: photoStatus.symbol)
                            .font(.largeTitle)
                    }
                    Text(photoStatus.message)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(photoStatus == .loading ? Color.clear : Color(uiColor: .systemGray4))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(photoStatus == .loading)
        case .address:
            Button {
                isSearching = true
            } label: {
                if let selectedLocation {
                    LocationMapPreview(location: selectedLocation, referenceImage: referenceMapImage)
                        .overlay(alignment: .bottomLeading) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedLocation.name).bold()
                                Text(selectedLocation.subtitle).font(.caption)
                            }
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.black.opacity(0.5))
                        }
                } else {
                    Text("Contoh: Dumai, Riau")
                        .font(.body)
                        .foregroundStyle(Color(uiColor: .placeholderText))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .background(.quaternary, in: Capsule())
                        .frame(maxHeight: .infinity)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Buka pencarian untuk memilih atau mengganti lokasi")
        }
    }

    private var actionTitle: String {
        switch step {
        case .guide: "Lanjut"
        case .photo: "Cari dengan alamat"
        case .address: selectedLocation == nil ? "Cari dengan alamat" : "Lanjutkan"
        }
    }

    private func advance() {
        switch step {
        case .guide: step = .photo
        case .photo: step = .address
        case .address:
            if let selectedLocation { onLocate(selectedLocation) } else { isSearching = true }
        }
    }

    @MainActor
    private func locatePhoto() async {
        guard let photo else { return }
        photoStatus = .loading
        do {
            guard let data = try await photo.loadTransferable(type: Data.self) else {
                photoStatus = .failed
                return
            }
            try Task.checkCancellation()
            guard let coordinate = PhotoLocationReader.coordinate(in: data) else {
                photoStatus = .missingLocation
                return
            }
            onLocate(GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun", coordinate: coordinate))
        } catch {
            guard !Task.isCancelled else { return }
            photoStatus = .failed
        }
    }
}

#Preview("02 · Panduan Petakan Batas") {
    RegistrationIntroView(onLocate: { _ in })
}

#if DEBUG
#Preview("03 · Lokasi dari Foto") {
    RegistrationIntroView(initialStep: .photo, onLocate: { _ in })
}
#Preview("05 · Foto Memuat") {
    RegistrationIntroView(initialStep: .photo, initialPhotoStatus: .loading, onLocate: { _ in })
}
#Preview("06 · Foto Gagal") {
    RegistrationIntroView(initialStep: .photo, initialPhotoStatus: .missingLocation, onLocate: { _ in })
}
#Preview("07 · Alamat Awal") {
    RegistrationIntroView(initialStep: .address, onLocate: { _ in })
}
#Preview("10 · Kabupaten Terpilih") {
    RegistrationIntroView(initialStep: .address, initialLocation: GardenPreviewData.location, onLocate: { _ in })
}
#endif
