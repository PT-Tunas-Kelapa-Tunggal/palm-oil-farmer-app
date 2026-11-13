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
        case fertilizingMap(gardenID: UUID, fertilizerName: String, isInPeriod: Bool)
        case exampleScreen(stepID: UUID)

        var id: String {
            switch self {
            case .fertilizingMap(let gardenID, let fertilizerName, let isInPeriod):
                return "map-\(gardenID)-\(fertilizerName)-\(isInPeriod)"
            case .exampleScreen(let stepID):
                return "example-\(stepID)"
            }
        }
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
        var stepName = "Dolomit"
        var isInPeriod = true
        if case .loaded(let presentation) = state {
            for sheet in presentation.sheets.values {
                for row in sheet.rows {
                    if case .step(let step) = row, step.id == id {
                        stepName = step.name
                        break
                    }
                }
            }
            if let hero = presentation.hero {
                switch hero {
                case .active(_, _, _, let rows):
                    for row in rows {
                        if case .step(let step) = row, step.id == id {
                            stepName = step.name
                            isInPeriod = true
                            break
                        }
                    }
                case .upcoming:
                    isInPeriod = false
                }
            }
        }
        destination = .fertilizingMap(gardenID: gardenID, fertilizerName: stepName, isInPeriod: isInPeriod)
    }
}
