import Foundation

enum ReviewStatus: Int, CaseIterable, Codable {
    case submitted, scheduled, inReview, completed
}
