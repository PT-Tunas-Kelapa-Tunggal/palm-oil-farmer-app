import SwiftUI

struct SubmissionSuccessView: View {
    let viewModel: SubmissionSuccessViewModel
    var onClose: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .body) private var buttonHeight = 52.0

    private var palette: AssessmentPalette { .init(isDark: colorScheme == .dark) }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    Image(.submissionSuccessIllustration)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 370)
                        .background(Color(white: 15 / 255), in: RoundedRectangle(cornerRadius: 20))
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text("Pengajuan Terkirim")
                            .font(.title.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text(viewModel.message)
                            .font(.body)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 370)
                }
                .frame(maxWidth: .infinity, minHeight: max(0, geometry.size.height - 16))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .foregroundStyle(palette.primary)
        .background(palette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: close) {
                Text("Kembali ke Detail Kebun")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: buttonHeight)
            }
            .buttonStyle(.plain)
            .foregroundStyle(palette.buttonLabel)
            .glassEffect(.regular.tint(palette.buttonTint), in: Capsule())
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .background(palette.background)
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}

#Preview("Pengajuan Terkirim") {
    SubmissionSuccessView(
        viewModel: SubmissionSuccessViewModel(gardenName: "Belakang Rumah", isPreview: false)
    )
    .preferredColorScheme(.dark)
}
