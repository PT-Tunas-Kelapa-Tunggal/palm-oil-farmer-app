import CloudKit
import Foundation

/// Only changes the HTTP envelope. The operator's existing CKRecord/JSON contract stays authoritative.
struct CloudKitWebRecordAdapter {
    static func encode(_ dto: PlantationScanRequestRecordDTO) throws -> [String: Any] {
        let record = PlantationRecordCKAdapter.toCKRecord(from: dto)
        var fields: [String: Any] = [:]
        for key in record.allKeys() {
            switch record[key] {
            case let value as Date:
                fields[key] = ["type": "TIMESTAMP", "value": value.timeIntervalSince1970 * 1_000]
            case let value as String:
                fields[key] = ["type": "STRING", "value": value]
            case let value as NSNumber:
                let isFloat = ["d", "f"].contains(String(cString: value.objCType))
                fields[key] = ["type": isFloat ? "DOUBLE" : "INT64", "value": value]
            default:
                throw CloudKitWebError.invalidResponse
            }
        }
        return ["recordType": record.recordType, "recordName": record.recordID.recordName, "fields": fields]
    }

    static func decode(_ json: [String: Any], assetURL: URL? = nil) throws -> PlantationScanRequestRecordDTO {
        guard let name = json["recordName"] as? String,
              json["recordType"] as? String == PlantationRecordCKAdapter.recordType,
              let fields = json["fields"] as? [String: [String: Any]] else {
            throw CloudKitWebError.invalidResponse
        }
        let record = CKRecord(recordType: PlantationRecordCKAdapter.recordType, recordID: CKRecord.ID(recordName: name))
        for (key, field) in fields {
            guard let value = field["value"], !(value is NSNull) else { continue }
            switch field["type"] as? String {
            case "TIMESTAMP":
                guard let milliseconds = value as? Double else { throw CloudKitWebError.invalidResponse }
                record[key] = Date(timeIntervalSince1970: milliseconds / 1_000) as CKRecordValue
            case "STRING":
                guard let text = value as? String else { throw CloudKitWebError.invalidResponse }
                record[key] = text as CKRecordValue
            case "INT64":
                guard let number = value as? NSNumber else { throw CloudKitWebError.invalidResponse }
                record[key] = number.int64Value as CKRecordValue
            case "DOUBLE":
                guard let number = value as? NSNumber else { throw CloudKitWebError.invalidResponse }
                record[key] = number.doubleValue as CKRecordValue
            default: break
            }
        }
        if let assetURL { record[PlantationRecordCKAdapter.Field.orthomosaicAsset] = CKAsset(fileURL: assetURL) }
        return try PlantationRecordCKAdapter.toDTO(from: record)
    }

    static func assetDownloadURL(in json: [String: Any]) -> URL? {
        guard let fields = json["fields"] as? [String: [String: Any]],
              let asset = fields[PlantationRecordCKAdapter.Field.orthomosaicAsset]?["value"] as? [String: Any],
              let text = asset["downloadURL"] as? String,
              let url = URL(string: text), url.scheme == "https" else { return nil }
        return url
    }
}
