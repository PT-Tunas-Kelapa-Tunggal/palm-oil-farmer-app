import CoreBluetooth
import Foundation

/// BLE settings for the spreader firmware (flashed by the hardware team).
/// Leave a UUID nil when unknown: the app then lists nearby named devices and uses the first
/// writable characteristic it finds. Fill them in once known so only spreaders appear.
enum SpreaderGATT {
    static let service: CBUUID? = nil
    static let command: CBUUID? = nil
    /// Only list devices whose advertised name starts with this, e.g. "KROPS". nil = every named device.
    static let namePrefix: String? = nil
    /// UTF-8 text that stops the pump immediately.
    static let stopCommand: String? = "S"
}

enum SpreaderLimits {
    static let unit = "L"
    /// Measured pump flow.
    static let litersPerMinute = 2.9
    /// Upper bound for one press in the app (5 L ≈ 1 min 43 s at 2.9 L/min).
    /// One dose is always sent as one "T:" command; the firmware must accept durations this long.
    static let maxLiters = 5.0
}

/// Firmware commands (UTF-8): "T:<milliseconds>" turns the pump on for that long, "S" stops it.
enum SpreaderPulse {
    static func command(milliseconds: Int) -> Data {
        Data("T:\(milliseconds)".utf8)
    }

    /// Pump time for a volume at the measured flow.
    static func milliseconds(liters: Double, litersPerMinute: Double = SpreaderLimits.litersPerMinute) -> Int? {
        guard SpreaderDose.validated(liters: liters) != nil, litersPerMinute.isFinite, litersPerMinute > 0 else { return nil }
        let value = Int((liters / litersPerMinute * 60_000).rounded())
        return value > 0 ? value : nil
    }
}

/// Dose arithmetic. The zone total will come from the assessment result.
enum SpreaderDose {
    static func litersPerTree(zoneTotalLiters: Double, treeCount: Int) -> Double? {
        guard treeCount > 0, zoneTotalLiters.isFinite, zoneTotalLiters > 0 else { return nil }
        return zoneTotalLiters / Double(treeCount)
    }

    static func validated(liters: Double) -> Double? {
        guard liters.isFinite, liters > 0, liters <= SpreaderLimits.maxLiters else { return nil }
        return liters
    }

    static func seconds(liters: Double, litersPerMinute: Double = SpreaderLimits.litersPerMinute) -> Double? {
        guard validated(liters: liters) != nil, litersPerMinute.isFinite, litersPerMinute > 0 else { return nil }
        return liters / litersPerMinute * 60
    }
}
