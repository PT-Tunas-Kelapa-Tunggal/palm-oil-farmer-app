import SwiftUI

public struct ChooseFertilizerSheetView: View {
    public let selectedFertilizer: FertilizerPeriodOption?
    public let availableFertilizers: [FertilizerPeriodOption]
    public let periodTitle: String
    public let pendingFertilizerID: String?
    public let errorMessage: String?
    public let onSelect: (FertilizerPeriodOption) -> Void
    public let onClose: () -> Void

    public init(
        selectedFertilizer: FertilizerPeriodOption?,
        availableFertilizers: [FertilizerPeriodOption],
        periodTitle: String = "Pemupukan 1 · Jan–Feb 2027",
        pendingFertilizerID: String? = nil,
        errorMessage: String? = nil,
        onSelect: @escaping (FertilizerPeriodOption) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.selectedFertilizer = selectedFertilizer
        self.availableFertilizers = availableFertilizers
        self.periodTitle = periodTitle
        self.pendingFertilizerID = pendingFertilizerID
        self.errorMessage = errorMessage
        self.onSelect = onSelect
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                Color.clear.frame(width: 44, height: 44)
                Spacer()
                VStack(spacing: 2) {
                    Text("Jenis Pupuk")
                        .font(.system(size: 20, weight: .semibold))
                    Text(pendingFertilizerID == nil ? periodTitle : "Memuat data pupuk…")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 44, height: 44)
                        .background(.quaternary, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(pendingFertilizerID != nil)
            }

            ScrollView {
                LazyVStack(spacing: 4) {
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    ForEach(availableFertilizers) { fertilizer in
                        fertilizerRow(fertilizer)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    private func fertilizerRow(_ fertilizer: FertilizerPeriodOption) -> some View {
        let isSelected = selectedFertilizer?.id == fertilizer.id
        let isPending = pendingFertilizerID == fertilizer.id

        return Button {
            onSelect(fertilizer)
        } label: {
            HStack(spacing: 12) {
                if isPending {
                    ProgressView()
                        .frame(width: 20)
                } else if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.tint)
                        .frame(width: 20)
                } else {
                    Color.clear.frame(width: 20)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(fertilizer.name)
                        .font(.body.weight(.semibold))
                    if !fertilizer.timingSubtitle.isEmpty {
                        Text(fertilizer.timingSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                Text(fertilizer.totalDose)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                if isSelected || isPending {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.black.opacity(0.12))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(pendingFertilizerID != nil)
    }
}

#if DEBUG
#Preview("Jenis Pupuk") {
    let dolomit = FertilizerPeriodOption(id: "dolomit", name: "Dolomit", timingSubtitle: "Awal periode", totalDose: "400 kg")
    let npk = FertilizerPeriodOption(id: "npk", name: "NPK 15-15-15", timingSubtitle: "14 hari setelah Dolomit", totalDose: "120 kg")
    let urea = FertilizerPeriodOption(id: "urea", name: "Urea", timingSubtitle: "1–7 hari setelah NPK 15-15-15", totalDose: "100 kg")

    ChooseFertilizerSheetView(
        selectedFertilizer: dolomit,
        availableFertilizers: [dolomit, npk, urea],
        onSelect: { _ in },
        onClose: {}
    )
}
#endif
