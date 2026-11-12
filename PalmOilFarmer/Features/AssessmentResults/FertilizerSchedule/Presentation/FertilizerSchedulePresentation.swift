import Foundation

/// Every string the fertilizer schedule screens show, so the views do no date math.
struct FertilizerSchedulePresentation {
    struct DateRange: Equatable {
        let startDay: String
        let startDetail: String
        let endDay: String
        let endDetail: String
        let length: String
    }

    struct StepRow: Identifiable, Equatable {
        enum Style: Equatable { case given, highlighted, waiting, locked }

        let id: UUID
        let order: Int
        let name: String
        let quantity: String
        let subtitle: String?
        let style: Style
        let accessibilityLabel: String
    }

    struct GapRow: Identifiable, Equatable {
        enum Style: Equatable { case pending, elapsed, counting }

        let id: String
        let text: String
        let style: Style
    }

    enum TimelineRow: Identifiable, Equatable {
        case step(StepRow)
        case gap(GapRow)

        var id: String {
            switch self {
            case .step(let row): "step-\(row.id)"
            case .gap(let row): row.id
            }
        }
    }

    enum Hero: Equatable {
        case active(range: DateRange, dayTitle: String, daySubtitle: String, rows: [TimelineRow])
        case upcoming(periodID: UUID, title: String, range: DateRange)
    }

    struct NextPeriodCard: Identifiable, Equatable {
        let id: UUID
        let caption: String
        let title: String
        let fertilizers: [String]
    }

    struct CompletedPeriodCard: Identifiable, Equatable {
        let id: UUID
        let caption: String
        let title: String
    }

    struct PeriodSheet: Identifiable, Equatable {
        let id: UUID
        let title: String
        let description: String
        let rows: [TimelineRow]
        let total: String
    }

    let subtitle: String
    let hero: Hero?
    let nextPeriodsSubtitle: String?
    let nextPeriods: [NextPeriodCard]
    let completedPeriods: [CompletedPeriodCard]
    let sheets: [UUID: PeriodSheet]

    var isEmpty: Bool { hero == nil && nextPeriods.isEmpty && completedPeriods.isEmpty }
}

extension FertilizerSchedulePresentation {
    init(schedule: FertilizerSchedule, overview: FertilizerScheduleOverview, today: Date, calendar: Calendar) {
        let format = ScheduleFormatter(calendar: calendar)
        subtitle = "\(schedule.gardenName), \(schedule.locationName)"

        switch overview.featured {
        case .active(let progress):
            hero = .active(
                range: format.range(progress.period),
                dayTitle: "Hari ke-\(progress.dayNumber)",
                daySubtitle: "dari \(progress.totalDays) hari",
                rows: progress.entries.map { format.row($0, inSheet: false) }
            )
        case .upcoming(let period, let days):
            hero = .upcoming(periodID: period.id, title: "Dimulai \(days) hari lagi", range: format.range(period))
        case nil:
            hero = nil
        }

        nextPeriods = overview.nextPeriods.map {
            NextPeriodCard(
                id: $0.period.id,
                caption: "Pemupukan \($0.period.sequence), dimulai \($0.daysUntilStart) hari lagi",
                title: format.title($0.period),
                fertilizers: $0.period.steps.sorted { $0.order < $1.order }.map(\.name)
            )
        }
        if let featured = overview.featured, !nextPeriods.isEmpty {
            nextPeriodsSubtitle = "\(Self.countWord(nextPeriods.count)) periode lagi setelah \(format.title(featured.period))."
        } else {
            nextPeriodsSubtitle = nil
        }

        completedPeriods = overview.completedPeriods.map {
            CompletedPeriodCard(
                id: $0.period.id,
                caption: "Pemupukan \($0.period.sequence), selesai \(format.dayMonth($0.completedOn))",
                title: format.title($0.period)
            )
        }

        var sheets: [UUID: PeriodSheet] = [:]
        for period in schedule.periods {
            let status: String
            switch FertilizerScheduleTimeline.status(of: period, today: today, calendar: calendar) {
            case .completed(let date): status = "selesai \(format.dayMonth(date))"
            case .active: status = "sedang berlangsung"
            case .upcoming(let days): status = "dimulai \(days) hari lagi"
            }
            sheets[period.id] = PeriodSheet(
                id: period.id,
                title: "Pemupukan \(period.sequence)",
                description: "\(format.title(period)), \(status). Ketuk jenis pupuk untuk melihat dosis tiap pohon di peta.",
                rows: FertilizerScheduleTimeline.entries(for: period, today: today, calendar: calendar)
                    .map { format.row($0, inSheet: true) },
                total: format.quantity(period.steps.reduce(0) { $0 + $1.quantityKg })
            )
        }
        self.sheets = sheets
    }

