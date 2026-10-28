import Foundation

struct GardenLocation: Identifiable, Codable {
    var id = UUID()
    let name: String
    let subtitle: String
    let coordinate: GardenCoordinate
    var source: Source = .search

    enum Source: String, Codable {
        case search, photo, currentLocation
    }
}
