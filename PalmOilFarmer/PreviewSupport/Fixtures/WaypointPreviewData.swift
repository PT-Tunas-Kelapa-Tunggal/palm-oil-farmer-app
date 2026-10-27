import MapKit

#if DEBUG
enum WaypointPreviewData {
    static var garden: Garden {
        let coordinates = [
            CLLocationCoordinate2D(latitude: -6.599, longitude: 106.799),
            CLLocationCoordinate2D(latitude: -6.599, longitude: 106.801),
            CLLocationCoordinate2D(latitude: -6.602, longitude: 106.801),
            CLLocationCoordinate2D(latitude: -6.602, longitude: 106.799)
        ]
        return Garden(id: UUID(), name: "Kebun Contoh", locationName: "Data demo • Bogor",
                      boundary: GardenBoundary(points: coordinates.map(GardenCoordinate.init)),
                      plantingYear: 2020, soilType: .mineral)
    }
}
#endif
