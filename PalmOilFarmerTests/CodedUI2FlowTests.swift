import Foundation
import CoreLocation
import Testing
@testable import PalmOilFarmer

@MainActor
struct CodedUI2FlowTests {
    private func temporaryDirectory() throws -> URL {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @Test func deferredMappingSurvivesRelaunchAndCanBeRemoved() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "drafts.json")
        let location = GardenLocation(name: "Desa uji", subtitle: "Bintan",
            coordinate: GardenCoordinate(CLLocationCoordinate2D(latitude: 1.1, longitude: 104.4)))
        let draft = MappingDraft(location: location, boundary: GardenBoundary())
        #expect(MappingDraftStore(fileURL: url).save(draft))
        let reloaded = MappingDraftStore(fileURL: url)
        #expect(reloaded.drafts.count == 1)
        #expect(reloaded.drafts.first?.location.coordinate.latitude == 1.1)
        #expect(reloaded.drafts.first?.location.source == .search)
        #expect(reloaded.remove(id: draft.id))
        #expect(MappingDraftStore(fileURL: url).drafts.isEmpty)
    }

    @Test func unreadableDraftCannotBeOverwrittenAfterDismissingError() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "drafts.json")
        let original = Data("unreadable".utf8)
        try original.write(to: url)
        let store = MappingDraftStore(fileURL: url)
        store.errorMessage = nil
        #expect(!store.remove(id: UUID()))
        #expect(try Data(contentsOf: url) == original)
    }

    @Test func failedDraftSaveDoesNotPublishSuccess() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = MappingDraftStore(fileURL: directory.appending(path: "missing/drafts.json"))
        let draft = MappingDraft(location: GardenLocation(name: "Uji", subtitle: "",
            coordinate: GardenCoordinate(CLLocationCoordinate2D(latitude: 1, longitude: 104))), boundary: GardenBoundary())
        #expect(!store.save(draft))
        #expect(store.drafts.isEmpty)
        #expect(store.errorMessage != nil)
    }

    @Test func legacyGardenAndReviewReportRoundTrip() throws {
        var garden = Garden(id: UUID(), name: "Uji", locationName: "Bintan",
            boundary: GardenBoundary(), plantingYear: 2016, soilType: .peat)
        let oldData = try JSONEncoder().encode(garden)
        #expect(try JSONDecoder().decode(Garden.self, from: oldData).review == nil)
        let report = FertilizerRecommendationReport(gardenName: "Uji", locationName: "Bintan",
            boundary: GardenBoundary(), outline: [], nutrients: [], costs: [], totalCost: "", areas: [])
        garden.review = GardenReview(requestID: "request-1", status: .completed, entries: [], report: report)
        let decoded = try JSONDecoder().decode(Garden.self, from: JSONEncoder().encode(garden))
        #expect(decoded.review?.requestID == "request-1")
        #expect(decoded.review?.status == .completed)
        #expect(decoded.review?.report?.gardenName == "Uji")
    }

    @Test func reviewResponsePreservesLatestGardenHistory() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = GardenStore(fileURL: directory.appending(path: "gardens.json"))
        var garden = Garden(id: UUID(), name: "Uji", locationName: "Bintan",
            boundary: GardenBoundary(), plantingYear: 2016, soilType: .peat)
        #expect(store.add(garden))
        garden.harvestRecord = HarvestRecord(frequencyPerMonth: 3, latestWeightKg: 500)
        #expect(store.update(garden))
        let review = GardenReview(requestID: "request-1", status: .scheduled, entries: [])
        #expect(store.updateReview(review, for: garden.id))
        #expect(store.gardens.first?.harvestRecord?.latestWeightKg == 500)
        #expect(store.gardens.first?.review?.status == .scheduled)
    }

    @Test func localReviewSurvivesReopeningEachStageAndStaysPerGarden() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "gardens.json")
        let first = Garden(id: UUID(), name: "Kebun A", locationName: "Bintan",
            boundary: GardenBoundary(), plantingYear: 2016, soilType: .peat)
        let second = Garden(id: UUID(), name: "Kebun B", locationName: "Dumai",
            boundary: GardenBoundary(), plantingYear: 2020, soilType: .mineral)
        let initial = GardenStore(fileURL: url)
        #expect(initial.add(first))
        #expect(initial.add(second))
        for status in ReviewStatus.allCases {
            let store = GardenStore(fileURL: url)
            #expect(store.updateReview(.localSimulation(for: first.id, status: status), for: first.id))
            let reopened = GardenStore(fileURL: url)
            let saved = try #require(reopened.gardens.first { $0.id == first.id })
            #expect(saved.review?.status == status)
            #expect(saved.review?.isLocalSimulation == true)
            #expect(saved.review?.requestID == "local-" + first.id.uuidString)
            #expect(saved.review?.entries.filter(\.isReached).count == status.rawValue + 1)
            #expect(reopened.gardens.first { $0.id == second.id }?.review == nil)
            #expect(FertilizerRecommendationReport.local(for: saved).gardenName == first.name)
        }
    }

    @Test func failedLocalReviewWriteDoesNotAdvancePublishedStatus() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "gardens.json")
        let garden = Garden(id: UUID(), name: "Uji", locationName: "Bintan",
            boundary: GardenBoundary(), plantingYear: 2016, soilType: .peat)
        let store = GardenStore(fileURL: url)
        #expect(store.add(garden))
        #expect(store.updateReview(.localSimulation(for: garden.id), for: garden.id))
        let backup = directory.appending(path: "backup.json")
        try FileManager.default.moveItem(at: url, to: backup)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        #expect(!store.updateReview(.localSimulation(for: garden.id, status: .completed), for: garden.id))
        #expect(store.gardens.first?.review?.status == .submitted)
        #expect(store.errorMessage != nil)
        #expect(GardenStore(fileURL: backup).gardens.first?.review?.status == .submitted)
    }

    @Test func legacyReviewWithoutSimulationMarkerStillLoads() throws {
        let data = Data(#"{"requestID":"server-1","status":0,"entries":[]}"#.utf8)
        let review = try JSONDecoder().decode(GardenReview.self, from: data)
        #expect(review.isLocalSimulation == nil)
        #expect(review.requestID == "server-1")
    }

    @Test func unavailableReviewServiceNeverReturnsSubmittedStatus() async {
        let garden = Garden(id: UUID(), name: "Uji", locationName: "Bintan",
            boundary: GardenBoundary(), plantingYear: 2016, soilType: .peat)
        do {
            _ = try await ReviewService.unavailable.submit(garden,
                ReviewContactDetails(name: "Uji", phone: "0800000000", address: "Alamat uji"))
            Issue.record("An unavailable service must not report submission success.")
        } catch {
            #expect(error is ReviewServiceError)
        }
    }
}
