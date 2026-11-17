import SwiftUI

struct AssessmentResultsConfirmationView: View {
    let confirmation: AssessmentResultsViewModel.Confirmation
    let gardenName: String
    let downloadWasSimulated: Bool
    let onContinue: () -> Void
    var onViewHistory: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var buttonHeight = 52.0
    @State private var hasAppeared = false

    private var entranceIsVisible: Bool { reduceMotion || hasAppeared }

    private var isReviewCompleted: Bool { confirmation == .reviewCompleted }

    private var message: String {
        if isReviewCompleted {
            return String(localized: "Hasil peninjauan \(gardenName) siap diunduh.")
        }
        if downloadWasSimulated {
            return String(localized: "Simulasi unduhan hasil peninjauan \(gardenName) selesai.")
        }
        return String(localized: "Hasil peninjauan \(gardenName) sudah tersimpan di ponsel Anda.")
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    Image(isReviewCompleted ? .assessmentReviewCompleteIllustration : .assessmentDownloadCompleteIllustration)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 370)
                        .scaleEffect(entranceIsVisible ? 1 : 0.92)
                        .opacity(entranceIsVisible ? 1 : 0)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text(isReviewCompleted ? "Peninjauan Selesai" : "Hasil Siap Dilihat")
                            .font(.title.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text(message).font(.body)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 370)
                    .offset(y: entranceIsVisible ? 0 : 12)
                    .opacity(entranceIsVisible ? 1 : 0)
                }
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                .padding(.horizontal, 16)
            }
        }
        .foregroundStyle(KropsTheme.labelPrimary)
        .background(KropsTheme.surfaceBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 8) {
                Button(action: onContinue) {
                    buttonLabel(isReviewCompleted ? "Lihat & Unduh Hasil Peninjauan" : "Lihat Hasil Peninjauan")
                }
                .buttonStyle(.plain)
                .foregroundStyle(KropsTheme.labelInversePrimary)
                .glassEffect(.regular.tint(KropsTheme.surfaceInverse), in: Capsule())

                Button(action: isReviewCompleted ? onViewHistory ?? onContinue : onContinue) {
                    buttonLabel(isReviewCompleted ? "Riwayat Pengajuan" : "Kembali ke Detail Kebun")
                }
                .buttonStyle(.plain)
                .foregroundStyle(KropsTheme.accentPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 2)
            .background(KropsTheme.surfaceBackground)
            .opacity(entranceIsVisible ? 1 : 0)
        }
        .sensoryFeedback(.success, trigger: hasAppeared) { _, appeared in appeared }
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.8).delay(0.1)) {
                hasAppeared = true
            }
        }
    }

    private func buttonLabel(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.headline)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: buttonHeight)
            .contentShape(Rectangle())
    }
}

#Preview("Peninjauan Selesai") {
    AssessmentResultsConfirmationView(confirmation: .reviewCompleted, gardenName: "Belakang Rumah",
                                      downloadWasSimulated: true, onContinue: {})
        .preferredColorScheme(.dark)
}

#Preview("Hasil Siap Dilihat") {
    AssessmentResultsConfirmationView(confirmation: .downloadCompleted, gardenName: "Belakang Rumah",
                                      downloadWasSimulated: true, onContinue: {})
        .preferredColorScheme(.dark)
}
