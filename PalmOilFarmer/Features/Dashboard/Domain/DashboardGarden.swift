import Foundation

/// (4) A registered garden as the dashboard shows it, already formatted for display.
struct DashboardGarden: Identifiable, Equatable {
    let id: UUID
    let name: String
    let soilType: String
    let plantingYear: String
    let area: String
    let perimeter: String
    /// Boundary corners, used only to draw the card's map.
    let boundary: [DashboardCoordinate]
    let stage: DashboardGardenStage
    let visitDate: Date?
    /// Gardens saved before this field existed have none.
    let createdAt: Date?
}

struct DashboardCoordinate: Equatable {
    let latitude: Double
    let longitude: Double
}
