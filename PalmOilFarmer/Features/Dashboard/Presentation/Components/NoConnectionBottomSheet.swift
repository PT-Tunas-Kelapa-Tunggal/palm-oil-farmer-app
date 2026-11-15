import SwiftUI

/// Bottom sheet shown when opening a garden review without an internet connection.
/// Designed after Sketch `Feature / Dashboard / Farm List / No Connection`.
struct NoConnectionBottomSheet: View {
    let onRetry: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var dark: Bool { colorScheme == .dark }
    private var palette: AssessmentPalette { .init(isDark: dark) }

    var body: some View {
        VStack(spacing: 0) {
            // Grabber handle
            Capsule()
                .fill(dark ? Color(white: 0.3) : Color(red: 20 / 255, green: 21 / 255, blue: 23 / 255, opacity: 0.2))
                .frame(width: 36, height: 5)
                .padding(.top, 6)
                .padding(.bottom, 12)

            VStack(spacing: 16) {
                // Icon (64x64 Circle with wifi.slash)
                Circle()
                    .fill(dark ? Color(white: 0.18) : Color(red: 20 / 255, green: 21 / 255, blue: 23 / 255, opacity: 0.08))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(palette.primary.opacity(0.72))
                    }

                // Text
                VStack(spacing: 6) {
                    Text("Tidak ada koneksi internet")
                        .font(.title3.bold())
                        .foregroundStyle(palette.primary)
                        .multilineTextAlignment(.center)

                    Text("Periksa sinyal atau data seluler Anda, lalu coba lagi untuk membuka kebun ini.")
                        .font(.subheadline)
                        .foregroundStyle(palette.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)

                // Button Coba Lagi
                Button(action: onRetry) {
                    Text("Coba Lagi")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundStyle(palette.buttonLabel)
                        .background(palette.buttonTint, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 8)
        .presentationDetents([.height(280)])
        .presentationCornerRadius(38)
        .presentationDragIndicator(.hidden)
        .presentationBackground {
            if dark { palette.card } else { Rectangle().fill(.regularMaterial) }
        }
    }
}

#if DEBUG
#Preview("No Connection Sheet") {
    Text("Dashboard Background")
        .sheet(isPresented: .constant(true)) {
            NoConnectionBottomSheet(onRetry: {})
        }
}
#endif

