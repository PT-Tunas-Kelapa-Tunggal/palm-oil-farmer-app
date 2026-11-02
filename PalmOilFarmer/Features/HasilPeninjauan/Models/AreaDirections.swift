import Foundation

/// Display data for walking to one area. Outline points are fractions of the screen.
struct AreaDirections {
    let mapImage: String
    let area: ReviewResult.Area
    let distance: String
}

#if DEBUG
extension AreaDirections {
    /// Example values from the design. Pixel positions match a 402×874 screen.
    static let sample = AreaDirections(
        mapImage: "CompleteSatelliteSource",
        area: ReviewResult.Area(id: 2, outline: [
            CGPoint(x: 152.0 / 402, y: 318.0 / 874),
            CGPoint(x: 300.0 / 402, y: 376.0 / 874),
            CGPoint(x: 258.0 / 402, y: 478.0 / 874),
            CGPoint(x: 110.0 / 402, y: 428.0 / 874)
        ]),
        distance: "120m"
    )
}
#endif
