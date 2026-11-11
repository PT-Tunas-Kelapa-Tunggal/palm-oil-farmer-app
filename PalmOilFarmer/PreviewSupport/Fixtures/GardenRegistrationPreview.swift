#if DEBUG
import Foundation
import UIKit

/// Preview composition root for the GardenRegistration feature.
/// Builds flows with the same factories as production (`App/RegistrationComposition`,
/// `App/MappingComposition`) but with the dummy data sources from
/// `Features/GardenRegistration/Data/Dummy`, so every `#Preview` renders the same way,
/// offline, without permission prompts and without touching stored gardens.
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
                       source: .photo)
    }

    // MARK: Step 1 · FindLocation

    static func registrationFlow(step: GardenRegistrationStep = .guide,
                                 query: String = "",
                                 showsResults: Bool = false,
                                 locations: DummyGardenLocationRepository.Scenario = .results,
                                 photos: DummyGardenPhotoRepository.Scenario = .photos) -> GardenRegistrationFlow {
        let factory = GardenRegistrationFactory {
            GardenRegistrationServices(locations: DummyGardenLocationRepository(locations),
                                       photos: DummyGardenPhotoRepository(photos, imageData: photoImageData))
        }
        return factory.makeFlow(
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

    // MARK: Step 2 · SetBoundaries

    static func mappingFlow(location: GardenLocation) -> GardenMappingFlow {
        GardenMappingFactory(saving: DummyGardenRegistrationSaving(),
                             authorization: { DummyGardenLocationAuthorization() })
            .makeFlow(location: location, onFinish: { _ in })
    }

    // MARK: Step 3 · CompleteInformation

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
