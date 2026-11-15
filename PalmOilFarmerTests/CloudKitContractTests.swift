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
            fertilizerType: .npk,
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
        #expect(readCompositions?.first?.fertilizerType == .npk)
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

    @Test func testStrictContractFertilizerTypeCastingAndErrors() throws {
        #expect(try ContractFertilizerType("NPK") == .npk)
        #expect(try ContractFertilizerType("NPK-15-15-15") == .npk15_15_15)
        #expect(try ContractFertilizerType("NPK-12-6-22-3") == .npk12_6_22_3)
        #expect(try ContractFertilizerType("NPK-13-6-27-4") == .npk13_6_27_4)
        #expect(try ContractFertilizerType("NPK-13-8-27-4") == .npk13_8_27_4)
        #expect(try ContractFertilizerType("NPK-16-16-16") == .npk16_16_16)
        #expect(try ContractFertilizerType("  npk-12-6-22-3  ") == .npk12_6_22_3)
        #expect(ContractFertilizerType.npk15_15_15.rawValue == "NPK-15-15-15")
        #expect(ContractFertilizerType.npk12_6_22_3.rawValue == "NPK-12-6-22-3")
        #expect(ContractFertilizerType.npk13_6_27_4.rawValue == "NPK-13-6-27-4")
        #expect(ContractFertilizerType.npk13_8_27_4.rawValue == "NPK-13-8-27-4")
        #expect(ContractFertilizerType.npk16_16_16.rawValue == "NPK-16-16-16")

        #expect(try ContractFertilizerType("Dolomit") == .dolomite)
        #expect(try ContractFertilizerType("KCl (MOP)") == .kcl)
        #expect(try ContractFertilizerType("Kieserit") == .kieserite)
        #expect(try ContractFertilizerType("Pupuk kandang") == .pupukKandang)
        #expect(ContractFertilizerType(rawValue: "Pupuk Ajaib") == nil)

        #expect(throws: ContractFertilizerTypeError.unknownFertilizerType("Pupuk Ajaib")) {
            _ = try ContractFertilizerType("Pupuk Ajaib")
        }
        #expect(throws: ContractFertilizerTypeError.unknownFertilizerType("NPK 15-15-15")) {
            _ = try ContractFertilizerType("NPK 15-15-15")
        }
        #expect(throws: ContractFertilizerTypeError.unknownFertilizerType("NPK15-15-15")) {
            _ = try ContractFertilizerType("NPK15-15-15")
        }
        #expect(throws: ContractFertilizerTypeError.unknownFertilizerType("NPK-12-12-17-2")) {
            _ = try ContractFertilizerType("NPK-12-12-17-2")
        }
    }

    @Test func testNewNPKVariantsRoundTripAcrossContractPayloads() throws {
        let npkTypes: [ContractFertilizerType] = [
            .npk15_15_15,
            .npk12_6_22_3,
            .npk13_6_27_4,
            .npk13_8_27_4,
            .npk16_16_16
        ]

        let compositions = npkTypes.map { type in
            FertilizerCompositionItem(
                fertilizerType: type,
                dosagePerTree: DosagePerTree(value: "1.5", valueType: "double", valueUnit: "kg")
            )
        }
        let iosWriter = ScanRequestRecordWriter(
            recordName: "test-npk-variants-ios",
            fertilizersCompositions: compositions
        )
        let iosRecord = try iosWriter.buildRecord()
        let iosReader = ScanRequestRecord(iosRecord)
        #expect(iosReader.fertilizersCompositions().orNil == compositions)

        let needs = npkTypes.map { type in
            FertilizerNeedItem(
                fertilizerApplicationType: .general,
                fertilizerType: type,
                recommendedDosage: 2.0,
                dosageUnit: "kg",
                currentDosage: 1.0
            )
        }
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let schedule = [
            FertilizationSchedulePeriodItem(
                order: 1,
                startDate: baseDate,
                endDate: baseDate.addingTimeInterval(86400),
                fertilizers: npkTypes.enumerated().map { index, type in
                    FertilizationScheduleFertilizerItem(
                        fertilizerType: type,
                        step: index + 1,
                        amountPerRoundKg: 50.0
                    )
                }
            )
        ]
        let macWriter = MacOSScanRequestRecordWriter(
            recordName: "test-npk-variants-mac",
            fertilizerNeedPerZone: needs,
            fertilizationScheduling: schedule
        )
        let macRecord = try macWriter.buildRecord()
        let macReader = ScanRequestRecord(macRecord)
        #expect(macReader.fertilizerNeedPerZone().orNil == needs)
        #expect(macReader.fertilizationScheduling().orNil == schedule)
    }

    @Test func testFertilizerNeedAndScheduleRejectUnknownFertilizerTypeJSON() throws {
        let needItem = FertilizerNeedItem(
            fertilizerApplicationType: .zoneSpecific,
            fertilizerType: .kcl,
            recommendedDosage: 2.0,
            dosageUnit: "kg",
            currentDosage: 1.0,
            zoneId: 1
        )
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let schedulePeriod = FertilizationSchedulePeriodItem(
            order: 1,
            startDate: baseDate,
            endDate: baseDate.addingTimeInterval(86400),
            fertilizers: [
                FertilizationScheduleFertilizerItem(
                    fertilizerType: .dolomite,
                    step: 1,
                    amountPerRoundKg: 50.0
                )
            ]
        )

        let macWriter = MacOSScanRequestRecordWriter(
            recordName: "test-mac-record",
            fertilizerNeedPerZone: [needItem],
            fertilizationScheduling: [schedulePeriod]
        )
        let record = try macWriter.buildRecord()
        let reader = ScanRequestRecord(record)

        #expect(reader.fertilizerNeedPerZone().orNil == [needItem])
        #expect(reader.fertilizationScheduling().orNil == [schedulePeriod])

        let invalidNeedJSON = """
        {"version":"1.0.0","payload":[{"fertilizer_application_type":"general","fertilizer_type":"UnknownBrand","recommended_dosage":1.0,"dosage_unit":"kg","current_dosage":0.5}]}
        """
        record[RecordKeys.MacOSOwned.fertilizerNeedPerZone] = invalidNeedJSON as CKRecordValue
        switch reader.fertilizerNeedPerZone() {
        case .failure(.decodingError(let key, _)):
            #expect(key == RecordKeys.MacOSOwned.fertilizerNeedPerZone)
        default:
            Issue.record("Expected decodingError for unknown fertilizer_type")
        }

        let invalidCompositionJSON = """
        {"version":"1.0.0","payload":[{"fertilizerType":"UnknownBrand","dosagePerTree":{"value":"1.0","valueType":"double","valueUnit":"kg"}}]}
        """
        record[RecordKeys.iOSOwned.fertilizersCompositions] = invalidCompositionJSON as CKRecordValue
        switch reader.fertilizersCompositions() {
        case .failure(.decodingError(let key, _)):
            #expect(key == RecordKeys.iOSOwned.fertilizersCompositions)
        default:
            Issue.record("Expected decodingError for unknown fertilizerType")
        }
    }
}

