import Foundation

/// A location saved with "Lakukan Nanti" before its boundary is mapped.
/// Persists the selected location until its boundary is mapped.
struct GardenDraft: Identifiable, Codable {
    var id = UUID()
    let name: String
    let subtitle: String
    let coordinate: GardenCoordinate
    var createdAt = Date()

    init(id: UUID = UUID(), name: String, subtitle: String, coordinate: GardenCoordinate, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.createdAt = createdAt
    }

    init(location: GardenLocation) {
        self.id = location.draftID ?? UUID()
        self.name = location.name
        self.subtitle = location.subtitle
        self.coordinate = location.coordinate
    }

    var location: GardenLocation {
        GardenLocation(name: name, subtitle: subtitle, coordinate: coordinate, source: .draft, draftID: id)
    }
}
