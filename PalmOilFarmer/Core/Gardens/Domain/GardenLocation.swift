import Foundation

struct GardenLocation: Identifiable {
    enum Source {
        case search, currentLocation, photo, draft
    }

    let id = UUID()
    let name: String
    let subtitle: String
    let coordinate: GardenCoordinate
    var source = Source.search
    /// A small selected-photo preview for the location marker; never persisted with the garden.
    var photoPreviewData: Data? = nil
    /// Set when mapping resumes a saved draft, so a successful save can remove it.
    var draftID: UUID? = nil
    /// When the selected photo was taken, shown while confirming a photo location.
    var photoDate: Date? = nil
}
