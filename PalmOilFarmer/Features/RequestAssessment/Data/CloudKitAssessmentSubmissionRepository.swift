import CloudKit
import CoreLocation
import Foundation

/// Real CloudKit submission repository that maps user input from `Garden` and `AssessmentSubmission`
/// into the agreed `CloudKitContract` payload and saves it to the CloudKit Public Database.
@MainActor
public final class CloudKitAssessmentSubmissionRepository: AssessmentSubmissionRepository {
    private let gardenStore: GardenStore
    private let database: CKDatabase

    public init(
        gardenStore: GardenStore,
        database: CKDatabase? = nil
    ) {
        self.gardenStore = gardenStore
        if let database {
            self.database = database
        } else {
            let container = CKContainer(identifier: AppConfiguration.cloudKitContainerIdentifier)
            self.database = container.publicCloudDatabase
        }
    }

    public func submit(_ submission: AssessmentSubmission) async throws {
        // 1. Locate the selected garden from the store
        guard let garden = gardenStore.gardens.first(where: { $0.id == submission.gardenID }) else {
            throw CloudKitSubmissionError.gardenNotFound(submission.gardenID)
        }

        // 2. Map Farm Boundary coordinates to CLLocation array
        let boundaryCoordinates = garden.boundary.points.map {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude)
        }

        // 3. Calculate perimeter circumference in meters
        let circumference = calculateCircumference(for: garden.boundary.points)

        // 4. Map planting date (1st of planting month & year)
        let plantingDate = mapPlantingDate(year: garden.plantingYear, month: garden.plantingMonth)

        // 5. Map Soil Type to Contract enum
        let contractSoilType = SoilType(rawValue: garden.soilType.rawValue)

        // 6. Map fertilizer history to FertilizerCompositionItem payload
        let fertilizerPayloads = mapFertilizerPayloads(from: garden.fertilizerRecords)

        // 7. Assemble ScanRequestRecordWriter with all user inputs
        let writer = ScanRequestRecordWriter(
            recordName: submission.gardenID.uuidString,
            farmBoundary: boundaryCoordinates.isEmpty ? nil : boundaryCoordinates,
            farmSize: max(garden.boundary.areaHectares, 0.1),
            farmCircumference: circumference > 0 ? circumference : nil,
            submittedAt: Date(),
            farmName: garden.name,
            farmAddress: garden.locationName,
            plantingMonthAndYear: plantingDate,
            soilType: contractSoilType,
            fertilizingFrequencyPerYear: garden.fertilizationFrequencyPerYear.map { Int64($0) },
            fertilizersCompositions: fertilizerPayloads,
            harvestFrequencyPerMonth: garden.harvestRecord.map { Int64($0.frequencyPerMonth) },
            averageHarvestWeightKg: garden.harvestRecord?.latestWeightKg,
            farmerContactName: submission.contact.name,
            farmerPhoneNumber: submission.contact.phone,
            farmerHomeAddress: submission.contact.address,
            fertilizationBudgetPerHa: Int64(submission.fertilizerBudgetPerHectare)
        )

        // 8. Build the CKRecord and save via .changedKeys to Public Database
        let record = try writer.buildRecord()
        try await ScanRequestRecordWriter.save(record: record, to: database)

        // 9. Update local Garden state with submitted review details
        var updatedGarden = garden
        updatedGarden.review = GardenReview(contact: submission.contact)
        gardenStore.update(updatedGarden)
    }

    // MARK: - Mapping Helpers

    private func calculateCircumference(for points: [GardenCoordinate]) -> Double {
        guard points.count >= 3 else { return 0.0 }
        var totalMeters: Double = 0.0
        for i in 0..<points.count {
            let p1 = CLLocation(latitude: points[i].latitude, longitude: points[i].longitude)
            let nextIndex = (i + 1) % points.count
            let p2 = CLLocation(latitude: points[nextIndex].latitude, longitude: points[nextIndex].longitude)
            totalMeters += p1.distance(from: p2)
        }
        return totalMeters
    }

    private func mapPlantingDate(year: Int, month: Int?) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month ?? 1
        components.day = 1
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }

    private func mapFertilizerPayloads(from records: [FertilizerRecord]?) -> [FertilizerCompositionItem]? {
        guard let records, !records.isEmpty else { return nil }
        return records.map { record in
            var elements: [CompositionElement] = []
            if let composition = record.composition {
                if let n = composition.nitrogen {
                    elements.append(CompositionElement(
                        name: "Nitrogen",
                        value: "\(n)",
                        valueType: "double",
                        valueUnit: "percent"
                    ))
                }
                if let p = composition.phosphorus {
                    elements.append(CompositionElement(
                        name: "Phosphorus",
                        value: "\(p)",
                        valueType: "double",
                        valueUnit: "percent"
                    ))
                }
                if let k = composition.potassium {
                    elements.append(CompositionElement(
                        name: "Potassium",
                        value: "\(k)",
                        valueType: "double",
                        valueUnit: "percent"
                    ))
                }
                if let mg = composition.magnesium {
                    elements.append(CompositionElement(
                        name: "Magnesium",
                        value: "\(mg)",
                        valueType: "double",
                        valueUnit: "percent"
                    ))
                }
            }

            let dosage = DosagePerTree(
                value: "\(record.doseKgPerTree)",
                valueType: "double",
                valueUnit: "kg"
            )

            return FertilizerCompositionItem(
                fertilizerType: record.name,
                composition: elements.isEmpty ? nil : elements,
                dosagePerTree: dosage
            )
        }
    }
}

public enum CloudKitSubmissionError: LocalizedError {
    case gardenNotFound(UUID)

    public var errorDescription: String? {
        switch self {
        case .gardenNotFound(let id):
            return "Kebun dengan ID \(id) tidak ditemukan."
        }
    }
}

