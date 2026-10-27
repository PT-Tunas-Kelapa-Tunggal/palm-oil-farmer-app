import CoreLocation
import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct FindingBlockTests {
    private func boundary(_ points: [(Double, Double)]) -> GardenBoundary {
        GardenBoundary(points: points.map {
            GardenCoordinate(CLLocationCoordinate2D(latitude: $0.1, longitude: $0.0))
        })
    }

    @Test func blocksPreserveAreaForConvexAndConcaveGardens() {
        let shapes: [[(Double, Double)]] = [
            [(106, -6), (106.002, -6), (106.002, -6.003), (106, -6.003)],
            [(106, -6), (106.003, -6), (106.003, -6.001),
             (106.001, -6.001), (106.001, -6.003), (106, -6.003)]
        ]
        for shape in shapes {
            for coordinates in [shape, Array(shape.reversed())] {
                let gardenBoundary = boundary(coordinates)
                let blocks = BlockZoning.zones(for: gardenBoundary)
                #expect(blocks.count == 6)
                #expect(blocks.map(\.id) == [1, 2, 3, 4, 5, 6])
                let total = blocks.reduce(0) { $0 + $1.areaSquareMeters }
                #expect(abs(total - gardenBoundary.areaHectares * 10_000) < 0.1)
                for block in blocks {
                    #expect(abs(block.areaSquareMeters - total / 6) < 0.01)
                    // Each fragment is convex: its target must lie on the same side of every edge.
                    #expect(block.fragments.contains { fragment in
                        let signs = fragment.indices.map { i in
                            let a = fragment[i], b = fragment[(i + 1) % fragment.count]
                            return (b.longitude - a.longitude) * (block.destination.latitude - a.latitude)
                                - (b.latitude - a.latitude) * (block.destination.longitude - a.longitude)
                        }
                        return signs.allSatisfy { $0 >= -1e-12 } || signs.allSatisfy { $0 <= 1e-12 }
                    })
                }
            }
        }
    }

    @Test func mapUsesStableAreaCodesAndHidesTriangulationEdges() {
        let blocks = BlockZoning.zones(for: boundary([
            (106, -6), (106.002, -6), (106.002, -6.003), (106, -6.003)
        ]))
        #expect(blocks.map(\.code) == ["AA", "BA", "AB", "BB", "AC", "BC"])
        for block in blocks {
            #expect(!block.outlineEdges.isEmpty)
            for edge in block.outlineEdges {
                #expect(abs(edge[0].latitude - edge[1].latitude) < 1e-8
                        || abs(edge[0].longitude - edge[1].longitude) < 1e-8)
            }
        }
    }

    @Test func invalidBoundariesDoNotProduceBlocks() {
        #expect(BlockZoning.zones(for: GardenBoundary()).isEmpty)
        #expect(BlockZoning.zones(for: boundary([
            (106, -6), (106.002, -6.002), (106.002, -6), (106, -6.002)
        ])).isEmpty)
    }

    @Test func allocationUsesAreaAndConservesEnteredTotal() {
        let target = CLLocationCoordinate2D(latitude: -6, longitude: 106)
        let blocks = [
            GardenBlock(id: 1, fragments: [], destination: target, areaSquareMeters: 100),
            GardenBlock(id: 2, fragments: [], destination: target, areaSquareMeters: 300)
        ]
        let quantities = BlockAllocation.quantities(totalKilograms: 120, blocks: blocks)
        #expect(quantities[1] == 30)
        #expect(quantities[2] == 90)
        #expect(quantities.values.reduce(0, +) == 120)
        #expect(BlockAllocation.quantities(totalKilograms: .infinity, blocks: blocks).isEmpty)
        #expect(BlockAllocation.kilograms(from: "12,5") == 12.5)
        #expect(BlockAllocation.kilograms(from: "-1") == nil)
        #expect(BlockAllocation.kilograms(from: "nan") == nil)
        #expect(BlockAllocation.kilograms(from: "") == nil)
    }

    @Test func localReportUsesSelectedGardenWithoutInventedAnalysis() {
        let garden = Garden(id: UUID(), name: "Kebun pengguna", locationName: "Lokasi pengguna",
            boundary: boundary([(106, -6), (106.001, -6), (106.001, -6.002), (106, -6.002)]),
            plantingYear: 2022, soilType: .mineral)
        let report = FertilizerRecommendationReport.local(for: garden)
        #expect(report.gardenName == garden.name)
        #expect(report.locationName == garden.locationName)
        #expect(report.boundary.points == garden.boundary.points)
        #expect(report.outline.count == garden.boundary.points.count)
        #expect(report.outline.allSatisfy { (0...1).contains($0.x) && (0...1).contains($0.y) })
        #expect(report.nutrients.isEmpty && report.costs.isEmpty && report.areas.isEmpty)
        #expect(report.rainfall == nil && report.downloadURL == nil)
    }

    @Test func navigationRejectsStaleGPSAndMeasuresRealDistance() {
        let now = Date()
        let coordinate = CLLocationCoordinate2D(latitude: -6, longitude: 106)
        let fix = CLLocation(coordinate: coordinate, altitude: 0, horizontalAccuracy: 5,
                             verticalAccuracy: 5, timestamp: now)
        let block = GardenBlock(id: 1, fragments: [], destination: coordinate, areaSquareMeters: 100)
        #expect(BlockLocationSession.isUsable(fix, now: now))
        #expect(!BlockLocationSession.isUsable(fix, now: now.addingTimeInterval(16)))
        #expect(BlockLocationSession.distance(from: fix, to: block) == 0)
    }
}