    static func countWord(_ count: Int) -> String {
        switch count {
        case 1: "Satu"
        case 2: "Dua"
        case 3: "Tiga"
        case 4: "Empat"
        case 5: "Lima"
        default: "\(count)"
        }
    }

    static func gapLength(_ gap: FertilizerGap) -> String {
        gap.isFixed ? "\(gap.minDays) hari" : "\(gap.minDays)–\(gap.maxDays) hari"
    }
}

private struct ScheduleFormatter {
    private let shortDate: DateFormatter
    private let weekdayYear: DateFormatter
    private let longDate: DateFormatter
    private let month: DateFormatter
    private let calendar: Calendar
    private let locale = Self.locale
    private static let locale = Locale(identifier: "id_ID")

    init(calendar: Calendar) {
        self.calendar = calendar
        shortDate = Self.formatter("d MMM", calendar: calendar)
        weekdayYear = Self.formatter("EEEE, yyyy", calendar: calendar)
        longDate = Self.formatter("d MMMM", calendar: calendar)
        month = Self.formatter("MMMM", calendar: calendar)
    }

    private static func formatter(_ pattern: String, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = pattern
        return formatter
    }

    func dayMonth(_ date: Date) -> String { longDate.string(from: date) }

    func quantity(_ kg: Double) -> String {
        "\(number(kg)) kg"
    }

    func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).locale(locale))
    }

    func title(_ period: FertilizerPeriod) -> String {
        let start = month.string(from: period.startDate)
        let end = month.string(from: period.endDate)
        let sameMonth = calendar.isDate(period.startDate, equalTo: period.endDate, toGranularity: .month)
        return sameMonth ? start : "\(start)–\(end)"
    }

    func range(_ period: FertilizerPeriod) -> FertilizerSchedulePresentation.DateRange {
        let days = FertilizerScheduleTimeline.days(from: period.startDate, to: period.endDate, calendar: calendar) + 1
        return .init(
            startDay: shortDate.string(from: period.startDate),
            startDetail: weekdayYear.string(from: period.startDate),
            endDay: shortDate.string(from: period.endDate),
            endDetail: weekdayYear.string(from: period.endDate),
            length: "\(days) hari"
        )
    }

    /// The sheet is a plain list of what to give, so only given steps keep their status look there.
    func row(_ entry: FertilizerTimelineEntry, inSheet: Bool) -> FertilizerSchedulePresentation.TimelineRow {
        switch entry {
        case .step(let step, let state):
            return .step(stepRow(step, state: state, inSheet: inSheet))
        case .gap(let gap, let state, let stepID):
            let length = FertilizerSchedulePresentation.gapLength(gap)
            let text: String
            let style: FertilizerSchedulePresentation.GapRow.Style
            switch state {
            case .pending:
                (text, style) = ("Tunggu \(length)", .pending)
            case .elapsed:
                (text, style) = ("Jeda \(length)", .elapsed)
            case .counting(let days) where !inSheet:
                (text, style) = ("Masa jeda \(length), sisa \(days) hari", .counting)
            case .counting:
                (text, style) = ("Tunggu \(length)", .pending)
            }
            return .gap(.init(id: "gap-\(stepID)", text: text, style: style))
        }
    }

    private func stepRow(
        _ step: FertilizerStep, state: FertilizerStepState, inSheet: Bool
    ) -> FertilizerSchedulePresentation.StepRow {
        let subtitle: String?
        let style: FertilizerSchedulePresentation.StepRow.Style
        let status: String
        switch state {
        case .given(let date):
            subtitle = "Diberikan \(dayMonth(date))"
            style = .given
            status = "diberikan \(dayMonth(date)), selesai"
        case .due:
            subtitle = nil
            style = .highlighted
            status = "harus diberikan sekarang"
        case .overdue(let days):
            subtitle = "Terlambat \(days) hari"
            style = .highlighted
            status = "terlambat \(days) hari, harus diberikan sekarang"
        case .waiting(let date):
            subtitle = "Mulai \(dayMonth(date))"
            style = .waiting
            status = "mulai \(dayMonth(date))"
        case .locked:
            subtitle = nil
            style = .locked
            status = "menunggu pupuk sebelumnya"
        }

        let plainInSheet = inSheet && style != .given
        return .init(
            id: step.id,
            order: step.order,
            name: step.name,
            quantity: quantity(step.quantityKg),
            subtitle: plainInSheet ? nil : subtitle,
            style: plainInSheet ? .locked : style,
            accessibilityLabel: plainInSheet
                ? "\(step.name), \(number(step.quantityKg)) kilogram"
                : "\(step.name), \(number(step.quantityKg)) kilogram, \(status)"
        )
    }
}
