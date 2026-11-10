import Foundation

enum FertilizerPeriodStatus: Equatable, Sendable {
    case completed(on: Date)
    case active
    case upcoming(daysUntilStart: Int)
}

enum FertilizerStepState: Equatable, Sendable {
    case given(Date)
    case due
    case overdue(daysLate: Int)
    case waiting(startsOn: Date)
    case locked
}

enum FertilizerGapState: Equatable, Sendable {
    case pending
    case elapsed
    case counting(daysRemaining: Int)
}

enum FertilizerTimelineEntry: Identifiable, Equatable, Sendable {
    case step(FertilizerStep, FertilizerStepState)
    /// The gap before the step identified by `beforeStepID`.
    case gap(FertilizerGap, FertilizerGapState, beforeStepID: UUID)

    var id: String {
        switch self {
        case .step(let step, _): "step-\(step.id)"
        case .gap(_, _, let stepID): "gap-\(stepID)"
        }
    }
}

struct ActivePeriodProgress: Equatable, Sendable {
    let period: FertilizerPeriod
    let dayNumber: Int
    let totalDays: Int
    let entries: [FertilizerTimelineEntry]
}

struct UpcomingFertilizerPeriod: Equatable, Sendable {
    let period: FertilizerPeriod
    let daysUntilStart: Int
}

struct CompletedFertilizerPeriod: Equatable, Sendable {
    let period: FertilizerPeriod
    let completedOn: Date
}

enum FeaturedFertilizerPeriod: Equatable, Sendable {
    case active(ActivePeriodProgress)
    case upcoming(FertilizerPeriod, daysUntilStart: Int)

    var period: FertilizerPeriod {
        switch self {
        case .active(let progress): progress.period
        case .upcoming(let period, _): period
        }
    }
}

struct FertilizerScheduleOverview: Equatable, Sendable {
    let featured: FeaturedFertilizerPeriod?
    let nextPeriods: [UpcomingFertilizerPeriod]
    let completedPeriods: [CompletedFertilizerPeriod]
}

/// Pure scheduling rules. Every comparison is made on calendar days, never on timestamps.
enum FertilizerScheduleTimeline {
    static func overview(for schedule: FertilizerSchedule, today: Date, calendar: Calendar) -> FertilizerScheduleOverview {
        let periods = schedule.periods.sorted { $0.startDate < $1.startDate }
        let statuses = periods.map { (period: $0, status: status(of: $0, today: today, calendar: calendar)) }

        let upcoming = statuses.compactMap { item -> UpcomingFertilizerPeriod? in
            guard case .upcoming(let days) = item.status else { return nil }
            return UpcomingFertilizerPeriod(period: item.period, daysUntilStart: days)
        }
        let completed = statuses.compactMap { item -> CompletedFertilizerPeriod? in
            guard case .completed(let date) = item.status else { return nil }
            return CompletedFertilizerPeriod(period: item.period, completedOn: date)
        }

        let featured: FeaturedFertilizerPeriod?
        if let active = statuses.first(where: { $0.status == .active }) {
            featured = .active(progress(for: active.period, today: today, calendar: calendar))
        } else if let first = upcoming.first {
            featured = .upcoming(first.period, daysUntilStart: first.daysUntilStart)
        } else {
            featured = nil
        }

        return FertilizerScheduleOverview(
            featured: featured,
            nextPeriods: upcoming.filter { $0.period.id != featured?.period.id },
            completedPeriods: completed.sorted { $0.completedOn > $1.completedOn }
        )
    }

    static func status(of period: FertilizerPeriod, today: Date, calendar: Calendar) -> FertilizerPeriodStatus {
        let givenDates = period.steps.compactMap(\.givenDate)
        if !period.steps.isEmpty, givenDates.count == period.steps.count, let latest = givenDates.max() {
            return .completed(on: latest)
        }
        let daysUntilStart = days(from: today, to: period.startDate, calendar: calendar)
        return daysUntilStart > 0 ? .upcoming(daysUntilStart: daysUntilStart) : .active
    }

    static func progress(for period: FertilizerPeriod, today: Date, calendar: Calendar) -> ActivePeriodProgress {
        ActivePeriodProgress(
            period: period,
            dayNumber: days(from: period.startDate, to: today, calendar: calendar) + 1,
            totalDays: days(from: period.startDate, to: period.endDate, calendar: calendar) + 1,
            entries: entries(for: period, today: today, calendar: calendar)
        )
    }

    /// Step rows in order, with a gap row before every step that has one.
    static func entries(for period: FertilizerPeriod, today: Date, calendar: Calendar) -> [FertilizerTimelineEntry] {
        let states = stepStates(for: period, today: today, calendar: calendar)
        var entries: [FertilizerTimelineEntry] = []
        for (index, step) in period.steps.enumerated() {
            if index > 0, let gap = step.gapBefore {
                entries.append(.gap(gap, gapState(previous: states[index - 1], next: states[index], today: today,
                                                  calendar: calendar), beforeStepID: step.id))
            }
            entries.append(.step(step, states[index]))
        }
        return entries
    }

    static func stepStates(for period: FertilizerPeriod, today: Date, calendar: Calendar) -> [FertilizerStepState] {
        var states: [FertilizerStepState] = []
        var reachedOpenStep = false
        for (index, step) in period.steps.enumerated() {
            if let givenDate = step.givenDate {
                states.append(.given(givenDate))
            } else if reachedOpenStep {
                states.append(.locked)
            } else {
                reachedOpenStep = true
                let previousGiven = index > 0 ? period.steps[index - 1].givenDate : nil
                states.append(openStepState(step, previousGiven: previousGiven, period: period,
                                            today: today, calendar: calendar))
            }
        }
        return states
    }

    private static func openStepState(
        _ step: FertilizerStep, previousGiven: Date?, period: FertilizerPeriod, today: Date, calendar: Calendar
    ) -> FertilizerStepState {
        let opensOn: Date
        let closesOn: Date
        if let previousGiven, let gap = step.gapBefore {
            opensOn = adding(gap.minDays, to: previousGiven, calendar: calendar)
            closesOn = adding(gap.maxDays, to: previousGiven, calendar: calendar)
        } else {
            opensOn = calendar.startOfDay(for: previousGiven ?? period.startDate)
            closesOn = calendar.startOfDay(for: period.endDate)
        }

        if days(from: today, to: opensOn, calendar: calendar) > 0 { return .waiting(startsOn: opensOn) }
        let daysLate = days(from: closesOn, to: today, calendar: calendar)
        return daysLate > 0 ? .overdue(daysLate: daysLate) : .due
    }

    private static func gapState(
        previous: FertilizerStepState, next: FertilizerStepState, today: Date, calendar: Calendar
    ) -> FertilizerGapState {
        guard case .given = previous else { return .pending }
        switch next {
        case .given, .due, .overdue: return .elapsed
        case .waiting(let opensOn): return .counting(daysRemaining: days(from: today, to: opensOn, calendar: calendar))
        case .locked: return .pending
        }
    }

    static func days(from start: Date, to end: Date, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0
    }

    private static func adding(_ days: Int, to date: Date, calendar: Calendar) -> Date {
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: days, to: start) ?? start
    }
}
