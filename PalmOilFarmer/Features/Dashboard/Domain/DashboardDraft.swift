import Foundation

/// (4) A location saved with "Lakukan Nanti", waiting for its boundary to be mapped.
struct DashboardDraft: Identifiable, Equatable {
    let id: UUID
    let name: String
    let subtitle: String
    let coordinate: DashboardCoordinate
    let createdAt: Date

    var title: String {
        subtitle.isEmpty || subtitle == name ? name : "\(name), \(subtitle)"
    }
}
