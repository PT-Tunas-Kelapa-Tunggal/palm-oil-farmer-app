import CoreLocation
import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct DomainBoundaryTests {
    private func garden() -> Garden {
        Garden(id: UUID(), name: "Kebun uji", locationName: "Dumai",
               boundary: GardenBoundary(points: [
                   GardenCoordinate(latitude: 1, longitude: 104),
                   GardenCoordinate(latitude: 1, longitude: 104.001),
                   GardenCoordinate(latitude: 1.001, longitude: 104)
               ]), plantingYear: 2016, soilType: .peat)
    }

    @Test func gardenDetailsKeepExistingRequiredFieldRules() throws {
        let details = try #require(GardenDetails(name: "  Kebun\n", plantingYear: 2016, soilType: .peat))
        #expect(details.name == "Kebun")
        #expect(details.plantingYear == 2016)
        #expect(details.soilType == .peat)
        #expect(GardenDetails(name: " \n", plantingYear: 2016, soilType: .peat) == nil)
        #expect(GardenDetails(name: "Kebun", plantingYear: nil, soilType: .peat) == nil)
        #expect(GardenDetails(name: "Kebun", plantingYear: 2016, soilType: nil) == nil)
        // The old save guard required a year, without imposing a new year range.
        #expect(GardenDetails(name: "Kebun", plantingYear: 0, soilType: .other) != nil)
    }

    @Test func fertilizerValidationPreservesIdentityAndRejectsInvalidQuantities() throws {
        let id = UUID()
        let valid = try #require(FertilizerRecord.validated(
            id: id, name: "  Urea\n", bagWeightKg: 50, bagCount: 2, doseKgPerTree: 1.5
        ))
        #expect(valid.id == id)
        #expect(valid.name == "Urea")
        #expect(valid.bagWeightKg == 50 && valid.bagCount == 2 && valid.doseKgPerTree == 1.5)
        for invalid in [0.0, -1, .infinity, .nan] {
            #expect(FertilizerRecord.validated(id: id, name: "Urea", bagWeightKg: invalid,
                                             bagCount: 2, doseKgPerTree: 1) == nil)
            #expect(FertilizerRecord.validated(id: id, name: "Urea", bagWeightKg: 50,
                                             bagCount: 2, doseKgPerTree: invalid) == nil)
        }
        #expect(FertilizerRecord.validated(id: id, name: " ", bagWeightKg: 50,
                                         bagCount: 2, doseKgPerTree: 1) == nil)
        #expect(FertilizerRecord.validated(id: id, name: "Urea", bagWeightKg: 50,
                                         bagCount: 0, doseKgPerTree: 1) == nil)
    }

    @Test func harvestValidationPreservesInclusiveFrequencyBounds() {
        #expect(HarvestRecord.validated(frequencyPerMonth: 1, latestWeightKg: 0.1) != nil)
        #expect(HarvestRecord.validated(frequencyPerMonth: 31, latestWeightKg: 500) != nil)
        #expect(HarvestRecord.validated(frequencyPerMonth: 0, latestWeightKg: 500) == nil)
        #expect(HarvestRecord.validated(frequencyPerMonth: 32, latestWeightKg: 500) == nil)
        for invalid in [0.0, -1, .infinity, .nan] {
            #expect(HarvestRecord.validated(frequencyPerMonth: 2, latestWeightKg: invalid) == nil)
        }
    }

    @Test func contactValidationTrimsNamesButPreservesPhonePayload() throws {
        let phone = " +62 (812) 3456 "
        let contact = try #require(ReviewContactDetails.validated(
            name: "  Pak Budi\n", phone: phone, address: "  Dusun Uji\n", hasConfirmedContact: true
        ))
        #expect(contact.name == "Pak Budi")
        #expect(contact.address == "Dusun Uji")
        #expect(contact.phone == phone)
        #expect(ReviewContactDetails.validated(name: "Budi", phone: "12345678", address: "Uji",
                                             hasConfirmedContact: true) != nil)
        #expect(ReviewContactDetails.validated(name: "Budi", phone: "1234567", address: "Uji",
                                             hasConfirmedContact: true) == nil)
        #expect(ReviewContactDetails.validated(name: "Budi", phone: phone, address: "Uji",
                                             hasConfirmedContact: false) == nil)
        #expect(ReviewContactDetails.validated(name: " \n", phone: phone, address: "Uji",
                                             hasConfirmedContact: true) == nil)
        #expect(ReviewContactDetails.validated(name: "Budi", phone: phone, address: " ",
                                             hasConfirmedContact: true) == nil)
    }

    @Test func profileReadinessStillRequiresBothHistories() {
        var value = garden()
        #expect(!value.isProfileComplete)
        value.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 400)
        value.fertilizerRecords = []
        #expect(!value.isProfileComplete)
        value.fertilizerRecords = [FertilizerRecord(name: "Urea", bagWeightKg: 50, bagCount: 2, doseKgPerTree: 1)]
        #expect(value.isProfileComplete)
        value.harvestRecord = nil
        #expect(!value.isProfileComplete)
    }

    @Test func coordinateAdapterKeepsGeodesicPerimeterAndRoundTrip() {
        let boundary = garden().boundary
        let coordinates = boundary.coordinates
        #expect(coordinates.map(GardenCoordinate.init) == boundary.points)
        let expected = coordinates.indices.reduce(0.0) { sum, index in
            let next = coordinates[(index + 1) % coordinates.count]
            return sum + CLLocation(latitude: coordinates[index].latitude, longitude: coordinates[index].longitude)
                .distance(from: CLLocation(latitude: next.latitude, longitude: next.longitude))
        }
        #expect(abs(boundary.perimeterMeters - expected) < 0.000001)
    }

    @Test func existingGardenJSONKeepsKeysRawValuesAndReviewDates() throws {
        let fixture = Data("""
        {"id":"5C8F2B1E-7A44-4C8A-9F1D-2B6E3C4D5A6B","name":"Lama","locationName":"Dumai",
         "boundary":{"points":[{"latitude":1,"longitude":104}]},"plantingYear":2016,
         "soilType":"Gambut","plantingMonth":10,"createdAt":0,
         "fertilizerRecords":[{"id":"5C8F2B1E-7A44-4C8A-9F1D-2B6E3C4D5A6C","name":"Urea",
          "bagWeightKg":50,"bagCount":2,"doseKgPerTree":1.5}],
         "harvestRecord":{"frequencyPerMonth":2,"latestWeightKg":400},
         "review":{"status":1,"contact":{"name":"Budi","phone":"08123456789","address":"Uji"},
          "stageDates":[0,3600],"resultsDownloaded":false}}
        """.utf8)
        let value = try JSONDecoder().decode(Garden.self, from: fixture)
        #expect(value.soilType == .peat)
        #expect(value.review?.status == .scheduled)
        #expect(value.review?.date(for: .scheduled) == Date(timeIntervalSinceReferenceDate: 3600))
        let restored = try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) as? NSDictionary
        let original = try JSONSerialization.jsonObject(with: fixture) as? NSDictionary
        #expect(restored == original)
    }

    @Test func submissionSnapshotKeepsExistingCloudPayload() throws {
        var value = garden()
        value.plantingMonth = 7
        let fertilizer = FertilizerRecord(name: "Urea", bagWeightKg: 50, bagCount: 2, doseKgPerTree: 1.5)
        value.fertilizerRecords = [fertilizer]
        value.harvestRecord = HarvestRecord(frequencyPerMonth: 2, latestWeightKg: 400)
        let contact = ReviewContactDetails(name: "Budi", phone: "+62 812 3456", address: "Uji")
        let request = PlantationReviewRequest(garden: value, contact: contact)
        #expect(request.garden.id == value.id)
        #expect(request.garden.name == value.name)
        #expect(request.garden.areaHectares == value.boundary.areaHectares)
        #expect(request.boundary.map { GardenCoordinate(latitude: $0.latitude, longitude: $0.longitude) }
                == value.boundary.points)
        #expect(request.status == .submitted && request.result == nil)
        let dto = try PlantationDomainMapper().toDTO(from: request)
        let agronomy = try JSONDecoder().decode(AgronomicProfileDTO.self, from: Data(dto.agronomicJSON.utf8))
        #expect(dto.recordName == request.id.uuidString)
        #expect(dto.gardenID == value.id.uuidString && dto.farmerPhone == contact.phone)
        #expect(dto.statusCode == 0 && dto.resultJSON == nil)
        #expect(agronomy.year == 2016 && agronomy.month == 7 && agronomy.soil == "Gambut")
        #expect(agronomy.fertilizers.first?.id == fertilizer.id.uuidString)
        #expect(agronomy.fertilizers.first?.bagKg == 50 && agronomy.fertilizers.first?.dosePerTree == 1.5)
        #expect(agronomy.harvest?.freq == 2 && agronomy.harvest?.weightKg == 400)
    }
}
