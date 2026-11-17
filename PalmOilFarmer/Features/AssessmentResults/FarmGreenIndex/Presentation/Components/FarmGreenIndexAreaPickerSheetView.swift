import SwiftUI

/// Bottom sheet for selecting the area division mode ("Pembagian Area": Per Pohon vs Per Zona) using Liquid Glass.
/// Sliced from Sketch: "Pemupukan / Peta Dosis Pupuk / Pembagian Area" -> "Area Picker"
public struct FarmGreenIndexAreaPickerSheetView: View {
    public let selectedMode: FarmAreaDivisionMode
    public var onSelectMode: ((FarmAreaDivisionMode) -> Void)?
    public var onClose: (() -> Void)?


    public init(
        selectedMode: FarmAreaDivisionMode = .perPohon,
        onSelectMode: ((FarmAreaDivisionMode) -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.selectedMode = selectedMode
        self.onSelectMode = onSelectMode
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header: Spacer (left) + Title (center) + Close Button (right) matching Sketch
            HStack(alignment: .center) {
                // Invisible spacer to ensure true center alignment of Title
                Color.clear
                    .frame(width: 36, height: 36)

                Spacer()

                Text("Pembagian Area")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(KropsTheme.labelPrimary)

                Spacer()

                // Circular Close Button (✕)
                Button(action: { onClose?() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(KropsTheme.labelPrimary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .background(Color.black.opacity(0.06))
                .clipShape(Circle())
                .accessibilityLabel("Tutup")
            }
            .padding(.horizontal, 4)

            // Two Area Division Choices (Per Pohon & Per Zona)
            HStack(spacing: 16) {
                optionCard(mode: .perPohon, imageName: "AreaPickerPerPohon")
                optionCard(mode: .perZona, imageName: "AreaPickerPerZona")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 36)
        .glassEffect(
            .regular,
            in: UnevenRoundedRectangle(
                topLeadingRadius: 32,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 32,
                style: .continuous
            )
        )
    }

    private func optionCard(mode: FarmAreaDivisionMode, imageName: String) -> some View {
        let isSelected = selectedMode == mode

        return Button(action: { onSelectMode?(mode) }) {
            VStack(spacing: 10) {
                // Thumbnail with selection ring
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                isSelected ? KropsTheme.labelInversePrimary : KropsTheme.fillBlack20,
                                lineWidth: isSelected ? 5 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.black.opacity(0.18) : Color.clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )

                // Label
                Text(mode.title)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? KropsTheme.labelPrimary : KropsTheme.labelSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            FarmGreenIndexAreaPickerSheetView(selectedMode: .perZona)
        }
    }
}

