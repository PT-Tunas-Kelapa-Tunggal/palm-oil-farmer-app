import SwiftUI

/// Floating navigation header for the Farm Green Index screen using Liquid Glass buttons.
/// Sliced from Sketch: "Hasil Peninjauan / Peta Kondisi Kebun / Legend" -> "Stack 5"
public struct FarmGreenIndexHeaderView: View {
    public let gardenName: String
    public let locationName: String
    public var onBack: (() -> Void)?
    public var onToggleLegend: (() -> Void)?
    public var onOpenAreaPicker: (() -> Void)?

    public init(
        gardenName: String,
        locationName: String,
        onBack: (() -> Void)? = nil,
        onToggleLegend: (() -> Void)? = nil,
        onOpenAreaPicker: (() -> Void)? = nil
    ) {
        self.gardenName = gardenName
        self.locationName = locationName
        self.onBack = onBack
        self.onToggleLegend = onToggleLegend
        self.onOpenAreaPicker = onOpenAreaPicker
    }

    public var body: some View {
        HStack(alignment: .center) {
            // Left back button (Tombol Kiri) with Liquid Glass
            Button(action: { onBack?() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(KropsTheme.labelPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel("Kembali")

            Spacer()

            // Center Garden Info (Judul)
            VStack(spacing: 2) {
                Text(gardenName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)

                Text(locationName)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
            }
            .multilineTextAlignment(.center)

            Spacer()

            // Same width as the back button, so the title stays centred.
            Color.clear
                .frame(width: 44, height: 44)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        FarmGreenIndexHeaderView(
            gardenName: "Belakang Rumah",
            locationName: "Malang Rapat, Bintan, Kep. Riau"
        )
    }
}
