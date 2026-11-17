import SwiftUI
import UIKit

/// A native blur behind a transparent navigation bar, with no opaque fill or separator.
struct NavigationBlurBackdrop: View {
    let topInset: CGFloat
    let progress: CGFloat

    static func scrollProgress(for offset: CGFloat) -> CGFloat {
        min(1, max(0, offset / 48))
    }

    var body: some View {
        NativeLightBlur(intensity: 0.22 * progress)
            .frame(height: max(topInset, 60) + 72)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.84),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct NativeLightBlur: UIViewRepresentable {
    let intensity: CGFloat

    func makeUIView(context: Context) -> AdjustableBlurView {
        AdjustableBlurView()
    }

    func updateUIView(_ view: AdjustableBlurView, context: Context) {
        view.intensity = intensity
    }
}

private final class AdjustableBlurView: UIVisualEffectView {
    private var blurAnimator: UIViewPropertyAnimator?

    var intensity: CGFloat = 0 {
        didSet { blurAnimator?.fractionComplete = min(max(intensity, 0), 1) }
    }

    init() {
        super.init(effect: nil)
        let animator = UIViewPropertyAnimator(duration: 1, curve: .linear) { [weak self] in
            self?.effect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        }
        animator.startAnimation()
        animator.pauseAnimation()
        blurAnimator = animator
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        blurAnimator?.stopAnimation(true)
    }
}
