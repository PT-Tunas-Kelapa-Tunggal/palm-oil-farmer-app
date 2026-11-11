import SwiftUI
import MapKit

/// Standalone version of the drawing guide (map demo + its own sheet).
/// Production uses the same pieces inline in `GardenBoundaryView`; this screen is kept for previews/experiments.
struct BoundaryDrawingGuideView: View {
    // A read-only starting position keeps the demonstration out of the mapping camera binding.
    let position: MapCameraPosition
    let fallbackCenter: CLLocationCoordinate2D
    let onBack: () -> Void
    let onContinue: () -> Void

    @State private var guide = BoundaryDrawingGuideViewModel()
    @State private var showsSheet = false
    @State private var sheetHeight: CGFloat = 0
    @State private var pendingExit: Exit?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Exit { case back, continueMapping }

    var body: some View {
        GeometryReader { _ in
            let center = position.camera?.centerCoordinate
                ?? position.region?.center
                ?? fallbackCenter

            let guideRegion = MKCoordinateRegion(
                center: center,
                latitudinalMeters: 400,
                longitudinalMeters: 400
            )

            BoundaryDrawingGuideDemo(
                step: guide.step,
                center: center,
                longitudeDelta: guideRegion.span.longitudeDelta,
                isPlaying: showsSheet && pendingExit == nil,
                bottomSheetHeight: sheetHeight
            )
            .ignoresSafeArea()
        }
        .overlay(alignment: .topLeading) {
            RegistrationIconButton(symbol: "chevron.left", label: "Kembali", action: goBack)
                .padding(.horizontal, KropsTheme.Spacing.screen)
        }
        .onAppear { showsSheet = true }
        .sheet(isPresented: $showsSheet, onDismiss: finishExit) {
            BoundaryDrawingGuideSheet(step: guide.step, onContinue: advance)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sheetHeight = $0 }
        }
    }

    private func advance() {
        guard pendingExit == nil else { return }
        withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.35)) {
            if !guide.advance() { closeSheet(for: .continueMapping) }
        }
    }

    private func goBack() {
        guard pendingExit == nil else { return }
        withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.35)) {
            if !guide.goBack() { closeSheet(for: .back) }
        }
    }

    // Finish navigation only after the native sheet has dismissed.
    private func closeSheet(for exit: Exit) {
        pendingExit = exit
        showsSheet = false
    }

    private func finishExit() {
        guard let exit = pendingExit else { return }
        pendingExit = nil
        switch exit {
        case .back: onBack()
        case .continueMapping: onContinue()
        }
    }
}

#if DEBUG
#Preview("Panduan menggambar batas") {
    BoundaryDrawingGuideView(
        position: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0.5, longitude: 101.5),
            span: MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.004)
        )),
        fallbackCenter: CLLocationCoordinate2D(latitude: 0.5, longitude: 101.5),
        onBack: {}, onContinue: {}
    )
}
#endif
