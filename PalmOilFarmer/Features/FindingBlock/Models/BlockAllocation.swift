import Foundation

enum BlockAllocation {
    static func kilograms(from text: String) -> Double? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let kilograms = Double(value), kilograms.isFinite, kilograms > 0 else { return nil }
        return kilograms
    }

    /// Distributes the user's planned quantity by measured block area, not a suggested dose.
    static func quantities(totalKilograms: Double, blocks: [GardenBlock]) -> [Int: Double] {
        guard totalKilograms.isFinite, totalKilograms > 0, !blocks.isEmpty,
              blocks.allSatisfy({ $0.areaSquareMeters.isFinite && $0.areaSquareMeters > 0 }),
              Set(blocks.map(\.id)).count == blocks.count else { return [:] }
        let totalArea = blocks.reduce(0) { $0 + $1.areaSquareMeters }
        guard totalArea.isFinite, totalArea > 0 else { return [:] }
        return Dictionary(uniqueKeysWithValues: blocks.map {
            ($0.id, totalKilograms * ($0.areaSquareMeters / totalArea))
        })
    }
}
