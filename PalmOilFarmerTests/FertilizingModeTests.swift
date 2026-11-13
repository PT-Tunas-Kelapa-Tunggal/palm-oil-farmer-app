import CoreLocation
import Foundation
import Testing
@testable import PalmOilFarmer

@MainActor
struct FertilizingModeTests {
    private let zones = WaypointZoning.zones(for: WaypointPreviewData.garden.boundary)

    @Test func samplePlanSendsTotalDividedByTrees() throws {
        let plans = FertilizingZonePlan.sample(for: zones)
        #expect(plans.count == 6)
        let plan = try #require(plans[2])
        #expect(plan.treeCount > 0)
        #expect(plan.dosePerTreeKg == 1.5)
        #expect(abs(plan.litersPerTree - 0.75) < 0.000_001)
        #expect(SpreaderDose.validated(liters: plan.litersPerTree) != nil)
    }

    @Test func eachZoneContainsItsOwnDestination() {
        for zone in zones {
            #expect(FertilizingGeometry.zoneID(containing: zone.destination, in: zones) == zone.id)
        }
    }

    @Test func pointOutsideGardenHasNoZone() {
        let far = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        #expect(FertilizingGeometry.zoneID(containing: far, in: zones) == nil)
    }

    @Test func separatorsSkipSeamsInsideZones() {
        let allEdges = zones.flatMap(\.fragments).reduce(0) { $0 + $1.count }
        let separators = FertilizingGeometry.separators(for: zones)
        #expect(!separators.isEmpty)
        #expect(separators.count < allEdges)
    }

    @Test func deviceNameDropsAdvertisingPrefix() {
        #expect(FertilizingFormat.deviceName("KROPS-SPR-A1B2") == "Spreader A1B2")
        #expect(FertilizingFormat.deviceName("Lainnya") == "Lainnya")
        #expect(FertilizingFormat.headerName("KROPS-SPR-A1B2") == "KROPS Spreader A1B2")
        #expect(FertilizingFormat.headerName("ESP32-Pupuk") == "ESP32-Pupuk")
    }

    @Test func sampleDoseIsOneCommand() throws {
        let plan = try #require(FertilizingZonePlan.sample(for: zones)[2])
        let total = try #require(SpreaderPulse.milliseconds(liters: plan.litersPerTree))
        #expect(String(data: SpreaderPulse.command(milliseconds: total), encoding: .utf8) == "T:15517")
    }

    @Test func kilogramsUseIndonesianDecimalComma() {
        #expect(FertilizingFormat.kilograms(1.5) == "1,5 kg")
        #expect(FertilizingFormat.kilograms(97.4, maxFraction: 0) == "97 kg")
    }
}
