import Foundation
import CoreLocation
import Testing
import SwiftData
@testable import PalmOilFarmer

@MainActor
struct UserTestingFlowTests {
    private func makeContainer() -> ModelContainer {
        AppConfiguration.makeModelContainer(inMemory: true)
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
        let container = makeContainer()
        let store = makeTestGardenStore(in: container)
        let draft = GardenDraft(location: location())
        #expect(store.addDraft(draft))

        let reopened = makeTestGardenStore(in: container)
        #expect(reopened.drafts.map(\.id) == [draft.id])
        #expect(reopened.drafts.first?.location.source == .draft)
        #expect(reopened.drafts.first?.location.draftID == draft.id)

        #expect(reopened.add(squareGarden(), completingDraft: draft.id))
        #expect(reopened.drafts.isEmpty)
        #expect(makeTestGardenStore(in: container).drafts.isEmpty)
        #expect(makeTestGardenStore(in: container).gardens.count == 1)
    }

    @Test func eraseAllClearsGardensAndDrafts() throws {
        let container = makeContainer()
        let store = makeTestGardenStore(in: container)
        #expect(store.addDraft(GardenDraft(location: location())))
        #expect(store.add(squareGarden()))
        #expect(!store.gardens.isEmpty && !store.drafts.isEmpty)

        store.eraseAll()
        #expect(store.gardens.isEmpty && store.drafts.isEmpty)
        let reopened = makeTestGardenStore(in: container)
        #expect(reopened.gardens.isEmpty && reopened.drafts.isEmpty)
    }

    @Test func plantationDomainMapperMapsToGardenWithReview() throws {
        let mapper = PlantationDomainMapper()
        let request = PlantationReviewRequest(
            farmer: FarmerContact(name: "Pak Budi", phone: "08123456789", address: "Riau"),
            garden: GardenSummary(id: UUID(), name: "Kebun Kelapa Sawit", locationName: "Dumai", areaHectares: 2.5),
            boundary: [CoordinatePoint(latitude: 1.0, longitude: 104.0)],
            agronomy: AgronomicProfile(plantingYear: 2018, soilType: "Mineral"),
            status: .scheduled
        )

        let garden = mapper.toGarden(from: request)
        #expect(garden.id == request.garden.id)
        #expect(garden.name == "Kebun Kelapa Sawit")
        #expect(garden.review?.status == .scheduled)
        #expect(garden.review?.contact.name == "Pak Budi")
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
        #expect(report.areas.allSatisfy { $0.periods.count == 2 })
        #expect(report.outline.count == 4)
        #expect(report.rainfall?.days.count == 7)
        #expect(report.nutrients.allSatisfy { NutrientReference.reference(for: $0.name) != nil })
    }
}

struct GardenOrderTests {
    @Test func newestGardensAndDraftsComeFirstAndLegacyGardensKeepTheirOrder() {
        func garden(_ name: String, _ created: Date?) -> Garden {
            var garden = Garden(id: UUID(), name: name, locationName: "", boundary: GardenBoundary(),
                                plantingYear: 2016, soilType: .peat)
            garden.createdAt = created
            return garden
        }
        let legacyOld = garden("lama-1", nil), legacyNew = garden("lama-2", nil)
        let older = garden("lama", Date(timeIntervalSince1970: 1_000)), newest = garden("baru", Date(timeIntervalSince1970: 3_000))
        var draft = GardenDraft(location: GardenLocation(name: "draf", subtitle: "",
            coordinate: GardenCoordinate(CLLocationCoordinate2D(latitude: 1, longitude: 104))))
        draft.createdAt = Date(timeIntervalSince1970: 2_000)
        let order = DashboardItem.newestFirst(gardens: [legacyOld, legacyNew, older, newest].map { DashboardMapper().map($0) },
                                               drafts: [DashboardMapper().map(draft)]).map(\.id)
        #expect(order == [newest.id, draft.id, older.id, legacyNew.id, legacyOld.id])
    }
}

struct NutrientLinkTests {
    @Test func everyNutrientNameInTheSummaryIsLinked() {
        let text = NutrientLinkedText.linked("Kadar magnesium paling jauh, disusul Nitrogen dan kalium. Fosfor berlebih; fosfor cukup.")
        let links = text.runs.compactMap { $0.link?.host() }
        #expect(links == ["Mg", "N", "K", "P", "P"])
    }
}

struct DashboardFilterTests {
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

    @Test func stagesLabelCardsAndOnlyDraftsAndReviewsAreFiltered() {
        let incomplete = garden(fertilized: true, harvested: false, review: nil)
        let ready = garden(fertilized: true, harvested: true, review: nil)
        let submitted = garden(fertilized: true, harvested: true, review: .submitted)
        let scheduled = garden(fertilized: true, harvested: true, review: .scheduled)
        let done = garden(fertilized: true, harvested: true, review: .completed)
        let mapper = DashboardMapper()
        #expect(mapper.map(incomplete).stage == .incomplete)
        #expect(mapper.map(ready).stage == .readyForReview)
        #expect(mapper.map(scheduled).stage == .inReview(visitScheduled: true))
        #expect(mapper.map(done).stage == .results(downloaded: false))
        let all = [incomplete, ready, submitted, scheduled, done].map { mapper.map($0) }
        #expect(all.filter(DashboardFilter.inReview.includes).map(\.id) == [submitted.id, scheduled.id])
        #expect(all.filter(DashboardFilter.all.includes).count == 5)
        let draft = GardenDraft(location: GardenLocation(name: "D", subtitle: "",
            coordinate: GardenCoordinate(CLLocationCoordinate2D(latitude: 1, longitude: 104))))
        #expect(DashboardFilter.all.actionCount(gardens: all, drafts: [mapper.map(draft)]) == 5)
        #expect(DashboardFilter.draft.actionCount(gardens: all, drafts: [mapper.map(draft)]) == 1)
        #expect(DashboardFilter.inReview.actionCount(gardens: all, drafts: [mapper.map(draft)]) == 1)
    }
}
