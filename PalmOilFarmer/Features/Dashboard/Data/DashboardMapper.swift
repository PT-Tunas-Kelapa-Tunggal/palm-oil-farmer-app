import Foundation

/// (3) Turns the app's shared garden records into the dashboard's own models.
/// Together with `DashboardRepository`, this is the only place in the feature
/// that knows `Garden` and `GardenDraft`.
struct DashboardMapper {
    func map(_ garden: Garden) -> DashboardGarden {
        DashboardGarden(
            id: garden.id,
            name: garden.name,
            soilType: garden.soilType.rawValue,
            plantingYear: String(garden.plantingYear),
            area: garden.boundary.areaHectares.formatted(.number.precision(.fractionLength(0...1))) + " ha",
            perimeter: garden.boundary.perimeterMeters.formatted(.number.precision(.fractionLength(0))) + " m",
            boundary: garden.boundary.points.map { DashboardCoordinate(latitude: $0.latitude, longitude: $0.longitude) },
            stage: stage(of: garden),
            visitDate: garden.review?.visitDate,
            createdAt: garden.createdAt
        )
    }

    func map(_ draft: GardenDraft) -> DashboardDraft {
        DashboardDraft(
            id: draft.id,
            name: draft.name,
            subtitle: draft.subtitle,
            coordinate: DashboardCoordinate(latitude: draft.coordinate.latitude, longitude: draft.coordinate.longitude),
            createdAt: draft.createdAt
        )
    }

    /// Where mapping resumes for a draft picked on the dashboard. Keeps the draft ID,
    /// so a successful save replaces the draft.
    func mappingLocation(for draft: DashboardDraft) -> GardenLocation {
        GardenDraft(
            id: draft.id,
            name: draft.name,
            subtitle: draft.subtitle,
            coordinate: GardenCoordinate(latitude: draft.coordinate.latitude, longitude: draft.coordinate.longitude),
            createdAt: draft.createdAt
        ).location
    }

    private func stage(of garden: Garden) -> DashboardGardenStage {
        guard let review = garden.review else {
            return garden.isProfileComplete ? .readyForReview : .incomplete
        }
        switch review.status {
        case .completed: return .results(downloaded: review.resultsDownloaded)
        case .scheduled: return .inReview(visitScheduled: true)
        case .submitted, .inReview: return .inReview(visitScheduled: false)
        }
    }
}
