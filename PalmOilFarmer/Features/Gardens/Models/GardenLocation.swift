import Foundation

struct GardenLocation: Identifiable {
    enum Source {
        case search, photo, draft
    }

    let id = UUID()
    let name: String
    let subtitle: String
    let coordinate: GardenCoordinate
    var source = Source.search
    /// Set when mapping resumes a saved draft, so a successful save can remove it.
    var draftID: UUID? = nil
}
