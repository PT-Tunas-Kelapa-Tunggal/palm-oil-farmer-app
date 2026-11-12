import SwiftUI

/// Collapsed bottom pill handle for the Farm Green Index screen using Liquid Glass.
/// Sliced from Sketch: "Hasil Peninjauan / Peta Kondisi Kebun / Collapsed" -> "Sheet / Capsule", "Kondisi Pohon"
public struct FarmGreenIndexCollapsedPillView: View {
    public let subtitle: String
    public var onExpand: (() -> Void)?

    private let darkPrimary = Color(red: 0.08, green: 0.08, blue: 0.09) // #141517

    public init(
        subtitle: String = "108 dari 228 pohon perlu diperhatikan",
        onExpand: (() -> Void)? = nil
    ) {
        self.subtitle = subtitle
        self.onExpand = onExpand
    }

    public var body: some View {
        Button(action: { onExpand?() }) {
            VStack(spacing: 6) {
                // Grabber handle matching Sketch & reference screenshot
                Capsule()
                    .fill(darkPrimary.opacity(0.25))
                    .frame(width: 36, height: 4)

                // Title & Subtitle centered matching Sketch
                VStack(spacing: 3) {
                    Text("Kondisi Pohon")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(darkPrimary)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(darkPrimary.opacity(0.65))
                }
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            FarmGreenIndexCollapsedPillView()
        }
    }
}
