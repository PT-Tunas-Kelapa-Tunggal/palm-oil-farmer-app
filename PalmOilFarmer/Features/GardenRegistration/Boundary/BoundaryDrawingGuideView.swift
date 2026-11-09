import SwiftUI
import MapKit

enum BoundaryDrawingGuideStyle {
    static let sheetHeight: CGFloat = 210
}

struct BoundaryDrawingGuideView: View {
    // A read-only starting position keeps the demonstration out of the mapping camera binding.
    let position: MapCameraPosition
    let fallbackCenter: CLLocationCoordinate2D
    let onBack: () -> Void
    let onContinue: () -> Void

    @State private var guide = BoundaryDrawingGuideState()
    @State private var showsSheet = false
    @State private var pendingExit: Exit?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Exit { case back, continueMapping }

    var body: some View {
        GeometryReader { _ in
            BoundaryDrawingGuideDemo(
                step: guide.step,
                center: position.camera?.centerCoordinate ?? position.region?.center ?? fallbackCenter,
                longitudeDelta: position.region?.span.longitudeDelta ?? 0.006,
                isPlaying: showsSheet && pendingExit == nil
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

struct BoundaryDrawingGuideSheet: View {
    var step: BoundaryDrawingGuideStep = .zoom
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: KropsTheme.Spacing.field) {
            ScrollView {
                VStack(spacing: KropsTheme.Spacing.field) {
                    HStack(spacing: KropsTheme.Spacing.compact) {
                        ForEach(BoundaryDrawingGuideStep.allCases, id: \.self) { page in
                            Circle()
                                .fill(page == step ? RegistrationStyle.onAction : RegistrationStyle.onAction.opacity(0.3))
                                .frame(width: 7, height: 7)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Panduan \(step.rawValue + 1) dari 2")

                    VStack(spacing: KropsTheme.Spacing.compact) {
                        Text(step.title)
                            .font(.title2.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text(step.message)
                            .font(KropsTheme.Typography.body)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .id(step)
                    .transition(.opacity)
                }
            }
            .scrollBounceBehavior(.basedOnSize)

            RegistrationPrimaryButton(title: step.buttonTitle, action: onContinue)
                .accessibilityIdentifier("boundaryGuideContinue")
        }
        .padding(.horizontal, KropsTheme.Spacing.screen)
        .padding(.top, KropsTheme.Spacing.screen)
        .padding(.bottom, KropsTheme.Spacing.field)
        .accessibilityElement(children: .contain)
        .presentationDetents([.height(BoundaryDrawingGuideStyle.sheetHeight)])
        .presentationDragIndicator(.hidden)
        // Only the back control is interactive behind the sheet; the demonstration is locked.
        .presentationBackgroundInteraction(.enabled)
        .presentationCompactAdaptation(.sheet)
        .interactiveDismissDisabled()
        .preferredColorScheme(.dark)
    }
}

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

#Preview("Sheet panduan · Zoom") {
    Color.clear.sheet(isPresented: .constant(true)) {
        BoundaryDrawingGuideSheet(onContinue: {})
    }
}

#Preview("Sheet panduan · Tandai sudut") {
    Color.clear.sheet(isPresented: .constant(true)) {
        BoundaryDrawingGuideSheet(step: .tap, onContinue: {})
    }
}

#Preview("Sheet panduan · Teks besar") {
    Color.clear.sheet(isPresented: .constant(true)) {
        BoundaryDrawingGuideSheet(step: .tap, onContinue: {})
            .environment(\.dynamicTypeSize, .accessibility3)
    }
}
