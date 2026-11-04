import SwiftUI
import UIKit

struct GardenPhotoPickerView: View {
    @State private var viewModel: GardenPhotoPickerViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    init(viewModel: GardenPhotoPickerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Album Kamera", onClose: { dismiss() })
            switch viewModel.access {
            case .unknown:
                ProgressView().frame(maxHeight: .infinity)
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
                ContentUnavailableView("Belum ada foto dari kamera", systemImage: "camera",
                    description: Text("Ambil foto di kebun dengan lokasi aktif, lalu coba lagi."))
            case .allowed:
                ScrollView {
                    Text("Foto yang diambil dengan kamera dan menyimpan lokasi.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, KropsTheme.Spacing.screen)
                        .padding(.bottom, 8)
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(viewModel.photos, id: \.id) { asset in
                            Button {
                                if viewModel.selectPhoto(id: asset.id) { dismiss() }
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
        .presentationDetents([.large])
        .task { await viewModel.load() }
        .onDisappear { viewModel.cancelLoading() }
    }
}

private struct CameraPhotoThumbnail: View {
    let photoID: String
    let viewModel: GardenPhotoPickerViewModel
    @State private var image: UIImage?

    var body: some View {
        Color(uiColor: .secondarySystemFill)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
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

#Preview("04 · Pilih Foto Galeri") {
    GardenPhotoPickerView(onSelect: { _ in })
}
