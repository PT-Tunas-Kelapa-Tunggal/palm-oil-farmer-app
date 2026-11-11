import XCTest
import SwiftUI
@testable import PalmOilFarmer

/// Opt-in render audit. Captures production views without driving the computer UI.
@MainActor
final class GardenProfileVisualTests: XCTestCase {
    func testRenderHiFidelityProfiles() async throws {
        guard ProcessInfo.processInfo.environment["PROFILE_VISUAL_AUDIT"] == "1" else {
            throw XCTSkip("Set PROFILE_VISUAL_AUDIT=1 to export the visual audit")
        }
        try await capture("missing", height: 874, view: GardenProfileCanvasFixtures.content(complete: false))
        try await capture("complete", height: 1045, view: GardenProfileCanvasFixtures.content(complete: true))
        try await capture("saved", height: 1078, view: GardenProfileCanvasFixtures.content(complete: true, justSaved: true))
        try await capture("form", height: 1317, view: GardenProfileEditorView(viewModel: GardenProfileCanvasFixtures.makeEditor(), onClose: {}))
        try await capture("summary", height: 1025, view: GardenProfileSummaryView(garden: GardenProfileCanvasFixtures.completeGarden, metrics: GardenDisplayMetrics(area: "1,7 ha", perimeter: "540 m"), onClose: {}, onEdit: {}))
        try await capture("information", height: 1227, view: GardenReviewInformationView(onClose: {}, onApply: {}))
        try await capture("form-accessibility", height: 1500, view: GardenProfileEditorView(viewModel: GardenProfileCanvasFixtures.makeEditor(), onClose: {}).environment(\.dynamicTypeSize, .accessibility3))
        try await capture("complete-dark", height: 1045, view: GardenProfileCanvasFixtures.content(complete: true).environment(\.colorScheme, .dark))
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
        let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("profile-hifid-audit")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent(name + ".png")
        try XCTUnwrap(image.pngData()).write(to: destination)
        print("PROFILE_RENDER: \(destination.path)")
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        window.isHidden = true
    }
}
