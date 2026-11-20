#if DEBUG
import Foundation
import UIKit

/// Preview data for the registration screens: dummy data sources, so every `#Preview` renders the
/// same way, offline, without permission prompts and without touching stored gardens.
@MainActor
enum GardenRegistrationPreview {
    // MARK: Sample locations

    static var searchResults: [GardenLocation] { DummyGardenLocationRepository.sampleResults }
    static var searchLocation: GardenLocation { searchResults[0] }
    static var currentLocation: GardenLocation { DummyGardenLocationRepository.sampleCurrentLocation }
    static var photoImageData: Data? {
        UIImage(named: "RegistrationPhotoReference")?.jpegData(compressionQuality: 0.6)
    }

    static var photoLocation: GardenLocation {
        GardenLocation(name: "Malang Rapat",
                       subtitle: "Kecamatan Gunung Kijang, Kabupaten Bintan, Kepulauan Riau",
                       coordinate: GardenCoordinate(latitude: 1.104950, longitude: 104.121010),
                       source: .photo,
                       photoDate: Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 8, minute: 14)))
    }

    // MARK: Location

    static func introViewModel(step: GardenRegistrationStep = .guide,
                               query: String = "",
                               showsResults: Bool = false,
                               locations: DummyGardenLocationRepository.Scenario = .results,
                               photos: DummyGardenPhotoRepository.Scenario = .photos) -> RegistrationIntroViewModel {
        let factory = GardenRegistrationFactory {
            GardenRegistrationServices(locations: DummyGardenLocationRepository(locations),
                                       photos: DummyGardenPhotoRepository(photos, imageData: photoImageData))
        }
        return factory.makeViewModel(
            initialStep: step,
            initialQuery: query,
            initialResults: showsResults ? searchResults : [],
            onLocate: { _ in },
            onCancel: {}
        )
    }

    static func photoPickerViewModel(_ scenario: DummyGardenPhotoRepository.Scenario = .photos) -> GardenPhotoPickerViewModel {
        GardenPhotoPickerViewModel(
            repository: DummyGardenPhotoRepository(scenario, imageData: photoImageData),
            resolveLocation: { await DummyGardenLocationRepository().location(at: $0) },
            onSelect: { _ in }
        )
    }

    // MARK: Boundary

    static func boundaryViewModel(location: GardenLocation) -> GardenBoundaryViewModel {
        GardenMappingFactory(saving: DummyGardenRegistrationSaving(),
                             authorization: { DummyGardenLocationAuthorization() })
            .makeViewModel(location: location, onFinish: { _ in })
    }

    // MARK: Details

    static func detailsViewModel(editing garden: Garden? = nil) -> GardenDetailsViewModel {
        GardenDetailsViewModel(
            locationName: garden?.locationName ?? GardenPreviewData.location.name,
            boundary: garden?.boundary ?? GardenPreviewData.boundary,
            editing: garden,
            onSave: { _ in true },
            onSaved: {}
        )
    }
}
#endif
