import SwiftUI

public struct FertilizingMapHeaderView: View {
    public let fertilizerName: String
    public let onTapFertilizer: () -> Void
    public let onTapAreaDivision: () -> Void
    public let onBack: () -> Void

    public init(
        fertilizerName: String,
        onTapFertilizer: @escaping () -> Void,
        onTapAreaDivision: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.fertilizerName = fertilizerName
        self.onTapFertilizer = onTapFertilizer
        self.onTapAreaDivision = onTapAreaDivision
        self.onBack = onBack
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Left Back Button
            GardenProfileIconButton(symbol: "chevron.left", label: "Kembali", action: onBack)

            Spacer()

            // Center Fertilizer Button
            Button(action: onTapFertilizer) {
                HStack(spacing: 8) {
                    Text(fertilizerName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .glassEffect(.regular.interactive(), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            // Right Map / Area Division Button
            GardenProfileIconButton(symbol: "map", label: "Pembagian Area", action: onTapAreaDivision)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.85),
                    Color.black.opacity(0.4),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        }
    }
}
