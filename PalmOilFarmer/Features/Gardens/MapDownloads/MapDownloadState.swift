import Foundation

enum MapDownloadState {
    case downloading(progress: Double, receivedMB: Int, totalMB: Int, remaining: String)
    case completed
    case failed(String)

    static let referenceProgress = MapDownloadState.downloading(
        progress: 0.4, receivedMB: 48, totalMB: 120, remaining: "sekitar 3 menit lagi"
    )
}
