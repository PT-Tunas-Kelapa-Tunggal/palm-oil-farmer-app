import SwiftUI
import UIKit

/// "Foto" sheet: pick a gallery photo, preview it, then confirm with "Gunakan Foto Ini".
struct GardenPhotoPickerView: View {
    @State private var viewModel: GardenPhotoPickerViewModel
    @State private var previewImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    init(viewModel: GardenPhotoPickerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 4)

    var body: some View {
        DynamicSheet(animation: .bouncy, size: .large) {
            sheetContent
        }
        .presentationBackgroundInteraction(.disabled)
        .presentationDragIndicator(.hidden)
        .presentationContentInteraction(.scrolls)
    }

    @ViewBuilder
    private var sheetContent: some View {
        VStack(spacing: 0) {
            RegistrationHeader(
                title: viewModel.previewPhotoID == nil ? "Foto" : "Foto Kebun",
                onClose: {
                    if viewModel.previewPhotoID != nil {
                        previewImage = nil
                        viewModel.clearPreview()
                    } else {
                        dismiss()
                    }
                }
            )
            if let selectedPhotoID = viewModel.previewPhotoID {
                PhotoSelectionContent(location: viewModel.previewLocation, image: previewImage,
                                      isLoadingImage: previewImage == nil,
                                      creationDate: viewModel.previewPhoto?.creationDate,
                                      hasNoLocation: viewModel.previewHasNoLocation)
                    .task(id: selectedPhotoID) {
                        await viewModel.preparePreview(for: selectedPhotoID)
                    }
                    .task(id: selectedPhotoID) {
                        for await data in viewModel.previewImages(for: selectedPhotoID) {
                            guard !Task.isCancelled else { return }
                            if let image = UIImage(data: data) { previewImage = image }
                        }
                    }
            } else {
                gallery
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.previewPhotoID != nil {
                RegistrationPrimaryButton(
                    title: viewModel.previewHasNoLocation ? "Pilih Foto Lain" : "Gunakan Foto Ini"
                ) {
                    if viewModel.previewHasNoLocation {
                        previewImage = nil
                        viewModel.clearPreview()
                    } else if viewModel.confirmPreview(imageData: previewImage?.jpegData(compressionQuality: 0.5)) {
                        dismiss()
                    }
                }
                .disabled(!viewModel.previewHasNoLocation && viewModel.previewLocation == nil)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(RegistrationStyle.background)
        .presentationBackground(RegistrationStyle.background)
        .task { await viewModel.load() }
        .onDisappear { viewModel.cancelLoading() }
    }

    @ViewBuilder
    private var gallery: some View {
        switch viewModel.access {
        case .unknown:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .denied:
            ContentUnavailableView {
                Label("Akses foto belum diizinkan", systemImage: "photo.on.rectangle")
            } description: {
                Text("Izinkan akses foto agar lokasi kebun dapat ditemukan dari foto yang diambil di kebun.")
            } actions: {
                Button("Buka Pengaturan") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .buttonStyle(.glass)
            }
        case .allowed where viewModel.photos.isEmpty:
            ContentUnavailableView("Belum ada foto", systemImage: "camera",
                description: Text("Ambil foto di kebun dengan lokasi aktif, lalu coba lagi."))
        case .allowed:
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(viewModel.photos) { asset in
                        Button {
                            previewImage = nil
                            viewModel.showPreview(for: asset.id)
                        } label: {
                            CameraPhotoThumbnail(photoID: asset.id, viewModel: viewModel)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(asset.creationDate.map {
                            "Foto \($0.formatted(date: .long, time: .shortened))"
                        } ?? "Foto")
                    }
                }
            }
        }
    }

}

#if DEBUG
#Preview("Sheet Foto · Galeri") {
    RegistrationSheetPreview {
        GardenPhotoPickerView(viewModel: GardenRegistrationPreview.photoPickerViewModel())
    }
}

#Preview("Sheet Foto · Akses ditolak") {
    RegistrationSheetPreview {
        GardenPhotoPickerView(viewModel: GardenRegistrationPreview.photoPickerViewModel(.denied))
    }
}

#Preview("Sheet Foto · Belum ada foto") {
    RegistrationSheetPreview {
        GardenPhotoPickerView(viewModel: GardenRegistrationPreview.photoPickerViewModel(.empty))
    }
}
#endif
