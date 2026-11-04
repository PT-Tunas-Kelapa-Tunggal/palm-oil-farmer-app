import CoreGraphics
import CoreLocation
import Foundation

extension PlantationReviewRequest {
    func makeRecommendationReport() -> FertilizerRecommendationReport? {
        guard let result = self.result else { return nil }

        let gardenCoordinates = self.boundary.map {
            GardenCoordinate(CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude))
        }
        let gardenBoundary = GardenBoundary(points: gardenCoordinates)

        // Generate normalized silhouette points from the boundary
        let outline: [CGPoint]
        if gardenBoundary.points.count >= 3 {
            let lats = gardenBoundary.points.map(\.latitude)
            let lons = gardenBoundary.points.map(\.longitude)
            if let minLat = lats.min(), let maxLat = lats.max(),
               let minLon = lons.min(), let maxLon = lons.max(),
               maxLat > minLat, maxLon > minLon {
                outline = gardenBoundary.points.map {
                    CGPoint(
                        x: ($0.longitude - minLon) / (maxLon - minLon),
                        y: 1.0 - ($0.latitude - minLat) / (maxLat - minLat)
                    )
                }
            } else {
                outline = []
            }
        } else {
            outline = []
        }

        let nutrients = result.nutrients.map {
            NutrientProjection(name: $0.name, current: $0.current, target: $0.target)
        }

        let costs = result.costs.map {
            FertilizerCostLine(name: $0.name, quantity: $0.quantity, cost: $0.cost)
        }

        let areas = result.allocationAreas.map { area in
            FertilizerAllocationArea(
                id: area.id,
                mapImage: result.orthomosaicImageURL?.path,
                periods: area.periods.map { period in
                    FertilizerAllocationPeriod(
                        title: period.title,
                        dateRange: period.dateRange,
                        lines: period.lines.map {
                            FertilizerAllocationLine(name: $0.name, total: $0.total, dosage: $0.dosage)
                        }
                    )
                }
            )
        }

        return FertilizerRecommendationReport(
            gardenName: self.garden.name,
            locationName: self.garden.locationName,
            boundary: gardenBoundary,
            outline: outline,
            nutrients: nutrients,
            costs: costs,
            totalCost: result.totalCostFormatted,
            areas: areas
        )
    }
}
