import Foundation

struct GardenLocation: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let coordinate: GardenCoordinate
}
