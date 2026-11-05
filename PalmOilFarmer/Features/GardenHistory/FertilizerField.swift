import Foundation

/// A numeric field in one fertilizer card; used for focus and scrolling.
struct FertilizerField: Hashable {
    enum Kind: CaseIterable { case bagWeight, bagCount, dose }
    let draftID: UUID
    let kind: Kind
}
