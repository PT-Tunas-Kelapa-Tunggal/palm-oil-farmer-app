import SwiftUI
import UIKit
import MapKit

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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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

struct PhotoSelectionContent: View {
    var location: GardenLocation?
    var image: UIImage? = nil
    var referenceMapImage: String? = nil
    var isLoadingImage = false

    var creationDate: Date? = nil
    var hasNoLocation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Color.clear.frame(height: 400).overlay {
                    if let image {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else if isLoadingImage {
                        ProgressView("Memuat foto…")
                    } else {
                        Image(systemName: "photo").font(.system(size: 80)).foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .accessibilityLabel("Foto terpilih")
                VStack(alignment: .leading, spacing: 16) {
                    metadataRow(symbol: "calendar", caption: "Waktu foto diambil",
                                value: creationDate.map {
                                    $0.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "id_ID"))) + ", " + $0.formatted(.dateTime.hour().minute().locale(Locale(identifier: "id_ID")))
                                } ?? "Waktu tidak tersimpan")
                    Divider()
                    if hasNoLocation {
                        HStack(alignment: .center, spacing: 14) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Lokasi tidak tersimpan di foto").font(.footnote).foregroundStyle(.secondary)
                                Text("Foto ini tidak bisa dipakai").font(.headline)
                                Text("Layanan Lokasi untuk Kamera belum aktif saat foto diambil. Aktifkan di Pengaturan, lalu ambil foto baru di kebun.")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    } else if let location {
                        metadataRow(symbol: "location.fill", caption: "Lokasi tersimpan di foto",
                                    value: String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude))
                    } else {
                        ProgressView("Mencari alamat foto…")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RegistrationStyle.surface, in: RoundedRectangle(cornerRadius: 20))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func metadataRow(symbol: String, caption: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol).foregroundStyle(RegistrationStyle.actionTint)
            VStack(alignment: .leading, spacing: 4) {
                Text(caption).font(.footnote).foregroundStyle(.secondary)
                Text(value).font(.headline)
            }
        }
    }
}

struct PhotoLocationCard: View {
    let location: GardenLocation
    var image: UIImage?
    var referenceMapImage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(location.name)
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            Group {
                if let referenceMapImage {
                    Image(referenceMapImage).resizable().scaledToFill()
                } else {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: location.coordinate.mapCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                    )), interactionModes: []) {
                        Annotation("Lokasi foto", coordinate: location.coordinate.mapCoordinate) {
                            PhotoLocationMarker(image: image)
                        }
                    }
                    .mapStyle(.imagery)
                    .mapControls {}
                }
            }
            .frame(height: 160)
            .clipped()
        }
        .background(RegistrationStyle.surface, in: RoundedRectangle(cornerRadius: RegistrationStyle.cardRadius))
        .clipShape(RoundedRectangle(cornerRadius: RegistrationStyle.cardRadius))
    }
}

struct PhotoLocationMarker: View {
    var image: UIImage?

    var body: some View {
        VStack(spacing: -1) {
            Group {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Image(systemName: "photo.fill").font(.title2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 48, height: 48)
            .background(.background)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay { RoundedRectangle(cornerRadius: 4).stroke(.white, lineWidth: 3) }
            Image(systemName: "triangle.fill")
                .font(.caption2)
                .rotationEffect(.degrees(180))
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Lokasi foto terpilih")
    }
}

private struct CameraPhotoThumbnail: View {
    let photoID: String
    let viewModel: GardenPhotoPickerViewModel
    @State private var image: UIImage?

    var body: some View {
        Color(uiColor: .systemBackground)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Image(systemName: "photo.fill").foregroundStyle(.tertiary)
                }
            }
            .clipped()
            .task(id: photoID) {
                for await data in viewModel.thumbnails(for: photoID) {
                    guard !Task.isCancelled else { return }
                    if let result = UIImage(data: data) { image = result }
                }
            }
    }
}

#Preview("COdedUI5 · Pilih Foto Galeri") {
    GardenPhotoPickerView(onSelect: { _ in })
}
