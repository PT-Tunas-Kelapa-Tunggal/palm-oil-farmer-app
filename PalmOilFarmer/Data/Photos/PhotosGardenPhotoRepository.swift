import Foundation
import Photos
import UIKit

@MainActor
final class PhotosGardenPhotoRepository: GardenPhotoRepository {
    private let imageManager = PHCachingImageManager()
    private var assets: [String: PHAsset] = [:]

    func loadPhotos() async -> GardenPhotoLibrarySnapshot {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard !Task.isCancelled else { return GardenPhotoLibrarySnapshot(access: .unknown, photos: []) }
        guard status == .authorized || status == .limited else {
            assets = [:]
            return GardenPhotoLibrarySnapshot(access: .denied, photos: [])
        }
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var found: [GardenPhoto] = []
        var loadedAssets: [String: PHAsset] = [:]
        result.enumerateObjects { asset, _, _ in
            // Keep subtype filtering in memory, as in the existing implementation.
            if let photo = GardenPhoto(
                id: asset.localIdentifier,
                coordinate: asset.location.map { GardenCoordinate($0.coordinate) },
                creationDate: asset.creationDate,
                isUserLibrary: asset.sourceType.contains(.typeUserLibrary),
                isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot)
            ) {
                found.append(photo)
                loadedAssets[photo.id] = asset
            }
        }
        assets = loadedAssets
        return GardenPhotoLibrarySnapshot(access: .allowed, photos: found)
    }

    func thumbnails(for photoID: String) -> AsyncStream<Data> {
        images(for: photoID, size: CGSize(width: 240, height: 240))
    }

    func previewImages(for photoID: String) -> AsyncStream<Data> {
        images(for: photoID, size: CGSize(width: 1600, height: 1600))
    }

    private func images(for photoID: String, size: CGSize) -> AsyncStream<Data> {
        guard let asset = assets[photoID] else { return AsyncStream { $0.finish() } }
        let manager = imageManager
        return AsyncStream { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true
            let requestID = manager.requestImage(
                for: asset, targetSize: size, contentMode: .aspectFill, options: options
            ) { image, info in
                if let data = image?.pngData() { continuation.yield(data) }
                if info?[PHImageResultIsDegradedKey] as? Bool != true { continuation.finish() }
            }
            continuation.onTermination = { _ in
                manager.cancelImageRequest(requestID)
            }
        }
    }
}
