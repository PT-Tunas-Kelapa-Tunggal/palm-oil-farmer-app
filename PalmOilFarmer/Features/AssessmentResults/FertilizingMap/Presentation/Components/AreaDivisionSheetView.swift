import SwiftUI

public struct AreaDivisionSheetView: View {
    public let selectedMode: AreaDivisionMode
    public let onSelect: (AreaDivisionMode) -> Void
    public let onClose: () -> Void

    public init(
        selectedMode: AreaDivisionMode,
        onSelect: @escaping (AreaDivisionMode) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.selectedMode = selectedMode
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.12), in: Circle())
                }

                Spacer()

                Text("Pembagian Area")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                // Balancing spacer
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.top, 8)

            // Division Options
            HStack(spacing: 16) {
                divisionCard(
                    mode: .perZona,
                    title: "Per Zona",
                    imageName: "FertilizingZoneMap"
                )

                divisionCard(
                    mode: .perPohon,
                    title: "Per Pohon",
                    imageName: "FertilizingTreeMap"
                )
            }
            .padding(.top, 8)

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(
            Color(red: 0x14 / 255, green: 0x15 / 255, blue: 0x17 / 255)
                .ignoresSafeArea()
        )
    }

    private func divisionCard(
        mode: AreaDivisionMode,
        title: String,
        imageName: String
    ) -> some View {
        let isSelected = selectedMode == mode

        return Button {
            onSelect(mode)
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))

                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 110)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(3)
                }
                .frame(height: 116)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isSelected ? Color.white : Color.white.opacity(0.15),
                            lineWidth: isSelected ? 2.5 : 1
                        )
                )

                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.75))
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview("Pembagian Area") {
    AreaDivisionSheetView(
        selectedMode: .perZona,
        onSelect: { _ in },
        onClose: {}
    )
}
#endif


