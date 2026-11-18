import Foundation
import Observation

@MainActor
@Observable
final class LocationSearchViewModel {
    var query: String
    private(set) var results: [GardenLocation]
    private(set) var isSearching = false
    private(set) var errorMessage: String?
    private(set) var isLocating = false
    private(set) var locationRequestID: UUID?
    private(set) var isDictating = false
    private(set) var dictationRequestID: UUID?

    private let repository: any GardenLocationRepository
    private let debounce: () async throws -> Void
    private let dictation: (any GardenSpeechDictating)?
    private let onSelect: (GardenLocation) -> Void
    private var searchRequestID: UUID?

    init(repository: any GardenLocationRepository,
         initialQuery: String = "", initialResults: [GardenLocation] = [],
         debounce: @escaping () async throws -> Void = { try await Task.sleep(for: .milliseconds(350)) },
         dictation: (any GardenSpeechDictating)? = nil,
         onSelect: @escaping (GardenLocation) -> Void) {
        self.repository = repository
        query = initialQuery
        results = initialResults
        self.debounce = debounce
        self.dictation = dictation
        self.onSelect = onSelect
    }

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

    // MARK: Voice search

    /// Whether the microphone button is shown.
    var canDictate: Bool { dictation != nil }

    /// Starts listening, or stops it when already listening.
    func toggleDictation() {
        guard let dictation else { return }
        if isDictating {
            dictation.stop()
            return
        }
        errorMessage = nil
        isDictating = true
        dictationRequestID = UUID()
    }

    /// Writes what the farmer says into `query`, so the normal search runs on it.
    func dictateIfRequested() async {
        guard let dictation, let requestID = dictationRequestID, isDictating else { return }
        defer { if dictationRequestID == requestID { isDictating = false } }
        do {
            for try await text in dictation.transcripts() {
                guard dictationRequestID == requestID else { return }
                query = text
            }
        } catch {
            guard !Task.isCancelled, dictationRequestID == requestID else { return }
            errorMessage = Self.dictationMessage(for: error)
        }
    }

    private static func dictationMessage(for error: any Error) -> String {
        switch error as? GardenSpeechDictationError {
        case .notAuthorized: "Izinkan mikrofon dan pengenalan suara di Pengaturan untuk mencari dengan suara."
        case .unavailable: "Pencarian suara belum bisa dipakai. Ketik nama tempat di kolom pencarian."
        case nil: "Suara belum terdengar jelas. Coba lagi atau ketik nama tempat."
        }
    }

    func cancelPendingWork() {
        if isDictating { dictation?.stop() }
        searchRequestID = nil
        locationRequestID = nil
        dictationRequestID = nil
        isSearching = false
        isLocating = false
        isDictating = false
    }
}
