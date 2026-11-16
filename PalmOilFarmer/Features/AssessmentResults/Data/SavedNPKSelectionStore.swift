import Foundation

/// The farmer's chosen NPK formula is an app preference, separate from the assessment payload.
actor SavedNPKSelectionStore {
    static let shared = SavedNPKSelectionStore()

    private let defaults = UserDefaults.standard
    private let keyPrefix = "fertilizer.savedNPK."

    func selection(for gardenID: String) -> String? {
        defaults.string(forKey: keyPrefix + gardenID.uppercased())
    }

    func save(_ optionID: String, for gardenID: String) {
        defaults.set(optionID, forKey: keyPrefix + gardenID.uppercased())
    }
}
