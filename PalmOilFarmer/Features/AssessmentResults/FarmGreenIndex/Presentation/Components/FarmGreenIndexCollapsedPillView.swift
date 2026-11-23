import SwiftUI

/// Summary shown in the bottom sheet at its smallest height ("Kondisi Pohon" and how many trees need attention).
/// Shown inside `DetentSheet`: the system draws the sheet, its glass and its grabber.
/// Sliced from Sketch: "Hasil Peninjauan / Peta Kondisi Kebun / Collapsed" -> "Sheet / Capsule", "Kondisi Pohon"
public struct FarmGreenIndexCollapsedPillView: View {
    public let subtitle: String
    public var onExpand: (() -> Void)?


    public init(
        subtitle: String = "108 dari 228 pohon perlu diperhatikan",
        onExpand: (() -> Void)? = nil
    ) {
        self.subtitle = subtitle
        self.onExpand = onExpand
    }

    public var body: some View {
        Button(action: { onExpand?() }) {
            // Title & Subtitle centered matching Sketch
            VStack(spacing: 3) {
                Text("Kondisi Pohon")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(KropsTheme.labelPrimary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(KropsTheme.labelSecondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Ketuk untuk melihat legenda kondisi pohon")
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
