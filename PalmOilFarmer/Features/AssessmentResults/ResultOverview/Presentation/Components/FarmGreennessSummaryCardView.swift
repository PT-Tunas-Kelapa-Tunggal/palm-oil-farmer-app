import SwiftUI

/// Summary card displaying tree deficiency metrics over the drone NDVI vegetation map.
/// Sliced from Sketch: "Hasil Peninjauan / Ringkasan Hasil / Default" -> "Card / Kehijauan Kebun"
public struct FarmGreennessSummaryCardView: View {
    public let title: String
    public let greenness: FarmGreennessSummary
    public var onTap: (() -> Void)?

    public init(
        title: String = "Kehijauan Kebun",
        greenness: FarmGreennessSummary,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.greenness = greenness
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: { onTap?() }) {
            ZStack(alignment: .topLeading) {
                // Background Drone NDVI Map
                Color.clear
                    .overlay {
                        if let uiImage = UIImage(named: "FarmGreennessMap") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            LinearGradient(
                                colors: [Color(red: 0.12, green: 0.22, blue: 0.16), Color(red: 0.08, green: 0.14, blue: 0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }

                // Dark gradient overlay to ensure white text readability
                LinearGradient(
                    colors: [Color.black.opacity(0.65), Color.black.opacity(0.35), Color.black.opacity(0.70)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Foreground Content
                VStack(alignment: .leading, spacing: 0) {
                    // Header Row
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.white)

                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.80))
                    }

                    Spacer(minLength: 24)

                    // Value and Description
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(greenness.affectedTreeCount)")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(Color.white)

                            Text("pohon")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.80))
                        }

                        Text(greenness.statusDescription)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.white.opacity(0.80))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
            }
            .frame(height: 181)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FarmGreennessSummaryCardView(
        greenness: ResultOverviewItem.sample.greenness
    )
    .padding()
    .background(Color(red: 0.95, green: 0.96, blue: 0.97))
}
