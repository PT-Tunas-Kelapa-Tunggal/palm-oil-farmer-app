import SwiftUI

public struct ChooseFertilizerSheetView: View {
    public let selectedFertilizer: FertilizerPeriodOption?
    public let availableFertilizers: [FertilizerPeriodOption]
    public let periodTitle: String
    public let onSelect: (FertilizerPeriodOption) -> Void
    public let onClose: () -> Void

    public init(
        selectedFertilizer: FertilizerPeriodOption?,
        availableFertilizers: [FertilizerPeriodOption],
        periodTitle: String = "Pemupukan 1 · Jan–Feb 2027",
        onSelect: @escaping (FertilizerPeriodOption) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.selectedFertilizer = selectedFertilizer
        self.availableFertilizers = availableFertilizers
        self.periodTitle = periodTitle
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(alignment: .center) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.12), in: Circle())
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("Jenis Pupuk")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)

                    Text(periodTitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.top, 8)

            // Fertilizer Options List
            VStack(spacing: 12) {
                ForEach(availableFertilizers) { fertilizer in
                    fertilizerRow(fertilizer)
                }
            }
            .padding(.top, 4)

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(
            Color(red: 0x14 / 255, green: 0x15 / 255, blue: 0x17 / 255)
                .ignoresSafeArea()
        )
    }

    private func fertilizerRow(_ fertilizer: FertilizerPeriodOption) -> some View {
        let isSelected = selectedFertilizer?.id == fertilizer.id

        return Button {
            onSelect(fertilizer)
        } label: {
            HStack(spacing: 14) {
                // Checkmark icon
                ZStack {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 20, height: 20)

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(fertilizer.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(fertilizer.timingSubtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.65))
                }

                Spacer()

                // Total dose
                Text(fertilizer.totalDose)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Jenis Pupuk") {
    let dolomit = FertilizerPeriodOption(
        id: "dolomit",
        name: "Dolomit",
        timingSubtitle: "Awal periode",
        totalDose: "400 kg"
    )
    let npk = FertilizerPeriodOption(
        id: "npk",
        name: "NPK 15-15-15",
        timingSubtitle: "14 hari setelah Dolomit",
        totalDose: "120 kg"
    )
    let urea = FertilizerPeriodOption(
        id: "urea",
        name: "Urea",
        timingSubtitle: "Pemupukan 1, Januari–Februari 2027",
        totalDose: "100 kg"
    )

    ChooseFertilizerSheetView(
        selectedFertilizer: dolomit,
        availableFertilizers: [dolomit, npk, urea],
        onSelect: { _ in },
        onClose: {}
    )
}
#endif


