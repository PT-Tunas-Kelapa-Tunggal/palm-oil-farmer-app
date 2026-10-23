import Foundation
import CoreLocation
import Testing
@testable import PalmOilFarmer

@MainActor
struct UserTestingFlowTests {
    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func location() -> GardenLocation {
        GardenLocation(name: "Malang rapat", subtitle: "Gunung Kijang, Bintan",
                       coordinate: GardenCoordinate(CLLocationCoordinate2D(latitude: 1.05, longitude: 104.6)))
    }

    private func squareGarden() -> Garden {
        let points = [(0.0, 0.0), (0.0, 0.002), (0.002, 0.002), (0.002, 0.0)].map {
            GardenCoordinate(CLLocationCoordinate2D(latitude: 1 + $0.0, longitude: 104 + $0.1))
        }
        return Garden(id: UUID(), name: "Belakang rumah", locationName: "Bintan",
                      boundary: GardenBoundary(points: points), plantingYear: 2016, soilType: .peat)
    }

    @Test func draftsPersistApartFromGardensAndCompletingOneRemovesIt() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "gardens.json")
        let store = GardenStore(fileURL: file)
        let draft = GardenDraft(location: location())
        #expect(store.addDraft(draft))
        #expect(!FileManager.default.fileExists(atPath: file.path))

        let reopened = GardenStore(fileURL: file)
        #expect(reopened.drafts.map(\.id) == [draft.id])
        #expect(reopened.drafts.first?.location.source == .draft)
        #expect(reopened.drafts.first?.location.draftID == draft.id)

        #expect(reopened.add(squareGarden(), completingDraft: draft.id))
        #expect(reopened.drafts.isEmpty)
        #expect(GardenStore(fileURL: file).drafts.isEmpty)
        #expect(GardenStore(fileURL: file).gardens.count == 1)
    }

    @Test func unreadableDraftsAreNotOverwritten() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let draftFile = directory.appending(path: "garden-drafts.json")
        try Data("not JSON".utf8).write(to: draftFile)
        let store = GardenStore(fileURL: directory.appending(path: "gardens.json"))
        #expect(store.errorMessage != nil)
        #expect(!store.addDraft(GardenDraft(location: location())))
        #expect(try Data(contentsOf: draftFile) == Data("not JSON".utf8))
        // Gardens remain writable when only the drafts file is unreadable.
        #expect(store.add(squareGarden()))
    }

    @Test func reviewSurvivesSaveAndAdvancesOneStageAtATime() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "gardens.json")
        let store = GardenStore(fileURL: file)
        var garden = squareGarden()
        #expect(store.add(garden))

        let submitted = Date(timeIntervalSince1970: 1_800_000_000)
        var review = GardenReview(contact: ReviewContactDetails(name: "Budi", phone: "085048384438", address: "Bintan"),
                                  submittedAt: submitted)
        review.advance(now: submitted.addingTimeInterval(3_600))
        garden.review = review
        #expect(store.update(garden))

        let loaded = try #require(GardenStore(fileURL: file).gardens.first?.review)
        #expect(loaded.status == .scheduled)
        #expect(loaded.contact.name == "Budi")
        #expect(loaded.date(for: .submitted) == submitted)
        #expect(loaded.visitDate == Calendar.current.date(byAdding: .day, value: 1, to: submitted.addingTimeInterval(3_600)))

        var finished = loaded
        for _ in 0..<5 { finished.advance() }
        #expect(finished.status == .completed)
        #expect(!finished.isInProgress)
        let entries = ReviewTimelineEntry.entries(for: finished)
        #expect(entries.allSatisfy { $0.isReached })
    }

    @Test func gardenSavedBeforeReviewsStillDecodes() throws {
        let legacy = Data("""
        [{"id":"5C8F2B1E-7A44-4C8A-9F1D-2B6E3C4D5A6B","name":"Lama","locationName":"Dumai",
          "boundary":{"points":[]},"plantingYear":2016,"soilType":"Gambut"}]
        """.utf8)
        let gardens = try JSONDecoder().decode([Garden].self, from: legacy)
        #expect(gardens.first?.review == nil)
        #expect(gardens.first?.soilType == .peat)
    }

    @Test func demoReportCodesSixAreasFromTheBoundary() {
        let report = DemoReviewReport.make(for: squareGarden())
        #expect(report.areas.map(\.id) == ["AA", "AB", "BA", "BB", "CA", "CB"])
        #expect(report.areas.allSatisfy { $0.zone != nil && $0.periods.count == 2 })
        #expect(report.outline.count == 4)
        #expect(report.rainfall?.days.count == 7)
        #expect(report.nutrients.allSatisfy { NutrientReference.reference(for: $0.name) != nil })
    }
}

