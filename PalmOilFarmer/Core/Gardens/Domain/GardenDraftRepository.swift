import Foundation

struct GardenDraftSnapshot {
    let locations: [GardenDraft]
    let gardens: [Garden]
}

/// Local, unsubmitted data only. Submitted reviews are never cached here.
@MainActor
protocol GardenDraftRepository {
    func loadDrafts() throws -> GardenDraftSnapshot
    func add(_ garden: Garden, completingDraft draftID: UUID?) throws
    func addDraft(_ draft: GardenDraft) throws

    /// Returns false when a matching draft cannot be found; throws if saving it fails.
    func update(_ garden: Garden) throws -> Bool

    /// Returns false when lookup fails or finds nothing. A thrown error means a
    /// draft was found and marked for deletion, but saving that deletion failed.
    func deleteDraft(id: UUID) throws -> Bool

    #if DEBUG
    func eraseAll() throws
    #endif
}
