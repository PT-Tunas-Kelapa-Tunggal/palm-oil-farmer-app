import SwiftUI

struct GardenRegistrationEmptyState: View {
    var body: some View {
        VStack(spacing: 24) {
            Image("GardenHeatmapIllustration")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 370)
                .padding(.horizontal, -16)
                .accessibilityHidden(true)
            VStack(spacing: 16) {
                Text("Ketahui pohon yang\nperlu perhatian")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                Text("Daftarkan kebun Anda, lalu ajukan peninjauan. Hasilnya berupa peta yang menandai pohon sehat dan pohon yang perlu perhatian.")
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
