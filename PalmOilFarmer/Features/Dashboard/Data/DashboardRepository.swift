import Foundation
import Observation

/// (2) Real implementation, backed by the shared `GardenStore`
/// (SwiftData drafts + CloudKit submissions). Reading through the observable store
/// keeps the dashboard live when other screens edit a garden.
@MainActor
final class DashboardRepository: DashboardRepositoryProtocol {
    private let store: GardenStore
    private let mapper: DashboardMapper

    init(store: GardenStore, mapper: DashboardMapper = DashboardMapper()) {
        self.store = store
        self.mapper = mapper
    }

    var gardens: [DashboardGarden] { store.gardens.map { mapper.map($0) } }
    var drafts: [DashboardDraft] { store.drafts.map { mapper.map($0) } }

    func refresh() async {
        await store.refreshRemote()
    }

    @discardableResult
    func deleteDraft(id: UUID) -> Bool {
        guard let draft = store.drafts.first(where: { $0.id == id }) else { return false }
        return store.deleteDraft(draft)
    }
}

#if DEBUG
/// (2) Dummy implementation for previews: gardens and drafts kept in memory.
@MainActor
@Observable
final class DummyDashboardRepository: DashboardRepositoryProtocol {
    var gardens: [DashboardGarden]
    var drafts: [DashboardDraft]

    init(gardens: [DashboardGarden] = [], drafts: [DashboardDraft] = []) {
        self.gardens = gardens
        self.drafts = drafts
    }

    func refresh() async {}

    @discardableResult
    func deleteDraft(id: UUID) -> Bool {
        guard drafts.contains(where: { $0.id == id }) else { return false }
        drafts.removeAll { $0.id == id }
        return true
    }
}

/// Sample dashboard models for Canvas previews, mapped from the shared preview fixtures.
enum DashboardPreviewData {
    static var garden: DashboardGarden { DashboardMapper().map(GardenPreviewData.garden) }
    static var gardens: [DashboardGarden] { GardenPreviewData.gardens.map { DashboardMapper().map($0) } }
    static var draft: DashboardDraft {
        DashboardMapper().map(GardenDraft(location: GardenLocation(
            name: "Malang rapat", subtitle: "Gunung Kijang, Bintan",
            coordinate: GardenPreviewData.location.coordinate
        )))
    }
}
#endif
