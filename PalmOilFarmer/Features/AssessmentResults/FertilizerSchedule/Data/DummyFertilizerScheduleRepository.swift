import Foundation

/// Sample schedule built from the same CloudKit contract payload used by production records.
actor DummyFertilizerScheduleRepository: FertilizerScheduleRepositoryProtocol {
    private let gardenName: String
    private let locationName: String
    private let scheduleItems: [FertilizationSchedulePeriodItem]

    init(
        gardenName: String = "Kebun Belakang Rumah",
        locationName: String = "Malang Rapat, Bintan"
    ) {
        self.gardenName = gardenName
        self.locationName = locationName
        scheduleItems = Self.sampleItems
    }

    func fetchSchedule(gardenID: UUID) async throws -> FertilizerSchedule {
        FertilizerSchedule(
            gardenName: gardenName,
            locationName: locationName,
            periods: scheduleItems.map { period in
                FertilizerPeriod(
                    id: UUID(),
                    sequence: period.order,
                    startDate: period.startDate,
                    endDate: period.endDate,
                    steps: period.fertilizers.map { fertilizer in
                        FertilizerStep(
                            id: UUID(),
                            order: fertilizer.step,
                            name: fertilizer.fertilizerType.rawValue,
                            quantityKg: fertilizer.amountPerRoundKg,
                            gapBefore: nil,
                            givenDate: fertilizer.doneAt
                        )
                    }
                )
            }
        )
    }

    private static var sampleItems: [FertilizationSchedulePeriodItem] {
        [
            FertilizationSchedulePeriodItem(
                order: 1,
                startDate: date(2027, 1, 1),
                endDate: date(2027, 2, 28),
                fertilizers: [
                    .init(fertilizerType: .dolomite, step: 1, amountPerRoundKg: 400),
                    .init(fertilizerType: .npk15_15_15, step: 2, amountPerRoundKg: 120),
                    .init(fertilizerType: .urea, step: 3, amountPerRoundKg: 100)
                ]
            ),
            FertilizationSchedulePeriodItem(
                order: 2,
                startDate: date(2027, 5, 1),
                endDate: date(2027, 6, 30),
                fertilizers: [
                    .init(fertilizerType: .npk15_15_15, step: 1, amountPerRoundKg: 120),
                    .init(fertilizerType: .urea, step: 2, amountPerRoundKg: 100)
                ]
            ),
            FertilizationSchedulePeriodItem(
                order: 3,
                startDate: date(2027, 9, 1),
                endDate: date(2027, 10, 31),
                fertilizers: [
                    .init(fertilizerType: .npk13_6_27_4, step: 1, amountPerRoundKg: 115),
                    .init(fertilizerType: .urea, step: 2, amountPerRoundKg: 100)
                ]
            )
        ]
    }

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Jakarta") ?? .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }
}
