#if DEBUG
import Foundation
import CoreGraphics

enum RecommendationPreviewData {
    static let lines = ["Urea", "KCl(MOP)", "Kiserite"].map {
        FertilizerAllocationLine(name: $0, total: "Total \($0) dibutuhkan 13kg", dosage: "1.5 kg / pohon")
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
            NutrientProjection(name: "N", current: 0.4, target: 0.64, status: "Kurang"),
            NutrientProjection(name: "P", current: 1, target: 0.64, status: "Berlebih"),
            NutrientProjection(name: "K", current: 0.52, target: 0.64, status: "Kurang"),
            NutrientProjection(name: "Mg", current: 0.21, target: 0.64, status: "Sangat kurang")
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
            ], boundary: GardenPreviewData.boundary,
               navigationTarget: GardenPreviewData.boundary.points.first)
        ],
        nutrientSummary: "Kadar magnesium paling jauh di bawah kebutuhan, disusul nitrogen dan kalium. Fosfor sudah melebihi kebutuhan, jadi tidak perlu pupuk fosfor.",
        nutrientReferences: [
            NutrientReference(id: "N", title: "Nitrogen (N)",
                explanation: "Nitrogen membantu daun tetap hijau dan pelepah baru tumbuh.",
                fertilizers: [
                    FertilizerReference(name: "Urea", detail: "Kandungan nitrogen ±46%."),
                    FertilizerReference(name: "ZA", detail: "Kandungan nitrogen ±21%, juga mengandung belerang."),
                    FertilizerReference(name: "NPK 15-15-15", detail: "Kandungan nitrogen ±15%, juga mengandung fosfor dan kalium.")
                ],
                note: "Kadar nitrogen bisa berbeda per merek. Lihat keterangan pada karung pupuk.")
        ],
        rainfall: RainfallForecast(dateRange: "19–25 Oktober",
            headline: "Hujan lebat pada Kamis dan Sabtu",
            days: [
                RainfallDay(id: "day-1", weekday: "Sen", symbol: "cloud.sun.fill", precipitationMillimeters: 0, isHeavy: false, spreadStatus: "Disarankan untuk pemupukan"),
                RainfallDay(id: "day-2", weekday: "Sel", symbol: "cloud.sun.rain.fill", precipitationMillimeters: 5, isHeavy: false, spreadStatus: "Disarankan untuk pemupukan"),
                RainfallDay(id: "day-3", weekday: "Rab", symbol: "cloud.sun.fill", precipitationMillimeters: 0, isHeavy: false, spreadStatus: "Disarankan untuk pemupukan"),
                RainfallDay(id: "day-4", weekday: "Kam", symbol: "cloud.heavyrain.fill", precipitationMillimeters: 28, isHeavy: true, spreadStatus: "Hujan lebat"),
                RainfallDay(id: "day-5", weekday: "Jum", symbol: "cloud.sun.fill", precipitationMillimeters: 0, isHeavy: false, spreadStatus: "Disarankan untuk pemupukan"),
                RainfallDay(id: "day-6", weekday: "Sab", symbol: "cloud.heavyrain.fill", precipitationMillimeters: 32, isHeavy: true, spreadStatus: "Hujan lebat"),
                RainfallDay(id: "day-7", weekday: "Min", symbol: "cloud.sun.fill", precipitationMillimeters: 0, isHeavy: false, spreadStatus: "Disarankan untuk pemupukan")
            ],
            summary: "Tanah masih lembap setelah hujan ringan Selasa, sehingga pupuk mudah meresap. Hindari memupuk pada Kamis dan Sabtu karena hujan lebat dapat menghanyutkan pupuk.",
            heavyThresholdMillimeters: 25)
    )
}
#endif
