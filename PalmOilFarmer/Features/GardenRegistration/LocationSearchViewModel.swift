import Foundation
import Observation

enum GardenPhotoStatus {
    case idle, loading, missingLocation, failed

    var message: String {
        switch self {
        case .idle: "Foto yang diambil di kebun menyimpan data lokasi, sehingga peta dapat langsung diarahkan ke kebun Anda."
        case .loading: "Memeriksa lokasi pada foto…"
        case .missingLocation: "Foto ini tidak menyimpan data lokasi. Coba foto lain yang diambil di kebun."
        case .failed: "Foto tidak dapat dibaca. Coba foto lain."
        }
    }

    var symbol: String {
        switch self {
        case .idle, .loading: "photo.on.rectangle"
        case .missingLocation, .failed: "exclamationmark.circle"
        }
    }
}

@MainActor
@Observable
final class LocationSearchViewModel {
    var query: String
    private(set) var results: [GardenLocation]
    private(set) var isSearching = false
    private(set) var errorMessage: String?
    private(set) var isLocating = false
    private(set) var locationRequestID: UUID?
    let photoStatus: GardenPhotoStatus

    private let repository: any GardenLocationRepository
    private let debounce: () async throws -> Void
    private let onSelect: (GardenLocation) -> Void
    private var searchRequestID: UUID?

    init(repository: any GardenLocationRepository,
         initialQuery: String = "", initialResults: [GardenLocation] = [],
         initialPhotoStatus: GardenPhotoStatus = .idle,
         debounce: @escaping () async throws -> Void = { try await Task.sleep(for: .milliseconds(350)) },
         onSelect: @escaping (GardenLocation) -> Void) {
        self.repository = repository
        query = initialQuery
        results = initialResults
        photoStatus = initialPhotoStatus
        self.debounce = debounce
        self.onSelect = onSelect
    }

    var hasQuery: Bool { !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func search() async {
        let requestID = UUID()
        searchRequestID = requestID
        results = []
        errorMessage = nil
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { isSearching = false; return }
        isSearching = true
        defer { if searchRequestID == requestID { isSearching = false } }
        do {
            try await debounce()
            try Task.checkCancellation()
            let locations = try await repository.search(text)
            try Task.checkCancellation()
            guard searchRequestID == requestID, query.trimmingCharacters(in: .whitespacesAndNewlines) == text else { return }
            results = locations
        } catch {
            guard !Task.isCancelled, !(error is CancellationError), searchRequestID == requestID,
                  query.trimmingCharacters(in: .whitespacesAndNewlines) == text else { return }
            errorMessage = "Pencarian gagal. Periksa koneksi internet lalu coba lagi."
        }
    }

    func selectResult(_ location: GardenLocation) { onSelect(location) }

    func requestCurrentLocation() {
        guard !isLocating else { return }
        isLocating = true
        locationRequestID = UUID()
    }

    func locateCurrentIfRequested() async {
        guard let requestID = locationRequestID, isLocating else { return }
        defer { if locationRequestID == requestID { isLocating = false } }
        do {
            let location = try await repository.currentLocation()
            try Task.checkCancellation()
            guard locationRequestID == requestID else { return }
            onSelect(location)
        } catch {
            guard !Task.isCancelled, !(error is CancellationError), locationRequestID == requestID else { return }
            errorMessage = "Lokasi tidak dapat diperoleh. Periksa izin lokasi dan coba lagi."
        }
    }

    func cancelPendingWork() {
        searchRequestID = nil
        locationRequestID = nil
        isSearching = false
        isLocating = false
    }
}
