import Foundation
import Observation

@MainActor
@Observable
final class FertilizerScheduleViewModel {
    enum LoadState {
        case loading
        case loaded(FertilizerSchedulePresentation)
        case failed(String)
    }

    enum Destination: Hashable, Identifiable {
        case exampleScreen(stepID: UUID)
        var id: Self { self }
    }

    private(set) var state: LoadState = .loading
    var presentedPeriodID: UUID?
    var destination: Destination?

    @ObservationIgnored private let gardenID: UUID
    @ObservationIgnored private let repository: any FertilizerScheduleRepositoryProtocol
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let calendar: Calendar

    init(
        gardenID: UUID, repository: any FertilizerScheduleRepositoryProtocol,
        now: @escaping () -> Date = Date.init, calendar: Calendar = .current
    ) {
        self.gardenID = gardenID
        self.repository = repository
        self.now = now
        self.calendar = calendar
    }

    var presentedPeriod: FertilizerSchedulePresentation.PeriodSheet? {
        guard case .loaded(let presentation) = state, let presentedPeriodID else { return nil }
        return presentation.sheets[presentedPeriodID]
    }

    func load() async {
        state = .loading
        do {
            let schedule = try await repository.fetchSchedule(gardenID: gardenID)
            let today = now()
            let overview = FertilizerScheduleTimeline.overview(for: schedule, today: today, calendar: calendar)
            state = .loaded(FertilizerSchedulePresentation(
                schedule: schedule, overview: overview, today: today, calendar: calendar
            ))
        } catch {
            state = .failed("Jadwal pemupukan belum bisa dimuat.")
        }
    }

    func openPeriod(_ id: UUID) { presentedPeriodID = id }
    func closePeriod() { presentedPeriodID = nil }

    func selectStep(_ id: UUID) {
        presentedPeriodID = nil
        destination = .exampleScreen(stepID: id)
    }
}
