import SwiftUI
import MapKit

/// Animated map behind the drawing guide: a noninteractive map with its own
/// camera and a cancellable demonstration for each page.
struct BoundaryDrawingGuideDemo: View {
    let step: BoundaryDrawingGuideStep
    let center: CLLocationCoordinate2D
    let longitudeDelta: Double
    let isPlaying: Bool
    var bottomSheetHeight: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var position: MapCameraPosition = .automatic
    @State private var corners: [CGPoint] = []
    @State private var spread: CGFloat = 0
    @State private var hintOpacity: Double = 1
    @State private var shown = 0
    @State private var active: Int?
    @State private var drawn: [CGFloat] = [0, 0, 0, 0]
    @State private var showsClosingHint = false
    @State private var isFilled = false
    @State private var hand = 0
    @State private var handVisible = false
    @State private var isPressing = false
    @State private var ripple = 0

    private struct Playback: Hashable {
        let step: BoundaryDrawingGuideStep
        let width: CGFloat
        let height: CGFloat
        let obscuredHeight: CGFloat
        let isPlaying: Bool
        let reduceMotion: Bool
    }

    var body: some View {
        GeometryReader { geometry in
            let obscuredHeight = bottomSheetHeight
                + geometry.safeAreaInsets.bottom + KropsTheme.Spacing.section
            let visibleHeight = max(1, geometry.size.height - obscuredHeight)
            let unit = min(geometry.size.width / 402, visibleHeight / 624)
            let layout = BoundaryDrawingGuideLayout(
                center: center, longitudeDelta: longitudeDelta, viewport: geometry.size,
                obscuredBottomHeight: obscuredHeight
            )
            let playback = Playback(
                step: step, width: geometry.size.width, height: geometry.size.height,
                obscuredHeight: obscuredHeight,
                isPlaying: isPlaying && scenePhase == .active, reduceMotion: reduceMotion
            )

            MapReader { proxy in
                Map(position: $position, interactionModes: []) {}
                    .mapStyle(.imagery(elevation: .flat))
                    .mapControls {}
                    .allowsHitTesting(false)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Contoh peta panduan")
                    .onMapCameraChange(frequency: .continuous) { _ in
                        // Project geographic corners instead of copying Sketch's screen coordinates.
                        corners = layout.coordinates.compactMap { proxy.convert($0, to: .local) }
                    }
                    .overlay {
                        if step == .zoom {
                            pinchHint(unit: unit)
                                .position(x: geometry.size.width * 0.51, y: visibleHeight * 0.57)
                                .opacity(hintOpacity)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        } else if corners.count == 4 {
                            tapHint(unit: unit)
                                .opacity(hintOpacity)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                    .task(id: playback) {
                        guard playback.isPlaying else { return }
                        let camera = proxy.camera(framing: layout.mapRect)
                        do {
                            try Task.checkCancellation()
                            reset()
                            position = .camera(camera)
                            if reduceMotion {
                                showStaticExample()
                            } else if step == .zoom {
                                try await demonstrateZoom(camera: camera)
                            } else {
                                try await demonstrateTaps()
                            }
                        } catch {
                            // Cancellation ends the entire sequence, including the current corner.
                        }
                    }
            }
        }
    }

    private func pinchHint(unit: CGFloat) -> some View {
        ZStack {
            let offset = (7.75 + 23.25 * spread) * unit
            touchIndicator(unit: unit).offset(x: -offset, y: -offset)
            touchIndicator(unit: unit).offset(x: offset, y: offset)
            Image(systemName: "hand.pinch.fill")
                .font(.system(size: 56 * unit))
                .foregroundStyle(RegistrationStyle.onAction)
                .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
                .offset(x: 35 * unit, y: -13 * unit)
        }
    }

    private func touchIndicator(unit: CGFloat) -> some View {
        Circle()
            .fill(RegistrationStyle.onAction)
            .frame(width: 28 * unit, height: 28 * unit)
            .background {
                Circle()
                    .stroke(RegistrationStyle.onAction.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 48 * unit, height: 48 * unit)
            }
    }

    private func tapHint(unit: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Path { path in
                path.addLines(corners)
                path.closeSubpath()
            }
            .fill(RegistrationStyle.onAction.opacity(0.12))
            .opacity(isFilled ? 1 : 0)

            ForEach(0..<4, id: \.self) { index in
                segment(from: corners[index], to: corners[(index + 1) % 4])
                    .trim(from: 0, to: drawn[index])
                    .stroke(RegistrationStyle.onAction, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            segment(from: corners[2], to: corners[0])
                .stroke(RegistrationStyle.onAction.opacity(0.7),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [6, 6]))
                .opacity(showsClosingHint ? 1 : 0)

            if let active {
                BoundaryGuideRipple(unit: unit)
                    .id(ripple)
                    .position(corners[active])
            }
            ForEach(0..<4, id: \.self) { index in
                if index < shown {
                    RegistrationBoundaryMarker(number: index + 1, isActive: active == index)
                        .position(corners[index])
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                }
            }
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 56 * unit))
                .foregroundStyle(RegistrationStyle.onAction)
                .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
                .scaleEffect(isPressing ? 0.88 : 1)
                .position(x: corners[hand].x + 22 * unit, y: corners[hand].y + 34 * unit)
                .opacity(handVisible ? 1 : 0)
        }
    }

