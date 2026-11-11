import Foundation

/// Everything the garden profile reads and writes.
/// `gardens` is read live so the profile reflects edits made anywhere in the app.
@MainActor
protocol GardenProfileDataSource: AnyObject {
    var gardens: [Garden] { get }
    var canDeleteGardens: Bool { get }
    func update(_ garden: Garden) -> Bool
    func delete(_ garden: Garden) -> Bool
}
