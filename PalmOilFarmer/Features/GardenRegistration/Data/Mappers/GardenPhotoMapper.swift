import CoreLocation
import Photos

/// Maps a Photos asset (`PHAsset`) to a `GardenPhoto`.
/// Returns nil for screenshots and photos outside the user's library.
enum GardenPhotoMapper {
    static func photo(from asset: PHAsset) -> GardenPhoto? {
        GardenPhoto(
            id: asset.localIdentifier,
            coordinate: asset.location.map { GardenLocationMapper.gardenCoordinate($0.coordinate) },
            creationDate: asset.creationDate,
            isUserLibrary: asset.sourceType.contains(.typeUserLibrary),
            isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot)
        )
    }
}
