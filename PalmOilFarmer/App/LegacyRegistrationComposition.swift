import Foundation

// Keep existing reference/experiment call sites while production injects its factory.
extension RegistrationIntroView {
    init(initialStep: Step = .guide, onLocate: @escaping (GardenLocation) -> Void) {
        self.init(flow: GardenRegistrationFactory(services: GardenRegistrationFactory.liveServices).makeFlow(
            initialStep: initialStep, onLocate: onLocate, onCancel: {}
        ))
    }
}

extension LocationSearchView {
    init(initialQuery: String = "", initialResults: [GardenLocation]? = nil,
         initialPhotoStatus: PhotoStatus = .idle,
         searchLocations: ((String) async throws -> [GardenLocation])? = nil,
         onSelect: @escaping (GardenLocation) -> Void) {
        let factory = GardenRegistrationFactory {
            let services = GardenRegistrationFactory.liveServices()
            return GardenRegistrationServices(
                locations: LegacyLocationSearchRepository(
                    base: services.locations, fixedResults: initialResults, search: searchLocations
                ),
                photos: services.photos
            )
        }
        self.init(flow: factory.makeFlow(
            initialStep: .search, initialQuery: initialQuery, initialResults: initialResults ?? [],
            initialPhotoStatus: initialPhotoStatus, onLocate: onSelect, onCancel: {}
        ))
    }
}

extension GardenPhotoPickerView {
    init(onSelect: @escaping (GardenCoordinate) -> Void) {
        self.init(viewModel: GardenPhotoPickerViewModel(repository: PhotosGardenPhotoRepository(), onSelect: onSelect))
    }
}

@MainActor
private struct LegacyLocationSearchRepository: GardenLocationRepository {
    let base: any GardenLocationRepository
    let fixedResults: [GardenLocation]?
    let search: ((String) async throws -> [GardenLocation])?

    func search(_ query: String) async throws -> [GardenLocation] {
        if let fixedResults { return fixedResults }
        if let search { return try await search(query) }
        return try await base.search(query)
    }

    func currentLocation() async throws -> GardenLocation { try await base.currentLocation() }
}
