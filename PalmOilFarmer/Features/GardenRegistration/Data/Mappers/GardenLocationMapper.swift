import CoreLocation
import MapKit

/// (3) Mapper: raw MapKit results (`MKMapItem`) → domain model `GardenLocation`.
/// MapKit types never leave the Data layer.
enum GardenLocationMapper {
    /// A forward-search result. `fallbackName` is the user's query when MapKit has no name.
    static func location(from item: MKMapItem, fallbackName: String) -> GardenLocation {
        GardenLocation(
            name: item.name ?? fallbackName,
            subtitle: item.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true) ?? "Indonesia",
            coordinate: gardenCoordinate(item.location.coordinate)
        )
    }

    /// A reverse-geocoded device or photo position. Falls back to a generic label offline.
    static func location(from item: MKMapItem?, at coordinate: CLLocationCoordinate2D) -> GardenLocation {
        let fallback = GardenLocation(name: "Lokasi saat ini", subtitle: "", coordinate: gardenCoordinate(coordinate))
        guard let item else { return fallback }
        return GardenLocation(
            name: item.name ?? fallback.name,
            subtitle: item.addressRepresentations?.cityWithContext ?? "",
            coordinate: gardenCoordinate(coordinate)
        )
    }

    static func gardenCoordinate(_ coordinate: CLLocationCoordinate2D) -> GardenCoordinate {
        GardenCoordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
