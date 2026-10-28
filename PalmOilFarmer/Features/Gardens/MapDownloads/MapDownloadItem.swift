import Foundation

struct MapDownloadItem: Identifiable {
    let id: UUID
    let location: GardenLocation
    let state: MapDownloadState
    var referenceMapImage: String? = nil
}
