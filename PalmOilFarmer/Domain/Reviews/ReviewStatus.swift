import Foundation

public enum ReviewStatus: Int, CaseIterable, Codable, Sendable {
    case submitted = 0
    case scheduled = 1
    case inReview = 2
    case completed = 3
}
