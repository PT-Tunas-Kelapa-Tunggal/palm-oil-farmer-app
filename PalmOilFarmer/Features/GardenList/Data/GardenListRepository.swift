import Foundation
import CoreLocation

protocol GardenListRepository {
    var gardens: [Garden] { get }
}

/// In-memory sample source for previews and local UI work. It never reads or writes
/// the app's persisted garden file.
struct DummyGardenListRepository: GardenListRepository {
    let gardens: [Garden]

    init(gardens: [Garden] = Self.sampleGardens) {
        self.gardens = gardens
    }

    static let sampleGardens: [Garden] = [
        Garden(
            id: UUID(uuidString: "A91D5B38-1A74-4F02-8D18-1BC0D5A11A01")!,
            name: "Kebun Pak Sutrisno",
            locationName: "Bintan",
            boundary: GardenBoundary(points: [
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1.66655, longitude: 101.44855)),
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1.66655, longitude: 101.44945)),
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1.66745, longitude: 101.44945)),
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1.66745, longitude: 101.44855))
            ]),
            plantingYear: 2009,
            soilType: .mineral,
            review: nil
        ),
    ]
}
