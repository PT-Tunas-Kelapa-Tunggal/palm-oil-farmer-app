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
    let reviewStatus: ReviewStatus?

    init(
        id: UUID,
        name: String,
        soilType: String,
        plantingYear: String,
        area: String,
        perimeter: String,
        boundary: [DashboardCoordinate],
        stage: DashboardGardenStage,
        visitDate: Date? = nil,
        createdAt: Date? = nil,
        reviewStatus: ReviewStatus? = nil
    ) {
        self.id = id
        self.name = name
        self.soilType = soilType
        self.plantingYear = plantingYear
        self.area = area
        self.perimeter = perimeter
        self.boundary = boundary
        self.stage = stage
        self.visitDate = visitDate
        self.createdAt = createdAt
        self.reviewStatus = reviewStatus
    }

    /// True ONLY when this garden has a review request whose progression status isn't finished/completed.
    var requiresOnlineConnection: Bool {
        guard let reviewStatus else { return false }
        return reviewStatus != .completed
    }
}

struct DashboardCoordinate: Equatable {
    let latitude: Double
    let longitude: Double
}
