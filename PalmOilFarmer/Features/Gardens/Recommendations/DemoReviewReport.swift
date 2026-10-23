import Foundation
import CoreLocation

/// Sample review results for user testing. No review service exists yet, so nutrient levels,
/// prices, and rainfall are fixed examples; only the outline, areas, and quantities follow the garden.
enum DemoReviewReport {
    private static let treesPerHectare = 136.0
    private static let fertilizers: [(name: String, kgPerHectare: Double, pricePerKg: Double, dosePerTree: Double)] = [
        ("Urea", 50, 7_000, 1.5),
        ("KCl(MOP)", 56, 6_500, 1.5),
        ("Kiserite", 22, 5_000, 1)
    ]

    static func make(for garden: Garden, now: Date = .now) -> FertilizerRecommendationReport {
        let hectares = max(garden.boundary.areaHectares, 0.1)
        let costs = fertilizers.map { fertilizer in
            let kilograms = (fertilizer.kgPerHectare * hectares).rounded()
            return (line: FertilizerCostLine(name: fertilizer.name, quantity: kilograms.formatted(),
                                             cost: rupiah(kilograms * fertilizer.pricePerKg)),
                    cost: kilograms * fertilizer.pricePerKg)
        }
        return FertilizerRecommendationReport(
            gardenName: garden.name,
            locationName: garden.locationName,
            boundary: garden.boundary,
            outline: outline(of: garden.boundary),
            nutrients: [
                NutrientProjection(name: "N", current: 0.4, target: 0.64, status: "Kurang"),
                NutrientProjection(name: "P", current: 1, target: 0.64, status: "Berlebih"),
                NutrientProjection(name: "K", current: 0.48, target: 0.64, status: "Kurang"),
                NutrientProjection(name: "Mg", current: 0.21, target: 0.64, status: "Sangat kurang")
            ],
            nutrientSummary: "Kadar magnesium paling jauh di bawah kebutuhan, disusul nitrogen dan kalium. Fosfor sudah melebihi kebutuhan, jadi tidak perlu pupuk fosfor.",
            costs: costs.map(\.line),
            totalCost: rupiah(costs.map(\.cost).reduce(0, +)),
            areas: areas(for: garden.boundary),
            rainfall: rainfall(startingFrom: now)
        )
    }

    /// Areas follow the six equal-area zones, coded by row (A–C) and column (A–B).
    static func areas(for boundary: GardenBoundary) -> [FertilizerAllocationArea] {
        WaypointZoning.zones(for: boundary).map { zone in
            let trees = zone.areaSquareMeters / 10_000 * treesPerHectare
            let lines = fertilizers.map { fertilizer in
                FertilizerAllocationLine(
                    name: fertilizer.name,
                    total: "Total \(fertilizer.name) dibutuhkan \((trees * fertilizer.dosePerTree).rounded().formatted()) kg",
                    dosage: "\(fertilizer.dosePerTree.formatted()) kg / pohon"
                )
            }
            return FertilizerAllocationArea(
                id: code(for: zone.id), mapImage: nil,
                periods: [
                    FertilizerAllocationPeriod(title: "Periode 1", dateRange: "Januari - Maret", lines: lines),
                    FertilizerAllocationPeriod(title: "Periode 2", dateRange: "Juni - Agustus", lines: lines)
                ],
                zone: zone
            )
        }
    }

    static func code(for zoneID: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        let row = (zoneID - 1) / 2, column = (zoneID - 1) % 2
        guard letters.indices.contains(row) else { return "\(zoneID)" }
        return letters[row] + letters[column]
    }

    static func rainfall(startingFrom date: Date) -> RainfallForecast {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = ReviewDateFormat.indonesian
        calendar.timeZone = ReviewDateFormat.jakarta
        calendar.firstWeekday = 2
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let day = Date.VerbatimFormatStyle(format: "\(day: .defaultDigits)", locale: ReviewDateFormat.indonesian,
                                           timeZone: ReviewDateFormat.jakarta, calendar: calendar)
        let dayMonth = Date.VerbatimFormatStyle(format: "\(day: .defaultDigits) \(month: .wide)",
                                                locale: ReviewDateFormat.indonesian,
                                                timeZone: ReviewDateFormat.jakarta, calendar: calendar)
        let sameMonth = calendar.component(.month, from: start) == calendar.component(.month, from: end)
        let range = "\(start.formatted(sameMonth ? day : dayMonth))–\(end.formatted(dayMonth))"

        var advice = AttributedString("Tanah masih lembap setelah hujan ringan ")
        advice += bold("Selasa")
        advice += AttributedString(", sehingga pupuk mudah meresap. Hindari memupuk pada ")
        advice += bold("Kamis")
        advice += AttributedString(" dan ")
        advice += bold("Sabtu")
        advice += AttributedString(" karena hujan lebat dapat menghanyutkan pupuk.")

        return RainfallForecast(
            dateRange: range,
            headline: "Hujan lebat pada Kamis dan Sabtu",
            days: zip(["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"], [2.0, 8, 1, 28, 4, 32, 3])
                .map { RainfallDay(weekday: $0, millimeters: $1) },
            advice: advice
        )
    }

    private static func bold(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.inlinePresentationIntent = .stronglyEmphasized
        return attributed
    }

    private static func outline(of boundary: GardenBoundary) -> [CGPoint] {
        let latitudes = boundary.points.map(\.latitude), longitudes = boundary.points.map(\.longitude)
        guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
              let minLon = longitudes.min(), let maxLon = longitudes.max(),
              maxLat > minLat, maxLon > minLon else { return [] }
        return boundary.points.map {
            CGPoint(x: ($0.longitude - minLon) / (maxLon - minLon), y: (maxLat - $0.latitude) / (maxLat - minLat))
        }
    }

    private static func rupiah(_ value: Double) -> String {
        "Rp" + value.rounded().formatted(.number.locale(ReviewDateFormat.indonesian))
    }
}
