import Foundation

struct FertilizerFormDetails: Codable, Equatable {
    var frequencyPerYear = 2
    var compositions: [UUID: FertilizerComposition] = [:]
}

/// Reads device-only values saved by the earlier UI into the persisted garden model.
/// Retained for migration; new edits are saved through GardenStore and the review payload.
struct LocalFertilizerFormStore {
    let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func load(gardenID: UUID) -> FertilizerFormDetails {
        guard let data = defaults.data(forKey: key(gardenID)),
              let details = try? JSONDecoder().decode(FertilizerFormDetails.self, from: data) else {
            return FertilizerFormDetails()
        }
        return details
    }

    func save(_ details: FertilizerFormDetails, gardenID: UUID) throws {
        let data = try JSONEncoder().encode(details)
        defaults.set(data, forKey: key(gardenID))
    }

    func remove(gardenID: UUID) {
        defaults.removeObject(forKey: key(gardenID))
    }

    func applyingLegacyDetails(to garden: Garden) -> Garden {
        guard defaults.data(forKey: key(garden.id)) != nil else { return garden }
        let details = load(gardenID: garden.id)
        var updated = garden
        if updated.fertilizationFrequencyPerYear == nil {
            updated.fertilizationFrequencyPerYear = details.frequencyPerYear
        }
        updated.fertilizerRecords = garden.fertilizerRecords?.map { record in
            var migrated = record
            if migrated.composition == nil,
               record.name.trimmingCharacters(in: .whitespaces).uppercased().hasPrefix("NPK") {
                migrated.composition = details.compositions[record.id]
            }
            return migrated
        }
        return updated
    }

    private func key(_ gardenID: UUID) -> String {
        "garden.fertilizerForm.v1." + gardenID.uuidString
    }
}
