import Foundation

public protocol FertilizerScheduleRepositoryProtocol: Sendable {
    func fetchSchedule(gardenID: UUID) async throws -> FertilizerSchedule
}
