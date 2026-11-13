import Foundation
import SwiftData

/// SwiftData persistent model storing all local, unsubmitted plantation scan requests and drafts.
/// Isolated per CloudKit container and environment.
@Model
final class DraftPlantationRequest {
    @Attribute(.unique) var id: UUID
    var name: String
    var locationName: String
    var locationSubtitle: String
    var latitude: Double
    var longitude: Double
    var boundaryData: Data?
    var plantingYear: Int?
    var plantingMonth: Int?
    var soilTypeRawValue: String?
    var fertilizerData: Data?
    var profileUpdatedAt: Date?
    var fertilizationFrequencyPerYear: Int?
    var harvestData: Data?
    var farmerName: String?
    var farmerPhone: String?
    var farmerAddress: String?
    var createdAt: Date
    var isBoundaryMapped: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        locationName: String = "",
        locationSubtitle: String = "",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        boundaryData: Data? = nil,
        plantingYear: Int? = nil,
        plantingMonth: Int? = nil,
        soilTypeRawValue: String? = nil,
        fertilizerData: Data? = nil,
        harvestData: Data? = nil,
        farmerName: String? = nil,
        farmerPhone: String? = nil,
        farmerAddress: String? = nil,
        createdAt: Date = .now,
        isBoundaryMapped: Bool = false,
        fertilizationFrequencyPerYear: Int? = nil,
        profileUpdatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.locationName = locationName
        self.locationSubtitle = locationSubtitle
        self.latitude = latitude
        self.longitude = longitude
        self.boundaryData = boundaryData
        self.plantingYear = plantingYear
        self.plantingMonth = plantingMonth
        self.soilTypeRawValue = soilTypeRawValue
        self.fertilizerData = fertilizerData
        self.harvestData = harvestData
        self.farmerName = farmerName
        self.farmerPhone = farmerPhone
        self.farmerAddress = farmerAddress
        self.createdAt = createdAt
        self.isBoundaryMapped = isBoundaryMapped
        self.fertilizationFrequencyPerYear = fertilizationFrequencyPerYear
        self.profileUpdatedAt = profileUpdatedAt
    }

    // MARK: - Convenient Domain Conversions

    var boundary: GardenBoundary {
        get {
            guard let boundaryData,
                  let points = try? JSONDecoder().decode([GardenCoordinate].self, from: boundaryData) else {
                return GardenBoundary()
            }
            return GardenBoundary(points: points)
        }
        set {
            boundaryData = try? JSONEncoder().encode(newValue.points)
        }
    }

    var fertilizerRecords: [FertilizerRecord] {
        get {
            guard let fertilizerData,
                  let records = try? JSONDecoder().decode([FertilizerRecord].self, from: fertilizerData) else {
                return []
            }
            return records
        }
        set {
            fertilizerData = try? JSONEncoder().encode(newValue)
        }
    }

    var harvestRecord: HarvestRecord? {
        get {
            guard let harvestData else { return nil }
            return try? JSONDecoder().decode(HarvestRecord.self, from: harvestData)
        }
        set {
            harvestData = try? JSONEncoder().encode(newValue)
        }
    }

    var soilType: SoilType? {
        get {
            guard let soilTypeRawValue else { return nil }
            return SoilType(rawValue: soilTypeRawValue)
        }
        set {
            soilTypeRawValue = newValue?.rawValue
        }
    }

    var location: GardenLocation {
        GardenLocation(
            name: locationName,
            subtitle: locationSubtitle,
            coordinate: GardenCoordinate(latitude: latitude, longitude: longitude),
            source: .draft,
            draftID: id
        )
    }

    func toGardenDraft() -> GardenDraft {
        GardenDraft(
            id: id,
            name: locationName,
            subtitle: locationSubtitle,
            coordinate: GardenCoordinate(latitude: latitude, longitude: longitude),
            createdAt: createdAt
        )
    }

    func toGarden() -> Garden {
        let review: GardenReview?
        if let farmerName, !farmerName.isEmpty, let farmerPhone, let farmerAddress {
            review = GardenReview(contact: ReviewContactDetails(name: farmerName, phone: farmerPhone, address: farmerAddress))
        } else {
            review = nil
        }
        return Garden(
            id: id,
            name: name,
            locationName: locationName,
            boundary: boundary,
            plantingYear: plantingYear ?? Calendar.current.component(.year, from: .now),
            soilType: soilType ?? .mineral,
            plantingMonth: plantingMonth,
            fertilizerRecords: fertilizerRecords.isEmpty ? nil : fertilizerRecords,
            harvestRecord: harvestRecord,
            review: review,
            createdAt: createdAt,
            fertilizationFrequencyPerYear: fertilizationFrequencyPerYear,
            profileUpdatedAt: profileUpdatedAt
        )
    }

    static func from(draft: GardenDraft) -> DraftPlantationRequest {
        DraftPlantationRequest(
            id: draft.id,
            name: draft.name,
            locationName: draft.name,
            locationSubtitle: draft.subtitle,
            latitude: draft.coordinate.latitude,
            longitude: draft.coordinate.longitude,
            createdAt: draft.createdAt,
            isBoundaryMapped: false
        )
    }

    static func from(garden: Garden) -> DraftPlantationRequest {
        let firstCoord = garden.boundary.points.first
        let boundaryData = try? JSONEncoder().encode(garden.boundary.points)
        let fertilizerData = garden.fertilizerRecords != nil ? (try? JSONEncoder().encode(garden.fertilizerRecords)) : nil
        let harvestData = garden.harvestRecord != nil ? (try? JSONEncoder().encode(garden.harvestRecord)) : nil

        return DraftPlantationRequest(
            id: garden.id,
            name: garden.name,
            locationName: garden.locationName,
            locationSubtitle: "",
            latitude: firstCoord?.latitude ?? 0.0,
            longitude: firstCoord?.longitude ?? 0.0,
            boundaryData: boundaryData,
            plantingYear: garden.plantingYear,
            plantingMonth: garden.plantingMonth,
            soilTypeRawValue: garden.soilType.rawValue,
            fertilizerData: fertilizerData,
            harvestData: harvestData,
            farmerName: garden.review?.contact.name,
            farmerPhone: garden.review?.contact.phone,
            farmerAddress: garden.review?.contact.address,
            createdAt: garden.createdAt ?? .now,
            isBoundaryMapped: true,
            fertilizationFrequencyPerYear: garden.fertilizationFrequencyPerYear,
            profileUpdatedAt: garden.profileUpdatedAt
        )
    }
}