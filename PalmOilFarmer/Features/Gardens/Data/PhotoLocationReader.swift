import Foundation
import ImageIO
import CoreLocation

enum PhotoLocationReader {
    static func coordinate(in data: Data) -> GardenCoordinate? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
              let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double else {
            return nil
        }

        let latitudeSign = (gps[kCGImagePropertyGPSLatitudeRef as String] as? String) == "S" ? -1.0 : 1.0
        let longitudeSign = (gps[kCGImagePropertyGPSLongitudeRef as String] as? String) == "W" ? -1.0 : 1.0
        let coordinate = CLLocationCoordinate2D(
            latitude: latitude * latitudeSign,
            longitude: longitude * longitudeSign
        )
        guard CLLocationCoordinate2DIsValid(coordinate) else { return nil }
        return GardenCoordinate(coordinate)
    }
}
