#if DEBUG
import Foundation

struct StubFertilizerScheduleRepository: FertilizerScheduleRepositoryProtocol {
    struct LoadError: Error {}

    var schedule = FertilizerSchedulePreviewData.schedule()
    var delay: Duration?
    var error: (any Error & Sendable)?

    func fetchSchedule(gardenID: UUID) async throws -> FertilizerSchedule {
        if let delay { try await Task.sleep(for: delay) }
        if let error { throw error }
        return schedule
    }
}

enum FertilizerSchedulePreviewData {
    struct Scenario {
        let today: Date
        let schedule: FertilizerSchedule
    }

    enum ID {
        static let garden = id(0xA0)
        static let period1 = id(0x01)
        static let period2 = id(0x02)
        static let period3 = id(0x03)
        static let dolomit1 = id(0x11)
        static let npk1 = id(0x12)
        static let urea1 = id(0x13)
        static let npk2 = id(0x21)
        static let urea2 = id(0x22)
        static let npk3 = id(0x31)
        static let urea3 = id(0x32)

        private static func id(_ value: UInt8) -> UUID {
            UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, value))
        }
    }

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current
        calendar.locale = Locale(identifier: "id_ID")
        return calendar
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    /// `given` maps a step ID to the day that fertilizer was applied.
    static func schedule(given: [UUID: Date] = [:]) -> FertilizerSchedule {
        func step(_ id: UUID, _ order: Int, _ name: String, _ kg: Double, gap: FertilizerGap? = nil) -> FertilizerStep {
            FertilizerStep(id: id, order: order, name: name, quantityKg: kg, gapBefore: gap, givenDate: given[id])
        }
        let shortGap = FertilizerGap(minDays: 1, maxDays: 7)
        return FertilizerSchedule(
            gardenName: "Kebun Belakang Rumah",
            locationName: "Malang Rapat",
            periods: [
                FertilizerPeriod(id: ID.period1, sequence: 1, startDate: date(2027, 1, 1), endDate: date(2027, 2, 28), steps: [
                    step(ID.dolomit1, 1, "Dolomit", 400),
                    step(ID.npk1, 2, "NPK 15-15-15", 120, gap: FertilizerGap(minDays: 14, maxDays: 14)),
                    step(ID.urea1, 3, "Urea", 100, gap: shortGap)
                ]),
                FertilizerPeriod(id: ID.period2, sequence: 2, startDate: date(2027, 5, 1), endDate: date(2027, 6, 30), steps: [
                    step(ID.npk2, 1, "NPK 15-15-15", 120),
                    step(ID.urea2, 2, "Urea", 100, gap: shortGap)
                ]),
                FertilizerPeriod(id: ID.period3, sequence: 3, startDate: date(2027, 9, 1), endDate: date(2027, 10, 31), steps: [
                    step(ID.npk3, 1, "NPK 15-15-15", 115),
                    step(ID.urea3, 2, "Urea", 100, gap: shortGap)
                ])
            ]
        )
    }

    static func scenario(today: Date, given: [UUID: Date] = [:]) -> Scenario {
        Scenario(today: today, schedule: schedule(given: given))
    }

    static let beforePeriod = scenario(today: date(2026, 11, 20))
    static let day5Dolomit = scenario(today: date(2027, 1, 5))
    static let day12Gap = scenario(today: date(2027, 1, 12), given: [ID.dolomit1: date(2027, 1, 5)])
    static let day21NPK = scenario(today: date(2027, 1, 21), given: [ID.dolomit1: date(2027, 1, 5)])
    static let day21Gap = scenario(today: date(2027, 1, 21), given: [
        ID.dolomit1: date(2027, 1, 5), ID.npk1: date(2027, 1, 21)
    ])
    static let day25Urea = scenario(today: date(2027, 1, 25), given: [
        ID.dolomit1: date(2027, 1, 5), ID.npk1: date(2027, 1, 21)
    ])
    static let betweenPeriods = scenario(today: date(2027, 3, 1), given: [
        ID.dolomit1: date(2027, 1, 5), ID.npk1: date(2027, 1, 21), ID.urea1: date(2027, 1, 25)
    ])
    static let ureaOverdue = scenario(today: date(2027, 1, 30), given: [
        ID.dolomit1: date(2027, 1, 5), ID.npk1: date(2027, 1, 21)
    ])
}
#endif
