import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct FertilizerScheduleTimelineTests {
    private typealias Fixture = FertilizerSchedulePreviewData
    private typealias ID = FertilizerSchedulePreviewData.ID

    private let calendar = Fixture.calendar

    private func overview(_ scenario: Fixture.Scenario) -> FertilizerScheduleOverview {
        FertilizerScheduleTimeline.overview(for: scenario.schedule, today: scenario.today, calendar: calendar)
    }

    private func progress(_ scenario: Fixture.Scenario) throws -> ActivePeriodProgress {
        guard case .active(let progress) = overview(scenario).featured else {
            Issue.record("Expected an active period")
            throw CancellationError()
        }
        return progress
    }

    /// Step and gap states in timeline order, e.g. [given, counting(7), waiting, pending, locked].
    private enum Entry: Equatable {
        case step(FertilizerStepState)
        case gap(FertilizerGapState)
    }

    private func entries(_ progress: ActivePeriodProgress) -> [Entry] {
        progress.entries.map {
            switch $0 {
            case .step(_, let state): .step(state)
            case .gap(_, let state, _): .gap(state)
            }
        }
    }

    private func nextDays(_ overview: FertilizerScheduleOverview) -> [Int] {
        overview.nextPeriods.map(\.daysUntilStart)
    }

    @Test func beforeFirstPeriodFeaturesUpcomingPeriod() {
        let result = overview(Fixture.beforePeriod)
        #expect(result.featured == .upcoming(Fixture.schedule().periods[0], daysUntilStart: 42))
        #expect(result.nextPeriods.map(\.period.id) == [ID.period2, ID.period3])
        #expect(nextDays(result) == [162, 285])
        #expect(result.completedPeriods.isEmpty)
    }

    @Test func day5DolomitIsDue() throws {
        let progress = try progress(Fixture.day5Dolomit)
        #expect(progress.dayNumber == 5)
        #expect(progress.totalDays == 59)
        #expect(entries(progress) == [.step(.due), .gap(.pending), .step(.locked), .gap(.pending), .step(.locked)])
        #expect(nextDays(overview(Fixture.day5Dolomit)) == [116, 239])
    }

    @Test func day12CountsDownFixedGap() throws {
        let progress = try progress(Fixture.day12Gap)
        #expect(progress.dayNumber == 12)
        #expect(progress.totalDays == 59)
        #expect(entries(progress) == [
            .step(.given(Fixture.date(2027, 1, 5))), .gap(.counting(daysRemaining: 7)),
            .step(.waiting(startsOn: Fixture.date(2027, 1, 19))), .gap(.pending), .step(.locked)
        ])
        let result = overview(Fixture.day12Gap)
        #expect(result.nextPeriods.map(\.period.id) == [ID.period2, ID.period3])
        #expect(nextDays(result) == [109, 232])
    }

    /// The fixed 14-day gap closes on 19 January, so on day 21 NPK is two days late.
    @Test func day21NPKIsPastFixedGap() throws {
        let progress = try progress(Fixture.day21NPK)
        #expect(progress.dayNumber == 21)
        #expect(entries(progress) == [
            .step(.given(Fixture.date(2027, 1, 5))), .gap(.elapsed),
            .step(.overdue(daysLate: 2)), .gap(.pending), .step(.locked)
        ])
        #expect(nextDays(overview(Fixture.day21NPK)) == [100, 223])
    }

    @Test func day21CountsDownRangeGap() throws {
        let progress = try progress(Fixture.day21Gap)
        #expect(progress.dayNumber == 21)
        #expect(entries(progress) == [
            .step(.given(Fixture.date(2027, 1, 5))), .gap(.elapsed),
            .step(.given(Fixture.date(2027, 1, 21))), .gap(.counting(daysRemaining: 1)),
            .step(.waiting(startsOn: Fixture.date(2027, 1, 22)))
        ])
    }

    @Test func day25UreaIsDue() throws {
        let progress = try progress(Fixture.day25Urea)
        #expect(progress.dayNumber == 25)
        #expect(entries(progress) == [
            .step(.given(Fixture.date(2027, 1, 5))), .gap(.elapsed),
            .step(.given(Fixture.date(2027, 1, 21))), .gap(.elapsed), .step(.due)
        ])
        #expect(nextDays(overview(Fixture.day25Urea)) == [96, 219])
    }

    @Test func betweenPeriodsFeaturesNextAndListsCompleted() {
        let result = overview(Fixture.betweenPeriods)
        #expect(result.featured == .upcoming(Fixture.betweenPeriods.schedule.periods[1], daysUntilStart: 61))
        #expect(result.nextPeriods.map(\.period.id) == [ID.period3])
        #expect(nextDays(result) == [184])
        #expect(result.completedPeriods.map(\.period.id) == [ID.period1])
        #expect(result.completedPeriods.first?.completedOn == Fixture.date(2027, 1, 25))
    }

    @Test func periodCompletesBeforeItsEndDate() {
        let period = Fixture.betweenPeriods.schedule.periods[0]
        let status = FertilizerScheduleTimeline.status(of: period, today: Fixture.date(2027, 1, 26), calendar: calendar)
        #expect(status == .completed(on: Fixture.date(2027, 1, 25)))
    }

    @Test func ureaPastRangeGapIsOverdue() throws {
        let progress = try progress(Fixture.ureaOverdue)
        #expect(progress.dayNumber == 30)
        #expect(entries(progress).last == .step(.overdue(daysLate: 2)))
    }

    @Test func comparesCalendarDaysNotTimestamps() throws {
        let lateEvening = try #require(calendar.date(byAdding: .hour, value: 23, to: Fixture.date(2027, 1, 12)))
        let scenario = Fixture.Scenario(today: lateEvening, schedule: Fixture.day12Gap.schedule)
        let progress = try progress(scenario)
        #expect(progress.dayNumber == 12)
        #expect(entries(progress)[1] == .gap(.counting(daysRemaining: 7)))
    }
}

