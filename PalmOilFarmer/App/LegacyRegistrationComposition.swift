import Foundation

// Keep existing reference/experiment call sites while production injects its factory.
extension RegistrationIntroView {
    init(initialStep: Step = .guide, onLocate: @escaping (GardenLocation) -> Void) {
        self.init(viewModel: GardenRegistrationFactory(services: GardenRegistrationFactory.liveServices).makeViewModel(
            initialStep: initialStep, onLocate: onLocate, onCancel: {}
        ))
    }
}

extension LocationSearchView {
    init(initialQuery: String = "", initialResults: [GardenLocation]? = nil,
         searchLocations: ((String) async throws -> [GardenLocation])? = nil,
         onSelect: @escaping (GardenLocation) -> Void) {
        let factory = GardenRegistrationFactory {
            let services = GardenRegistrationFactory.liveServices()
            return GardenRegistrationServices(
                locations: LegacyLocationSearchRepository(
                    base: services.locations, fixedResults: initialResults, search: searchLocations
                ),
                photos: services.photos,
                dictation: services.dictation
            )
        }
        self.init(viewModel: factory.makeViewModel(
            initialStep: .search, initialQuery: initialQuery, initialResults: initialResults ?? [],
            onLocate: onSelect, onCancel: {}
        ))
    }
}

extension GardenPhotoPickerView {
    init(onSelect: @escaping (GardenCoordinate) -> Void) {
        self.init(viewModel: GardenPhotoPickerViewModel(repository: PhotosGardenPhotoRepository(), onSelect: { onSelect($0.coordinate) }))
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
    func location(at coordinate: GardenCoordinate) async -> GardenLocation { await base.location(at: coordinate) }
}
