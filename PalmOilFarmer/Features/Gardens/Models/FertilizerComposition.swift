import Foundation

/// Nutrient percentages read from the fertilizer packaging.
public struct FertilizerComposition: Codable, Equatable, Sendable {
    public var nitrogen: Double?
    public var phosphorus: Double?
    public var potassium: Double?
    public var magnesium: Double?

    public var isValid: Bool {
        guard let nitrogen, let phosphorus, let potassium else { return false }
        let values = [nitrogen, phosphorus, potassium, magnesium ?? 0]
        return values.allSatisfy { $0.isFinite && (0...100).contains($0) }
            && values.reduce(0, +) > 0 && values.reduce(0, +) <= 100
    }

    public init(nitrogen: Double? = nil, phosphorus: Double? = nil,
                potassium: Double? = nil, magnesium: Double? = nil) {
        self.nitrogen = nitrogen
        self.phosphorus = phosphorus
        self.potassium = potassium
        self.magnesium = magnesium
    }

    static func fromLabel(_ name: String) -> Self {
        let values = name.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap(Double.init)
        guard name.uppercased().hasPrefix("NPK"), values.count == 3 else { return Self() }
        let composition = Self(nitrogen: values[0], phosphorus: values[1], potassium: values[2])
        return composition.isValid ? composition : Self()
    }
}