@MainActor
struct AreaOutlineTests {
    @Test func outlineDropsEdgesSharedBetweenFragments() {
        let corners = [(0.0, 0.0), (0.0, 1.0), (1.0, 1.0), (1.0, 0.0)].map {
            CLLocationCoordinate2D(latitude: $0.0, longitude: $0.1)
        }
        // A square split into two triangles along one diagonal.
        let zone = WaypointZone(id: 1, fragments: [[corners[0], corners[1], corners[2]], [corners[0], corners[2], corners[3]]],
                                destination: corners[0], areaSquareMeters: 1)
        #expect(zone.outlineSegments.count == 4)
    }

    @Test func tappedCoordinateFindsItsArea() {
        let report = DemoReviewReport.make(for: Garden(
            id: UUID(), name: "Uji", locationName: "Bintan",
            boundary: GardenBoundary(points: [(0.0, 0.0), (0.0, 0.002), (0.002, 0.002), (0.002, 0.0)].map {
                GardenCoordinate(CLLocationCoordinate2D(latitude: 1 + $0.0, longitude: 104 + $0.1))
            }),
            plantingYear: 2016, soilType: .peat
        ))
        for area in report.areas {
            let destination = try! #require(area.zone).destination
            #expect(report.areas.filter { $0.zone?.contains(destination) == true }.map(\.id) == [area.id])
        }
        #expect(report.areas.allSatisfy { $0.zone?.contains(CLLocationCoordinate2D(latitude: 0, longitude: 0)) == false })
    }
}

struct NutrientLinkTests {
    @Test func everyNutrientNameInTheSummaryIsLinked() {
        let text = NutrientLinkedText.linked("Kadar magnesium paling jauh, disusul Nitrogen dan kalium. Fosfor berlebih; fosfor cukup.")
        let links = text.runs.compactMap { $0.link?.host() }
        #expect(links == ["Mg", "N", "K", "P", "P"])
    }
}

struct GardenListFilterTests {
    private func garden(fertilized: Bool, harvested: Bool, review: ReviewStatus?) -> Garden {
        var garden = Garden(id: UUID(), name: "Uji", locationName: "Bintan", boundary: GardenBoundary(),
                            plantingYear: 2016, soilType: .peat)
        if fertilized { garden.fertilizerRecords = [FertilizerRecord(name: "Urea", bagWeightKg: 50, bagCount: 1, doseKgPerTree: 1)] }
        if harvested { garden.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 400) }
        if let review {
            var value = GardenReview(contact: ReviewContactDetails(name: "A", phone: "08123456789", address: "B"))
            while value.status != review { value.advance() }
            garden.review = value
        }
        return garden
    }

    @Test func eachGardenFallsIntoOneStage() {
        let incomplete = garden(fertilized: true, harvested: false, review: nil)
        let ready = garden(fertilized: true, harvested: true, review: nil)
        let reviewing = garden(fertilized: true, harvested: true, review: .scheduled)
        let done = garden(fertilized: true, harvested: true, review: .completed)
        let all = [incomplete, ready, reviewing, done]
        #expect(all.filter(GardenListFilter.incomplete.includes).map(\.id) == [incomplete.id])
        #expect(all.filter(GardenListFilter.inReview.includes).map(\.id) == [reviewing.id])
        #expect(all.filter(GardenListFilter.results.includes).map(\.id) == [done.id])
        #expect(all.filter(GardenListFilter.all.includes).count == 4)
        #expect(all.filter(GardenListFilter.draft.includes).isEmpty)
        #expect(GardenListFilter.draft.includesDrafts && !GardenListFilter.results.includesDrafts)
    }
}
