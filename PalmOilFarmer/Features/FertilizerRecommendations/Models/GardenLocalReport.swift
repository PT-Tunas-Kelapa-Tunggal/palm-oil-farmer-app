import MapKit

extension FertilizerRecommendationReport {
    /// A local view of saved garden geometry. No soil, cost, or weather values are inferred.
    static func local(for garden: Garden) -> FertilizerRecommendationReport {
        let points = garden.boundary.coordinates.map { MKMapPoint($0) }
        let minX = points.map(\.x).min() ?? 0
        let minY = points.map(\.y).min() ?? 0
        let width = max((points.map(\.x).max() ?? minX) - minX, 1)
        let height = max((points.map(\.y).max() ?? minY) - minY, 1)
        let scale = max(width, height)
        let outline = points.map {
            CGPoint(x: ($0.x - minX + (scale - width) / 2) / scale,
                    y: ($0.y - minY + (scale - height) / 2) / scale)
        }
        return FertilizerRecommendationReport(
            gardenName: garden.name, locationName: garden.locationName,
            boundary: garden.boundary, outline: outline,
            nutrients: [], costs: [], totalCost: "", areas: []
        )
    }
}
