import Foundation
@testable import PalmOilFarmer

/// Intentionally ignores task cancellation so tests can deliver late framework responses.
@MainActor
final class ControlledLocationRepository: GardenLocationRepository {
    private var searches: [String: CheckedContinuation<[GardenLocation], Error>] = [:]
    private var searchWaiters: [String: CheckedContinuation<Void, Never>] = [:]
    private var current: CheckedContinuation<GardenLocation, Error>?
    private var currentWaiter: CheckedContinuation<Void, Never>?

    func search(_ query: String) async throws -> [GardenLocation] {
        try await withCheckedThrowingContinuation {
            searches[query] = $0
            searchWaiters.removeValue(forKey: query)?.resume()
        }
    }

    func currentLocation() async throws -> GardenLocation {
        try await withCheckedThrowingContinuation {
            current = $0
            currentWaiter?.resume()
            currentWaiter = nil
        }
    }

    func location(at coordinate: GardenCoordinate) async -> GardenLocation {
        GardenLocation(name: "Lokasi dari foto", subtitle: "Foto kebun", coordinate: coordinate, source: .photo)
    }

    func waitForSearch(_ query: String) async {
        if searches[query] != nil { return }
        await withCheckedContinuation { searchWaiters[query] = $0 }
    }

    func finishSearch(_ query: String, with result: Result<[GardenLocation], Error>) {
        searches.removeValue(forKey: query)?.resume(with: result)
    }

    func waitForCurrentLocation() async {
        if current != nil { return }
        await withCheckedContinuation { currentWaiter = $0 }
    }

    func finishCurrentLocation(with result: Result<GardenLocation, Error>) {
        let pending = current
        current = nil
        pending?.resume(with: result)
    }
}

@MainActor
final class ControlledPhotoRepository: GardenPhotoRepository {
    private var loads: [Int: CheckedContinuation<GardenPhotoLibrarySnapshot, Never>] = [:]
    private var waiters: [Int: CheckedContinuation<Void, Never>] = [:]
    private var loadCount = 0

    func loadPhotos() async -> GardenPhotoLibrarySnapshot {
        loadCount += 1
        let id = loadCount
        return await withCheckedContinuation {
            loads[id] = $0
            waiters.removeValue(forKey: id)?.resume()
        }
    }

    func waitForLoad(_ id: Int) async {
        if loads[id] != nil { return }
        await withCheckedContinuation { waiters[id] = $0 }
    }

    func finishLoad(_ id: Int, with snapshot: GardenPhotoLibrarySnapshot) {
        loads.removeValue(forKey: id)?.resume(returning: snapshot)
    }

    func thumbnails(for photoID: String) -> AsyncStream<Data> { AsyncStream { $0.finish() } }
}
