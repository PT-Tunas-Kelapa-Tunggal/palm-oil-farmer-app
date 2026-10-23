#if DEBUG
import Foundation
import CoreLocation

/// Shared sample data for Canvas previews; never reads or writes stored gardens.
enum GardenPreviewData {
    static let location = GardenLocation(
        name: "Dumai",
        subtitle: "Riau, Indonesia",
        coordinate: GardenCoordinate(CLLocationCoordinate2D(latitude: 1.667, longitude: 101.447))
    )

    static let boundary = GardenBoundary(points: [
        GardenCoordinate(CLLocationCoordinate2D(latitude: 1.667, longitude: 101.447)),
        GardenCoordinate(CLLocationCoordinate2D(latitude: 1.667, longitude: 101.449)),
        GardenCoordinate(CLLocationCoordinate2D(latitude: 1.665, longitude: 101.449)),
        GardenCoordinate(CLLocationCoordinate2D(latitude: 1.665, longitude: 101.447))
    ])

    static let garden = Garden(
        id: UUID(),
        name: "Belakang rumah",
        locationName: location.name,
        boundary: boundary,
        plantingYear: 2016,
        soilType: .peat
    )
    static let metrics = GardenDisplayMetrics(area: "2,3 ha", perimeter: "2300 m")
    static let gardens = [garden, Garden(
        id: UUID(), name: garden.name, locationName: garden.locationName,
        boundary: boundary, plantingYear: 2016, soilType: .peat
    )]
    static let fertilizers = [
        FertilizerRecord(name: "Dolomit Super", bagWeightKg: 50, bagCount: 6, doseKgPerTree: 1),
        FertilizerRecord(name: "Urea", bagWeightKg: 50, bagCount: 6, doseKgPerTree: 0.5),
        FertilizerRecord(name: "NPK 15-15-15", bagWeightKg: 50, bagCount: 6, doseKgPerTree: 0.5)
    ]
    static let harvest = HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 420)

    static var fertilizedGarden: Garden {
        var sample = garden
        sample.fertilizerRecords = fertilizers
        return sample
    }
    static var completedGarden: Garden {
        var sample = fertilizedGarden
        sample.harvestRecord = harvest
        return sample
    }
}
#endif
