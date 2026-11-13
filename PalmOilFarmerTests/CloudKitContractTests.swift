import CloudKit
import CoreLocation
import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct CloudKitContractTests {

    @Test func testRecordWriterAndReaderRoundTrip() throws {
        let coordinates = [
            CLLocation(latitude: 1.6640, longitude: 101.4480),
            CLLocation(latitude: 1.6650, longitude: 101.4490),
            CLLocation(latitude: 1.6630, longitude: 101.4500)
        ]
        let submittedDate = Date()
        let plantingDate = Calendar.current.date(from: DateComponents(year: 2018, month: 4, day: 1))!

        let composition = FertilizerCompositionItem(
            fertilizerType: "NPK 15-15-15",
            composition: [
                CompositionElement(name: "Nitrogen", value: "15", valueType: "int", valueUnit: "percent"),
                CompositionElement(name: "Phosphorus", value: "15", valueType: "int", valueUnit: "percent"),
                CompositionElement(name: "Potassium", value: "15", valueType: "int", valueUnit: "percent")
            ],
            dosagePerTree: DosagePerTree(value: "1.5", valueType: "double", valueUnit: "kg")
        )

        let writer = ScanRequestRecordWriter(
            recordName: "test-scan-request-001",
            farmBoundary: coordinates,
            farmSize: 2.75,
            farmCircumference: 840.5,
            submittedAt: submittedDate,
            farmName: "Kebun Belakang Rumah",
            farmAddress: "Jl. Sawit Subur No. 8, Dumai",
            plantingMonthAndYear: plantingDate,
            soilType: .gambut,
            fertilizingFrequencyPerYear: 3,
            fertilizersCompositions: [composition],
            harvestFrequencyPerMonth: 2,
            averageHarvestWeightKg: 1450.0,
            farmerContactName: "Pak Joko",
            farmerPhoneNumber: "081234567890",
            farmerHomeAddress: "Jl. Merdeka No. 10",
            fertilizationBudgetPerHa: 5_000_000
        )

        let record = try writer.buildRecord()
        let reader = ScanRequestRecord(record)

        // Verify Schema Version stamped
        #expect(reader.schemaVersion() == ContractInfo.version)

        // Verify iOS-owned fields
        #expect(reader.farmName().orNil == "Kebun Belakang Rumah")
        #expect(reader.farmAddress().orNil == "Jl. Sawit Subur No. 8, Dumai")
        #expect(reader.farmSize().orNil == 2.75)
        #expect(reader.farmCircumference().orNil == 840.5)
        #expect(reader.soilType().orNil == .gambut)
        #expect(reader.fertilizingFrequencyPerYear().orNil == 3)
        #expect(reader.harvestFrequencyPerMonth().orNil == 2)
        #expect(reader.averageHarvestWeightKg().orNil == 1450.0)
        #expect(reader.farmerContactName().orNil == "Pak Joko")
        #expect(reader.farmerPhoneNumber().orNil == "081234567890")
        #expect(reader.farmerHomeAddress().orNil == "Jl. Merdeka No. 10")
        #expect(reader.fertilizationBudgetPerHa().orNil == 5_000_000)

        // Verify Boundary
        let readBoundary = reader.farmBoundary().orNil
        #expect(readBoundary?.count == 3)
        #expect(readBoundary?.first?.coordinate.latitude == 1.6640)

        // Verify JSON Envelope serialization for fertilizers
        let readCompositions = reader.fertilizersCompositions().orNil
        #expect(readCompositions?.count == 1)
        #expect(readCompositions?.first?.fertilizerType == "NPK 15-15-15")
        #expect(readCompositions?.first?.composition?.count == 3)
        #expect(readCompositions?.first?.dosagePerTree.value == "1.5")

        // Verify Initialized macOS Progression Status
        #expect(reader.progressionStatus().orNil == .sent)
        let progressionDetails = reader.progressionStatusDetail().orNil
        #expect(progressionDetails?.count == 1)
        #expect(progressionDetails?.first?.title == "Sent")
    }

    @Test func testReaderFaultToleranceWithMissingAndCorruptedFields() {
        let emptyRecord = CKRecord(recordType: RecordKeys.recordType)
        let reader = ScanRequestRecord(emptyRecord)

        // Missing fields return .failure(.missing) rather than crashing
        switch reader.farmName() {
        case .failure(let error):
            #expect(error.isMissing)
        case .success:
            Issue.record("Expected missing field error")
        }

        // Call site helper .or() works as designed
        #expect(reader.farmName().or("Fallback Name") == "Fallback Name")
        #expect(reader.farmSize().or(0.0) == 0.0)
        #expect(reader.fertilizersCompositions().or([]) == [])

        // Corrupted JSON returns .failure(.decodingError) without crashing
        emptyRecord[RecordKeys.iOSOwned.fertilizersCompositions] = "invalid json string" as CKRecordValue
        let corruptReader = ScanRequestRecord(emptyRecord)
        switch corruptReader.fertilizersCompositions() {
        case .failure(let error):
            #expect(!error.isMissing)
        case .success:
            Issue.record("Expected decoding failure")
        }
    }

    @Test func testFieldOwnershipDoesNotOverwriteDroneFields() throws {
        let record = CKRecord(recordType: RecordKeys.recordType)
        record[RecordKeys.MacOSOwned.progressionStatus] = "In Progress" as CKRecordValue
        record[RecordKeys.MacOSOwned.plannedOperatorVisitDate] = Date() as CKRecordValue

        let writer = ScanRequestRecordWriter(
            recordName: "test-record",
            farmName: "Kebun Sawit Baru"
        )
        try writer.applyToRecord(record)

        let reader = ScanRequestRecord(record)
        // Drone-owned field was preserved (not overwritten with Sent)
        #expect(reader.progressionStatus().orNil == .inProgress)
        #expect(reader.plannedOperatorVisitDate().orNil != nil)
        // Farmer-owned field was updated
        #expect(reader.farmName().orNil == "Kebun Sawit Baru")
    }
}

