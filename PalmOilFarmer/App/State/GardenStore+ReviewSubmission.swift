import Foundation

extension GardenStore: ReviewSubmissionGateway {
    func garden(for id: UUID) -> Garden? { gardens.first { $0.id == id } }
}
