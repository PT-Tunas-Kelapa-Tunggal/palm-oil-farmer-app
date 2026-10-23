#if DEBUG
import Foundation
import CoreGraphics

enum RecommendationPreviewData {
    static let lines = ["Urea", "KCl(MOP)", "Kiserite"].map {
        FertilizerAllocationLine(name: $0, total: "Total urea dibutuhkan 13kg", dosage: "1.5 kg / pohon")
    }
    static let report = FertilizerRecommendationReport(
        gardenName: "Belakang rumah", locationName: "Malang Rapat",
        boundary: GardenPreviewData.boundary,
        outline: [
            CGPoint(x: 1, y: 0.10927), CGPoint(x: 0.64475, y: 0),
            CGPoint(x: 0.55678, y: 0.15505), CGPoint(x: 0.20978, y: 0.03791),
            CGPoint(x: 0, y: 0.50098), CGPoint(x: 0.34909, y: 0.64072),
            CGPoint(x: 0.23222, y: 0.87896), CGPoint(x: 0.5, y: 1)
        ],
        nutrients: [
            NutrientProjection(name: "N", current: 0.4, target: 0.64),
            NutrientProjection(name: "P", current: 1, target: 0.64),
            NutrientProjection(name: "K", current: 0.52, target: 0.64),
            NutrientProjection(name: "Mg", current: 0.21, target: 0.64)
        ],
        costs: [
            FertilizerCostLine(name: "Urea", quantity: "115", cost: "Rp800,000"),
            FertilizerCostLine(name: "KCl(MOP)", quantity: "130", cost: "Rp800,000"),
            FertilizerCostLine(name: "Kiserite", quantity: "50", cost: "Rp800,000")
        ],
        totalCost: "Rp1,435,000",
        areas: [
            FertilizerAllocationArea(id: "AB", mapImage: "CodedAllocationMap", periods: [
                FertilizerAllocationPeriod(title: "Periode 1", dateRange: "Januari - Maret", lines: lines),
                FertilizerAllocationPeriod(title: "Periode 2", dateRange: "Juni - Agustus", lines: lines)
            ])
        ]
    )
}
#endif
