import Foundation

/// Shared source of truth for gardens, used by every feature that reads or writes a `Garden`.
///
/// Features never talk to the concrete store. Each feature has its own narrow repository
/// (in its own `Data/` folder) that reads and writes through this protocol, so one SwiftData
/// container and one CloudKit database back every screen (docs/ARCHITECTURE.md §7).
/// The implementation is observable: a write from one feature updates every screen that reads it.
@MainActor
protocol GardenDataSource: AnyObject {
    /// Local drafts and submitted gardens, merged (a submitted garden replaces its draft).
    var gardens: [Garden] { get }
    /// Locations saved with "Lakukan Nanti", not yet mapped.
    var drafts: [GardenDraft] { get }

    func add(_ garden: Garden, completingDraft draftID: UUID?) -> Bool
    func addDraft(_ draft: GardenDraft) -> Bool
    func update(_ garden: Garden) -> Bool
    func delete(_ garden: Garden) -> Bool
    func deleteDraft(_ draft: GardenDraft) -> Bool
    func refreshRemote() async
}
