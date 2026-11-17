import Foundation


/// Review progress saved with the garden. Older gardens decode without it.
struct GardenReview: Codable {
    private(set) var status = ReviewStatus.submitted
    let contact: ReviewContactDetails
    /// The date each status was reached, indexed by `ReviewStatus.rawValue`.
    private(set) var stageDates: [Date]
    var resultsDownloaded = false

    init(contact: ReviewContactDetails, submittedAt: Date = .now) {
        self.contact = contact
        stageDates = [submittedAt]
    }

    init(status: ReviewStatus, contact: ReviewContactDetails, stageDates: [Date], resultsDownloaded: Bool = false) {
        self.status = status
        self.contact = contact
        self.stageDates = stageDates
        self.resultsDownloaded = resultsDownloaded
    }

    var isInProgress: Bool { status != .completed }

    /// The officer visit is planned for the day after scheduling.
    var visitDate: Date? {
        guard stageDates.count > ReviewStatus.scheduled.rawValue else { return nil }
        return Calendar.current.date(byAdding: .day, value: 1, to: stageDates[ReviewStatus.scheduled.rawValue])
    }

    func date(for status: ReviewStatus) -> Date? {
        stageDates.indices.contains(status.rawValue) ? stageDates[status.rawValue] : nil
    }

    /// Officers advance a review on the server. User testing advances it from the status screen.
    mutating func advance(now: Date = .now) {
        guard let next = ReviewStatus(rawValue: status.rawValue + 1) else { return }
        status = next
        stageDates = Array(stageDates.prefix(status.rawValue)) + [now]
    }
}