@MainActor
struct FertilizerSchedulePresentationTests {
    private typealias Fixture = FertilizerSchedulePreviewData

    private func presentation(_ scenario: Fixture.Scenario) -> FertilizerSchedulePresentation {
        let overview = FertilizerScheduleTimeline.overview(for: scenario.schedule, today: scenario.today, calendar: Fixture.calendar)
        return FertilizerSchedulePresentation(schedule: scenario.schedule, overview: overview,
                                              today: scenario.today, calendar: Fixture.calendar)
    }

    @Test func formatsActiveHeroAndRows() {
        let result = presentation(Fixture.day12Gap)
        #expect(result.subtitle == "Kebun Belakang Rumah, Malang Rapat")
        #expect(result.nextPeriodsSubtitle == "Dua periode lagi setelah Januari–Februari.")
        #expect(result.nextPeriods.map(\.caption) == [
            "Pemupukan 2, dimulai 109 hari lagi", "Pemupukan 3, dimulai 232 hari lagi"
        ])
        #expect(result.nextPeriods.map(\.title) == ["Mei–Juni", "September–Oktober"])
        guard case .active(let range, let dayTitle, let daySubtitle, let rows) = result.hero else {
            Issue.record("Expected active hero")
            return
        }
        #expect(range == .init(startDay: "1 Jan", startDetail: "Jumat, 2027", endDay: "28 Feb",
                               endDetail: "Minggu, 2027", length: "59 hari"))
        #expect(dayTitle == "Hari ke-12")
        #expect(daySubtitle == "dari 59 hari")
        let texts = rows.map { row -> String in
            switch row {
            case .step(let step): [step.name, step.quantity, step.subtitle ?? "-"].joined(separator: " | ")
            case .gap(let gap): gap.text
            }
        }
        #expect(texts == [
            "Dolomit | 400 kg | Diberikan 5 Januari",
            "Masa jeda 14 hari, sisa 7 hari",
            "NPK 15-15-15 | 120 kg | Mulai 19 Januari",
            "Tunggu 1–7 hari",
            "Urea | 100 kg | -"
        ])
        if case .step(let dolomit) = rows.first {
            #expect(dolomit.accessibilityLabel == "Dolomit, 400 kilogram, diberikan 5 Januari, selesai")
        }
    }

    @Test func formatsBetweenPeriodsAndSheet() throws {
        let result = presentation(Fixture.betweenPeriods)
        #expect(result.hero == .upcoming(
            periodID: Fixture.ID.period2, title: "Dimulai 61 hari lagi",
            range: .init(startDay: "1 Mei", startDetail: "Sabtu, 2027", endDay: "30 Jun",
                         endDetail: "Rabu, 2027", length: "61 hari")
        ))
        #expect(result.nextPeriodsSubtitle == "Satu periode lagi setelah Mei–Juni.")
        #expect(result.completedPeriods.map(\.caption) == ["Pemupukan 1, selesai 25 Januari"])

        let sheet = try #require(result.sheets[Fixture.ID.period3])
        #expect(sheet.title == "Pemupukan 3")
        #expect(sheet.description == "September–Oktober, dimulai 184 hari lagi. Ketuk jenis pupuk untuk melihat dosis tiap pohon di peta.")
        #expect(sheet.total == "215 kg")
        #expect(sheet.rows.count == 3)
        #expect(result.sheets[Fixture.ID.period1]?.description.hasPrefix("Januari–Februari, selesai 25 Januari.") == true)
    }

    @Test func viewModelSelectingStepClosesSheet() async {
        let model = FertilizerScheduleViewModel(
            gardenID: Fixture.ID.garden, repository: StubFertilizerScheduleRepository(),
            now: { Fixture.date(2027, 3, 1) }, calendar: Fixture.calendar
        )
        await model.load()
        model.openPeriod(Fixture.ID.period3)
        #expect(model.presentedPeriod?.title == "Pemupukan 3")
        model.selectStep(Fixture.ID.npk3)
        #expect(model.presentedPeriodID == nil)
        #expect(model.destination == .exampleScreen(stepID: Fixture.ID.npk3))
    }

    @Test func viewModelReportsLoadFailure() async {
        let model = FertilizerScheduleViewModel(
            gardenID: Fixture.ID.garden,
            repository: StubFertilizerScheduleRepository(error: StubFertilizerScheduleRepository.LoadError()),
            calendar: Fixture.calendar
        )
        await model.load()
        guard case .failed(let message) = model.state else {
            Issue.record("Expected failure")
            return
        }
        #expect(message == "Jadwal pemupukan belum bisa dimuat.")
    }
}
