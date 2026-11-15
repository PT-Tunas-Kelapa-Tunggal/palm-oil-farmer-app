import Foundation

nonisolated public struct FertilizerComposition: Codable, Sendable, Equatable {
    public var nitrogen: Double?
    public var phosphorus: Double?
    public var potassium: Double?
    public var magnesium: Double?

    var isValid: Bool {
        guard let nitrogen, let phosphorus, let potassium else { return false }
        let values = [nitrogen, phosphorus, potassium, magnesium ?? 0]
        let total = values.reduce(0, +)
        return values.allSatisfy { $0.isFinite && (0...100).contains($0) }
            && total > 0 && total <= 100
    }

    var label: String {
        [nitrogen ?? 0, phosphorus ?? 0, potassium ?? 0]
            .map { $0.formatted(.number.precision(.fractionLength(0...2))) }
            .joined(separator: "-")
    }
}
