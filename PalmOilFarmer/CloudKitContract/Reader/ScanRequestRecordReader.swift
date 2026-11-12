import CloudKit
import CoreLocation
import Foundation

/// Fault-tolerant reader wrapping a CloudKit `CKRecord` for `PlantationScanRequest`.
/// Guarantees that no getter panics or throws unhandled errors; all field reads return `Result<T, FieldError>`.
public struct ScanRequestRecord: Sendable {
    public let record: CKRecord

    public init(_ record: CKRecord) {
        self.record = record
    }

    // MARK: - Core Record Reader

    /// Internal helper to safely read any expected type from the underlying CKRecord.
    public func read<T>(_ key: String, as type: T.Type) -> Result<T, FieldError> {
        guard let rawValue = record[key] else {
            return .failure(.missing(key: key))
        }

        if let typed = rawValue as? T {
            return .success(typed)
        }

        // Support automatic integer promotion (e.g. Int to Int64)
        if T.self == Int64.self, let intVal = rawValue as? Int {
            return .success(Int64(intVal) as! T)
        }
        if T.self == Double.self, let num = rawValue as? NSNumber {
            return .success(num.doubleValue as! T)
        }

        return .failure(.typeMismatch(
            key: key,
            expected: String(describing: T.self),
            actual: String(describing: Swift.type(of: rawValue))
        ))
    }

    // MARK: - Schema Metadata

    /// The contract version stamped when this record was last saved (0 if missing).
    public func schemaVersion() -> Int64 {
        read(RecordKeys.schemaVersion, as: Int64.self).or(0)
    }

    // MARK: - iOS-Owned Fields

    public func farmBoundary() -> Result<[CLLocation], FieldError> {
        read(RecordKeys.iOSOwned.farmBoundary, as: [CLLocation].self)
    }

    public func farmSize() -> Result<Double, FieldError> {
        read(RecordKeys.iOSOwned.farmSize, as: Double.self)
    }

    public func farmCircumference() -> Result<Double, FieldError> {
        read(RecordKeys.iOSOwned.farmCircumference, as: Double.self)
    }

    public func submittedAt() -> Result<Date, FieldError> {
        read(RecordKeys.iOSOwned.submittedAt, as: Date.self)
    }

    public func farmName() -> Result<String, FieldError> {
        read(RecordKeys.iOSOwned.farmName, as: String.self)
    }

    public func farmAddress() -> Result<String, FieldError> {
        read(RecordKeys.iOSOwned.farmAddress, as: String.self)
    }

    public func plantingMonthAndYear() -> Result<Date, FieldError> {
        read(RecordKeys.iOSOwned.plantingMonthAndYear, as: Date.self)
    }

    public func soilType() -> Result<SoilType, FieldError> {
        read(RecordKeys.iOSOwned.soilType, as: String.self).map { SoilType(rawValue: $0) }
    }

    public func fertilizingFrequencyPerYear() -> Result<Int64, FieldError> {
        read(RecordKeys.iOSOwned.fertilizingFrequencyPerYear, as: Int64.self)
    }

    public func fertilizersCompositions() -> Result<[FertilizerCompositionItem], FieldError> {
        read(RecordKeys.iOSOwned.fertilizersCompositions, as: String.self)
            .flatMap { rawJSON in
                JSONEnvelope<[FertilizerCompositionItem]>.decodeFromString(rawJSON)
            }
    }

    public func harvestFrequencyPerMonth() -> Result<Int64, FieldError> {
        read(RecordKeys.iOSOwned.harvestFrequencyPerMonth, as: Int64.self)
    }

    public func averageHarvestWeightKg() -> Result<Double, FieldError> {
        read(RecordKeys.iOSOwned.averageHarvestWeightKg, as: Double.self)
    }

    public func farmerContactName() -> Result<String, FieldError> {
        read(RecordKeys.iOSOwned.farmerContactName, as: String.self)
    }

    public func farmerPhoneNumber() -> Result<String, FieldError> {
        read(RecordKeys.iOSOwned.farmerPhoneNumber, as: String.self)
    }

    public func farmerHomeAddress() -> Result<String, FieldError> {
        read(RecordKeys.iOSOwned.farmerHomeAddress, as: String.self)
    }

    public func fertilizationBudgetPerHa() -> Result<Int64, FieldError> {
        read(RecordKeys.iOSOwned.fertilizationBudgetPerHa, as: Int64.self)
    }

    // MARK: - macOS-Owned Fields

    public func progressionStatus() -> Result<ProgressionStatus, FieldError> {
        read(RecordKeys.MacOSOwned.progressionStatus, as: String.self)
            .map { ProgressionStatus(rawValue: $0) }
    }

    public func progressionStatusDetail() -> Result<[ProgressionStatusDetailEvent], FieldError> {
        read(RecordKeys.MacOSOwned.progressionStatusDetail, as: String.self)
            .flatMap { rawJSON in
                JSONEnvelope<[ProgressionStatusDetailEvent]>.decodeFromString(rawJSON)
            }
    }

    public func orthomosaicImage() -> Result<CKAsset, FieldError> {
        read(RecordKeys.MacOSOwned.orthomosaicImage, as: CKAsset.self)
    }

    public func fertilizingZone() -> Result<[FertilizingZoneItem], FieldError> {
        read(RecordKeys.MacOSOwned.fertilizingZone, as: String.self)
            .flatMap { rawJSON in
                JSONEnvelope<[FertilizingZoneItem]>.decodeFromString(rawJSON)
            }
    }

    public func fertilizerNeedPerZone() -> Result<[FertilizerNeedItem], FieldError> {
        read(RecordKeys.MacOSOwned.fertilizerNeedPerZone, as: String.self)
            .flatMap { rawJSON in
                JSONEnvelope<[FertilizerNeedItem]>.decodeFromString(rawJSON)
            }
    }

    public func treeIdentification() -> Result<[TreeIdentificationItem], FieldError> {
        read(RecordKeys.MacOSOwned.treeIdentification, as: String.self)
            .flatMap { rawJSON in
                JSONEnvelope<[TreeIdentificationItem]>.decodeFromString(rawJSON)
            }
    }

    public func plannedOperatorVisitDate() -> Result<Date, FieldError> {
        read(RecordKeys.MacOSOwned.plannedOperatorVisitDate, as: Date.self)
    }

    public func resultSentAt() -> Result<Date, FieldError> {
        read(RecordKeys.MacOSOwned.resultSentAt, as: Date.self)
    }
}

