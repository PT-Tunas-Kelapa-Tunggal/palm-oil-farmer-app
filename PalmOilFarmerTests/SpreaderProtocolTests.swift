import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct SpreaderProtocolTests {
    @Test func commandIsUTF8TimeText() {
        #expect(String(data: SpreaderPulse.command(milliseconds: 5517), encoding: .utf8) == "T:5517")
        #expect(String(data: SpreaderPulse.command(milliseconds: 10_000), encoding: .utf8) == "T:10000")
    }

    @Test func litersBecomeMillisecondsAtMeasuredFlow() {
        #expect(SpreaderLimits.litersPerMinute == 2.9)
        #expect(SpreaderPulse.milliseconds(liters: 0.75) == 15_517)
        #expect(SpreaderPulse.milliseconds(liters: 2.9) == 60_000)
        #expect(SpreaderPulse.milliseconds(liters: 0) == nil)
        #expect(SpreaderPulse.milliseconds(liters: .nan) == nil)
        #expect(SpreaderPulse.milliseconds(liters: SpreaderLimits.maxLiters + 0.1) == nil)
    }

    @Test func oneDoseIsOneCommandEvenAboveTenSeconds() throws {
        let milliseconds = try #require(SpreaderPulse.milliseconds(liters: 0.75))
        #expect(milliseconds > 10_000)
        #expect(String(data: SpreaderPulse.command(milliseconds: milliseconds), encoding: .utf8) == "T:15517")
    }

    @Test func runProgressFollowsTheClock() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let run = DispenseRun(zoneID: 2, liters: 0.4, milliseconds: 8_000, startedAt: start)
        #expect(run.progress(at: start) == 0)
        #expect(abs(run.progress(at: start.addingTimeInterval(4)) - 0.5) < 0.0001)
        #expect(run.progress(at: start.addingTimeInterval(20)) == 1)
        #expect(run.remainingSeconds(at: start.addingTimeInterval(2.5)) == 6)
    }

    @Test func doseArithmetic() {
        #expect(SpreaderDose.litersPerTree(zoneTotalLiters: 4.5, treeCount: 6) == 0.75)
        #expect(SpreaderDose.litersPerTree(zoneTotalLiters: 4.5, treeCount: 0) == nil)
        #expect(abs((SpreaderDose.seconds(liters: 0.75) ?? 0) - 15.517) < 0.001)
    }
}
