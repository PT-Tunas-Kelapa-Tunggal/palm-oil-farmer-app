import Foundation

struct MappingDraft: Identifiable, Codable {
    var id: UUID { location.id }
    let location: GardenLocation
    var boundary: GardenBoundary
}
