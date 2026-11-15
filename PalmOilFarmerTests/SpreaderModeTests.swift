import CoreLocation
import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct SpreaderModeTests {
    private let zones = WaypointZoning.zones(for: WaypointPreviewData.garden.boundary)

    @Test func samplePlanSendsTotalDividedByTrees() throws {
        let plans = SpreaderZonePlan.sample(for: zones)
        #expect(plans.count == 6)
        let plan = try #require(plans[2])
        #expect(plan.treeCount > 0)
        #expect(plan.dosePerTreeKg == 1.5)
        #expect(abs(plan.litersPerTree - 0.75) < 0.000_001)
        #expect(SpreaderDose.validated(liters: plan.litersPerTree) != nil)
    }

    @Test func eachZoneContainsItsOwnDestination() {
        for zone in zones {
            #expect(SpreaderGeometry.zoneID(containing: zone.destination, in: zones) == zone.id)
        }
    }

    @Test func pointOutsideGardenHasNoZone() {
        let far = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        #expect(SpreaderGeometry.zoneID(containing: far, in: zones) == nil)
    }

    @Test func separatorsSkipSeamsInsideZones() {
        let allEdges = zones.flatMap(\.fragments).reduce(0) { $0 + $1.count }
        let separators = SpreaderGeometry.separators(for: zones)
        #expect(!separators.isEmpty)
        #expect(separators.count < allEdges)
    }

    @Test func deviceNameDropsAdvertisingPrefix() {
        #expect(SpreaderFormat.deviceName("KROPS-SPR-A1B2") == "Spreader A1B2")
        #expect(SpreaderFormat.deviceName("Lainnya") == "Lainnya")
        #expect(SpreaderFormat.headerName("KROPS-SPR-A1B2") == "KROPS Spreader A1B2")
        #expect(SpreaderFormat.headerName("ESP32-Pupuk") == "ESP32-Pupuk")
    }

    @Test func sampleDoseIsOneCommand() throws {
        let plan = try #require(SpreaderZonePlan.sample(for: zones)[2])
        let total = try #require(SpreaderPulse.milliseconds(liters: plan.litersPerTree))
        #expect(String(data: SpreaderPulse.command(milliseconds: total), encoding: .utf8) == "T:15517")
    }

    @Test func kilogramsUseIndonesianDecimalComma() {
        #expect(SpreaderFormat.kilograms(1.5) == "1,5 kg")
        #expect(SpreaderFormat.kilograms(97.4, maxFraction: 0) == "97 kg")
    }
}
