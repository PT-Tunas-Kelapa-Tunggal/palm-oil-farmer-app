import SwiftUI

struct GardenSavedConfirmationView: View {
    let gardenName: String
    let area: String
    let onContinue: () -> Void
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    var body: some View {
        VStack(spacing: KropsTheme.Spacing.section) {
            Image("GardenRegistrationSuccess")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 370)
                .clipShape(RoundedRectangle(cornerRadius: KropsTheme.Radius.metric))
                .accessibilityHidden(true)

            VStack(spacing: KropsTheme.Spacing.compact) {
                Text("Kebun Tersimpan")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("\(gardenName) seluas \(area) sudah masuk ke daftar kebun Anda.")
                    .font(KropsTheme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if voiceOverEnabled {
                PrimaryActionButton(title: "Selesai", action: onContinue)
            }
        }
        .padding(.horizontal, KropsTheme.Spacing.screen)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .interactiveDismissDisabled()
        .task(id: voiceOverEnabled) {
            guard !voiceOverEnabled else { return }
            do {
                try await Task.sleep(for: .seconds(3))
                onContinue()
            } catch { }
        }
    }

}
