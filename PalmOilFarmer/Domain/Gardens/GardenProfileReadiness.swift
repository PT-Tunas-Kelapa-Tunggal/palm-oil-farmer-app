import Foundation

extension Garden {
    /// Existing review readiness rule: at least one fertilizer entry and a harvest entry.
    var isProfileComplete: Bool {
        !(fertilizerRecords ?? []).isEmpty && harvestRecord != nil
    }
}
