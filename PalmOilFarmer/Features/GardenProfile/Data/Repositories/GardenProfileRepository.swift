import Foundation

/// Reads and edits gardens through the shared garden data source, so the list and the
/// profile always show the same garden.
@MainActor
final class GardenProfileRepository: GardenProfileDataSource {
    private let source: any GardenDataSource

    init(gardens: any GardenDataSource) {
        source = gardens
    }

    var gardens: [Garden] { source.gardens }
    var canDeleteGardens: Bool { true }

    func update(_ garden: Garden) -> Bool { source.update(garden) }
    func delete(_ garden: Garden) -> Bool { source.delete(garden) }
}
