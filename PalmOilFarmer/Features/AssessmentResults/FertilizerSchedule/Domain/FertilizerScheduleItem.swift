import Foundation

public struct FertilizerSchedule: Equatable, Sendable {
    public let gardenName: String
    public let locationName: String
    public let periods: [FertilizerPeriod]
}

public struct FertilizerPeriod: Identifiable, Equatable, Sendable {
    public let id: UUID
    /// Shown as "Pemupukan N".
    public let sequence: Int
    public let startDate: Date
    public let endDate: Date
    public let steps: [FertilizerStep]
}

public struct FertilizerStep: Identifiable, Equatable, Sendable {
    public let id: UUID
    /// 1-based position within the period.
    public let order: Int
    public let name: String
    public let quantityKg: Double
    /// Waiting window after the previous step; nil for the first step.
    public let gapBefore: FertilizerGap?
    public let givenDate: Date?
}

/// A fixed gap has `minDays == maxDays`; a range gap allows the next step anywhere inside it.
public struct FertilizerGap: Equatable, Sendable {
    public let minDays: Int
    public let maxDays: Int

    public var isFixed: Bool { minDays == maxDays }
}
