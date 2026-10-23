import SwiftUI
import Photos
import UIKit

/// Photos from the library that came from the camera, as far as Photos can tell: images with a
/// location, excluding screenshots. Saved or forwarded images usually lose their location, so this
/// also keeps out photos that could not place the garden on the map.
@MainActor
@Observable
final class CameraPhotoLibrary {
    enum Access { case unknown, allowed, denied }

    private(set) var access = Access.unknown
    private(set) var assets: [PHAsset] = []
    let imageManager = PHCachingImageManager()

    func load() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            access = .denied
            return
        }
        access = .allowed
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var found: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            // A bitmask predicate on mediaSubtypes does not filter reliably, so screenshots are excluded here.
            if asset.location != nil, asset.sourceType.contains(.typeUserLibrary),
               !asset.mediaSubtypes.contains(.photoScreenshot) {
                found.append(asset)
            }
        }
        assets = found
    }
}

struct GardenPhotoPickerView: View {
    let onSelect: (GardenCoordinate) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var library = CameraPhotoLibrary()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Album Kamera", onClose: { dismiss() })
            switch library.access {
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
            case .allowed where library.assets.isEmpty:
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
                        ForEach(library.assets, id: \.localIdentifier) { asset in
                            Button {
                                guard let location = asset.location else { return }
                                onSelect(GardenCoordinate(location.coordinate))
                                dismiss()
                            } label: {
                                CameraPhotoThumbnail(asset: asset, manager: library.imageManager)
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
        .task { await library.load() }
    }
}

private struct CameraPhotoThumbnail: View {
    let asset: PHAsset
    let manager: PHCachingImageManager
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
            .task(id: asset.localIdentifier) {
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isNetworkAccessAllowed = true
                let size = CGSize(width: 240, height: 240)
                manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { result, _ in
                    if let result { image = result }
                }
            }
    }
}

#Preview("04 · Pilih Foto Galeri") {
    GardenPhotoPickerView(onSelect: { _ in })
}
