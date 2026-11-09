import Foundation

/// Stable selection identity; labels can change without changing NPK behavior.
enum FertilizerType: Hashable {
    case unselected, urea, za, npk, sp36, kcl, dolomite, kieserite, manure, other
    case custom(String)
}

enum FertilizerCatalogue {
    static let options: [FertilizerType] = [
        .urea, .za, .npk, .sp36, .custom("TSP"), .kcl, .dolomite, .kieserite,
        .custom("Borat"), .manure, .custom("Pupuk Organik"), .other
    ]

    static var names: [String] { options.map(displayName) }

    static func displayName(for kind: FertilizerType) -> String {
        storedName(for: kind)
    }

    /// Persisted names remain stable even when a display label changes.
    static func storedName(for kind: FertilizerType) -> String {
        switch kind {
        case .unselected: ""
        case .urea: "Urea"
        case .za: "ZA"
        case .npk: "NPK"
        case .sp36: "SP-36"
        case .kcl: "KCl (MOP)"
        case .dolomite: "Dolomit"
        case .kieserite: "Kieserit"
        case .manure: "Pupuk kandang"
        case .other: "Lainnya"
        case .custom(let name): name
        }
    }

    static func kind(for name: String) -> FertilizerType {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .unselected }
        return options.first { storedName(for: $0) == trimmed } ?? .custom(trimmed)
    }
}
