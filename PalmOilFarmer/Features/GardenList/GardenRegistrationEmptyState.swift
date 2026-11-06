import SwiftUI

struct GardenRegistrationEmptyState: View {
    var body: some View {
        VStack(spacing: 24) {
            Image("GardenHeatmapIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 210)
                .accessibilityHidden(true)
            VStack(spacing: 16) {
                Text("Pahami kebun anda lebih baik")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                Text("Peninjauan memberikan peta kondisi kebun per area sehingga anda tahu bagian mana yang perlu diprioritaskan dan kapan waktu terbaik untuk merawatnya")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