    private func segment(from start: CGPoint, to end: CGPoint) -> Path {
        Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
    }

    private func reset() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            spread = 0
            hintOpacity = 1
            shown = 0
            active = nil
            drawn = [0, 0, 0, 0]
            showsClosingHint = false
            isFilled = false
            hand = 0
            handVisible = false
            isPressing = false
        }
    }

    private func showStaticExample() {
        spread = 1
        if step == .tap {
            shown = 4
            drawn = [1, 1, 1, 1]
            isFilled = true
        }
    }

    @MainActor
    private func demonstrateZoom(camera: MapCamera) async throws {
        while true {
            try Task.checkCancellation()
            reset()
            var distantCamera = camera
            distantCamera.distance = camera.distance / 0.83
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { position = .camera(distantCamera) }
            try await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeInOut(duration: 1)) {
                spread = 1
                position = .camera(camera)
            }
            try await Task.sleep(for: .milliseconds(1800))
            withAnimation(.easeOut(duration: 0.3)) { hintOpacity = 0 }
            try await Task.sleep(for: .milliseconds(300))
        }
    }

    @MainActor
    private func demonstrateTaps() async throws {
        while true {
            try Task.checkCancellation()
            reset()
            try await Task.sleep(for: .milliseconds(400))
            for index in 0..<4 {
                withAnimation(.easeInOut(duration: 0.45)) {
                    hand = index
                    handVisible = true
                }
                try await Task.sleep(for: .milliseconds(450))
                withAnimation(.easeOut(duration: 0.12)) { isPressing = true }
                try await Task.sleep(for: .milliseconds(120))
                ripple += 1
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isPressing = false
                    shown = index + 1
                    active = index
                }
                if index >= 1 {
                    withAnimation(.easeInOut(duration: 0.35)) { drawn[index - 1] = 1 }
                }
                if index == 2 {
                    withAnimation(.easeIn(duration: 0.3).delay(0.35)) { showsClosingHint = true }
                }
                if index == 3 {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showsClosingHint = false
                        drawn[3] = 1
                    }
                    try await Task.sleep(for: .milliseconds(350))
                    withAnimation(.easeOut(duration: 0.4)) {
                        isFilled = true
                        active = nil
                        handVisible = false
                    }
                }
                try await Task.sleep(for: .milliseconds(600))
            }
            try await Task.sleep(for: .milliseconds(1200))
            withAnimation(.easeOut(duration: 0.3)) { hintOpacity = 0 }
            try await Task.sleep(for: .milliseconds(300))
        }
    }
}

private struct BoundaryGuideRipple: View {
    let unit: CGFloat
    @State private var grown = false

    var body: some View {
        Circle()
            .fill(RegistrationStyle.onAction.opacity(0.18))
            .overlay { Circle().stroke(RegistrationStyle.onAction.opacity(0.6), lineWidth: 1.5) }
            .frame(width: 60 * unit, height: 60 * unit)
            .scaleEffect(grown ? 1 : 0.4)
            .opacity(grown ? 1 : 0.2)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) { grown = true }
            }
    }
}

#if DEBUG
#Preview("Demo panduan · Zoom") {
    BoundaryDrawingGuideDemo(step: .zoom,
                             center: CLLocationCoordinate2D(latitude: 1.104950, longitude: 104.121010),
                             longitudeDelta: 0.004, isPlaying: true, bottomSheetHeight: 230)
        .ignoresSafeArea()
}

#Preview("Demo panduan · Tandai sudut") {
    BoundaryDrawingGuideDemo(step: .tap,
                             center: CLLocationCoordinate2D(latitude: 1.104950, longitude: 104.121010),
                             longitudeDelta: 0.004, isPlaying: true, bottomSheetHeight: 230)
        .ignoresSafeArea()
}
#endif
