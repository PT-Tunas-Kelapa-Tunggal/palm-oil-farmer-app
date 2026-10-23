import Foundation

/// A location saved with "Lakukan Nanti" before its boundary is mapped.
/// Stored apart from gardens.json so the garden file format stays unchanged.
struct GardenDraft: Identifiable, Codable {
    var id = UUID()
    let name: String
    let subtitle: String
    let coordinate: GardenCoordinate
    var createdAt = Date()

    init(location: GardenLocation) {
        name = location.name
        subtitle = location.subtitle
        coordinate = location.coordinate
    }

    var location: GardenLocation {
        GardenLocation(name: name, subtitle: subtitle, coordinate: coordinate, source: .draft, draftID: id)
    }

    var title: String {
        subtitle.isEmpty || subtitle == name ? name : "\(name), \(subtitle)"
    }
}
