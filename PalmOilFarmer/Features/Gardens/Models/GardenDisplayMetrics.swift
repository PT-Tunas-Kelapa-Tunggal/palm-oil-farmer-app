import Foundation

struct GardenDisplayMetrics {
    let area: String
    let perimeter: String

    init(boundary: GardenBoundary) {
        area = boundary.areaHectares.formatted(.number.precision(.fractionLength(0...1))) + " ha"
        perimeter = boundary.perimeterMeters.formatted(.number.precision(.fractionLength(0))) + " m"
    }

    init(area: String, perimeter: String) {
        self.area = area
        self.perimeter = perimeter
    }
}

