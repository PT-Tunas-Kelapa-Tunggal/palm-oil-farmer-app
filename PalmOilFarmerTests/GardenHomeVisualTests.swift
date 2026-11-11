import XCTest
import SwiftUI
@testable import PalmOilFarmer

@MainActor
final class GardenHomeVisualTests: XCTestCase {
    func testRenderHome() async throws {
        guard ProcessInfo.processInfo.environment["HOME_VISUAL_AUDIT"] == "1" else { throw XCTSkip("Opt-in Home render audit") }
        var complete = GardenProfileCanvasFixtures.completeGarden
        complete.createdAt = Date(timeIntervalSince1970: 100)
        let incomplete = Garden(id: UUID(), name: "Hilir Sungai", locationName: "Malang Rapat, Bintan", boundary: complete.boundary, plantingYear: 2019, soilType: .peat, createdAt: Date(timeIntervalSince1970: 0))
        let metrics = GardenDisplayMetrics(area: "1,7 ha", perimeter: "540 m")
        let state = DashboardViewState(gardens: [complete, incomplete].map { DashboardMapper().map($0) }, drafts: [], filter: .all)
        let home = DashboardContentView(state: state, selectedFilter: .constant(.all), showsFilter: false,
            referenceMapImage: "HomeReferenceMap", fertilizerSchedules: [complete.id: "Pemupukan 1 dalam 50 hari"],
            previewMetrics: metrics, onRegisterGarden: {})
        try await capture("home", height: 987, view: home)
        try await capture("home-dark", height: 987, view: home.environment(\.colorScheme, .dark))
        try await capture("home-accessibility", height: 1200, view: home.environment(\.dynamicTypeSize, .accessibility3))
        try await capture("empty", height: 874, view: DashboardContentView(state: DashboardViewState(gardens: [], drafts: [], filter: .all), selectedFilter: .constant(.all), showsFilter: false, onRegisterGarden: {}))
        try await capture("incomplete", height: 430, view: DashboardGardenCard(garden: DashboardMapper().map(incomplete), referenceImage: "HomeReferenceMap", metrics: metrics).padding(.horizontal, 16))
        try await capture("ready", height: 430, view: DashboardGardenCard(garden: DashboardMapper().map(complete), referenceImage: "HomeReferenceMap", metrics: metrics).padding(.horizontal, 16))
    }

    private func capture<V: View>(_ name: String, height: CGFloat, view: V) async throws {
        let host = UIHostingController(rootView: view.environment(\.locale, Locale(identifier: "id_ID")).safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: 62) }.background(GardenProfileStyle.background))
        host.safeAreaRegions = []
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 402, height: height)
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.frame = window.bounds
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(600))
        let image = UIGraphicsImageRenderer(size: window.bounds.size).image { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("home-hifid-audit")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent(name + ".png")
        try XCTUnwrap(image.pngData()).write(to: destination)
        print("HOME_RENDER: \(destination.path)")
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        window.isHidden = true
    }
}
