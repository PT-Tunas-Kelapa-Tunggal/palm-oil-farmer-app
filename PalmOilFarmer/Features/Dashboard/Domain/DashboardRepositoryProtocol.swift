import Foundation

/// (1) What the dashboard needs from storage, in the dashboard's own models.
/// Reads are synchronous and observable, so the dashboard updates as soon as another
/// screen (profile, mapping) changes the shared gardens.
@MainActor
protocol DashboardRepositoryProtocol: AnyObject {
    var gardens: [DashboardGarden] { get }
    var drafts: [DashboardDraft] { get }

    /// Pulls the farmer's submitted gardens from the server.
    func refresh() async

    /// Returns false when the draft could not be deleted; nothing is removed optimistically.
    @discardableResult func deleteDraft(id: UUID) -> Bool
}
